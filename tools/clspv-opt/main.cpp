// Copyright 2019 The Clspv Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and

// This driver is a stripped-down version of LLVM opt tailored to run clspv
// passes on LLVM IR.  It only implements enough functionality to execute LLVM
// scalar optimizations and the clspv transformations defined in clspv/Passes.h.

#include "llvm/CodeGen/CommandFlags.inc"
#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/LegacyPassNameParser.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/InitializePasses.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/ToolOutputFile.h"

#include "clspv/Passes.h"

static llvm::cl::list<const PassInfo *, bool, PassNameParser>
    PassList(llvm::cl::desc("Transformations available:"));

static llvm::cl::opt<std::string>
    InputFile(llvm::cl::Positional, llvm::cl::desc("<input LLVM IR file>"),
              llvm::cl::init("-"), llvm::cl::value_desc("filename"));

static llvm::cl::opt<std::string>
    OutputFile("o", llvm::cl::desc("Override output filename"),
               llvm::cl::value_desc("filename"));

static llvm::cl::opt<bool>
    PrintEachXForm("p",
                   llvm::cl::desc("Print module after each transformation"));

int main(int argc, char **argv) {
  llvm::InitLLVM c(argc, argv);

  // Initialize passes.
  PassRegistry &registry = *llvm::PassRegistry::getPassRegistry();
  llvm::initializeCore(registry);
  llvm::initializeScalarOpts(registry);

  // clspv passes
  llvm::initializeClspvPasses(registry);

  llvm::cl::ParseCommandLineOptions(argc, argv,
                                    "clspv IR to IR modular optimizer\n");

  llvm::SMDiagnostic err;
  llvm::LLVMContext context;
  context.setDiscardValueNames(false);
  std::unique_ptr<llvm::Module> module =
      llvm::parseIRFile(InputFile, err, context, true, "");

  if (!module) {
    err.print(argv[0], errs());
    return 1;
  }

  // Run the verifier before doing any transformation.
  if (llvm::verifyModule(*module, &errs())) {
    errs() << argv[0] << ": " << InputFile
           << ": error: input module is broken!\n";
    return 1;
  }

  if (OutputFile.empty())
    OutputFile = "-";

  std::error_code ec;
  std::unique_ptr<llvm::ToolOutputFile> out(
      new llvm::ToolOutputFile(OutputFile, ec, sys::fs::F_None));
  if (ec) {
    errs() << ec.message() << '\n';
    return 1;
  }

  // Add a pass for each pass requested on the command-line.
  llvm::legacy::PassManager passes;
  for (unsigned i = 0; i < PassList.size(); ++i) {
    const llvm::PassInfo *pinfo = PassList[i];
    if (pinfo->getNormalCtor()) {
      llvm::Pass *pass = pinfo->getNormalCtor()();
      passes.add(pass);
    } else {
      errs() << argv[0] << ": cannot create pass: " << pinfo->getPassName()
             << "\n";
    }

    if (PrintEachXForm)
      passes.add(llvm::createPrintModulePass(errs(), "", true));
  }

  // Verify after all transformations have executed.
  passes.add(llvm::createVerifierPass());

  // Add a pass to print the module at the end.
  assert(out);
  passes.add(llvm::createPrintModulePass(out->os(), "", false));

  // Print command-line options (this handles -print-options and
  // -print-all-options).
  llvm::cl::PrintOptionValues();

  // Run all the scheduled passes.
  passes.run(*module);
  out->keep();

  return 0;
}
