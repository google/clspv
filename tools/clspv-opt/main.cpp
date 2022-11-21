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

#include "llvm/Analysis/CGSCCPassManager.h"
#include "llvm/CodeGen/CommandFlags.h"
#include "llvm/IRPrinter/IRPrintingPasses.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/InitializePasses.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/StandardInstrumentations.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Transforms/Scalar/LoopPassManager.h"
#include "llvm/Transforms/Utils/Debugify.h"

// Necessary to initialize options and passes.
#include "clspv/Option.h"
#include "clspv/Passes.h"

using namespace llvm;

static llvm::cl::opt<std::string>
    InputFile(llvm::cl::Positional, llvm::cl::desc("<input LLVM IR file>"),
              llvm::cl::init("-"), llvm::cl::value_desc("filename"));

static llvm::cl::opt<std::string>
    OutputFile("o", llvm::cl::desc("Override output filename"),
               llvm::cl::value_desc("filename"));

static llvm::cl::opt<bool>
    PrintEachXForm("p",
                   llvm::cl::desc("Print module after each transformation"));

static llvm::cl::opt<std::string> Passes("passes", llvm::cl::desc("Passes"));

int main(int argc, char **argv) {
  llvm::InitLLVM c(argc, argv);

  llvm::cl::ParseCommandLineOptions(argc, argv,
                                    "clspv IR to IR modular optimizer\n");

  llvm::SMDiagnostic err;
  llvm::LLVMContext context;
  context.setDiscardValueNames(false);
  std::unique_ptr<llvm::Module> module =
      llvm::parseIRFile(InputFile, err, context);

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
      new llvm::ToolOutputFile(OutputFile, ec, sys::fs::OF_None));
  if (ec) {
    errs() << ec.message() << '\n';
    return 1;
  }

  if (Passes.empty()) {
    errs() << "No passes specified to run!\n";
    return 1;
  }

  llvm::LoopAnalysisManager LAM;
  llvm::FunctionAnalysisManager FAM;
  llvm::CGSCCAnalysisManager CGAM;
  llvm::ModuleAnalysisManager MAM;

  llvm::PassInstrumentationCallbacks PIC;
  clspv::RegisterClspvPasses(&PIC);
  llvm::PassBuilder PB(nullptr, llvm::PipelineTuningOptions(), llvm::None,
                       &PIC);
  clspv::RegisterClspvPassBuilderCallback(&PB);

  PB.registerModuleAnalyses(MAM);
  PB.registerCGSCCAnalyses(CGAM);
  PB.registerFunctionAnalyses(FAM);
  PB.registerLoopAnalyses(LAM);
  PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

  llvm::ModulePassManager MPM;
  MPM.addPass(VerifierPass());
  if (auto Err = PB.parsePassPipeline(MPM, Passes)) {
    errs() << toString(std::move(Err)) << "\n";
    return 1;
  }
  MPM.addPass(VerifierPass());
  MPM.addPass(PrintModulePass(out->os(), "", false));

  // Print command-line options (this handles -print-options and
  // -print-all-options).
  llvm::cl::PrintOptionValues();

  MPM.run(*module, MAM);

  out->keep();

  return 0;
}
