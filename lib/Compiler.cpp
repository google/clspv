// Copyright 2018 The Clspv Authors. All rights reserved.
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
// limitations under the License.
#include "clang/Basic/FileManager.h"
#include "clang/Basic/TargetInfo.h"
#include "clang/CodeGen/CodeGenAction.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Frontend/TextDiagnosticPrinter.h"
#include "clang/Lex/PreprocessorOptions.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/InitializePasses.h"
#include "llvm/LinkAllPasses.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/StandardInstrumentations.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorOr.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/StringSaver.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar/DCE.h"
#include "llvm/Transforms/Scalar/InferAddressSpaces.h"
#include "llvm/Transforms/Scalar/SROA.h"
#include "llvm/Transforms/Scalar/StructurizeCFG.h"
#include "llvm/Transforms/Utils/LowerSwitch.h"
#include "llvm/Transforms/Utils/Mem2Reg.h"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"
#include "clspv/Sampler.h"
#include "clspv/clspv64_builtin_library.h"
#include "clspv/clspv_builtin_library.h"
#include "clspv/opencl_builtins_header.h"

#include "Builtins.h"
#include "BuiltinsEnum.h"
#include "Constants.h"
#include "FrontendPlugin.h"
#include "Passes.h"
#include "Types.h"

#include <cassert>
#include <fstream>
#include <iostream>
#include <numeric>
#include <ostream>
#include <sstream>
#include <string>

using namespace clang;

namespace {
enum class SPIRArch : uint32_t {
  SPIR = 0,
  SPIR64,
};

// This registration must be located in the same file as the execution of the
// action.
static FrontendPluginRegistry::Add<clspv::ExtraValidationASTAction>
    X("extra-validation",
      "Perform extra validation on OpenCL C when targeting Vulkan");
static FrontendPluginRegistry::Add<clspv::EntryPointAttrsASTAction>
    Y("attr-information-getting", "get those attrs");

static llvm::cl::opt<bool> cl_single_precision_constants(
    "cl-single-precision-constant", llvm::cl::init(false),
    llvm::cl::desc("Treat double precision floating-point constant as single "
                   "precision constant."));

static llvm::cl::opt<bool> cl_denorms_are_zero(
    "cl-denorms-are-zero", llvm::cl::init(false),
    llvm::cl::desc("If specified, denormalized floating point numbers may be "
                   "flushed to zero."));

static llvm::cl::opt<bool> cl_fp32_correctly_rounded_divide_sqrt(
    "cl-fp32-correctly-rounded-divide-sqrt", llvm::cl::init(false),
    llvm::cl::desc("Single precision floating-point divide (x/y and 1/x) and "
                   "sqrt used are correctly rounded."));

static llvm::cl::opt<bool>
    cl_opt_disable("cl-opt-disable", llvm::cl::init(false),
                   llvm::cl::desc("This option disables all optimizations. The "
                                  "default is optimizations are enabled."));

static llvm::cl::opt<bool> cl_mad_enable(
    "cl-mad-enable", llvm::cl::init(false),
    llvm::cl::desc("Allow a * b + c to be replaced by a mad. The mad computes "
                   "a * b + c with reduced accuracy."));

static llvm::cl::opt<bool> cl_no_signed_zeros(
    "cl-no-signed-zeros", llvm::cl::init(false),
    llvm::cl::desc("Allow optimizations for floating-point arithmetic that "
                   "ignore the signedness of zero."));

static llvm::cl::list<std::string>
    Includes(llvm::cl::Prefix, "I",
             llvm::cl::desc("Add a directory to the list of directories "
                            "to be searched for header files."),
             llvm::cl::ZeroOrMore, llvm::cl::value_desc("include path"));

static llvm::cl::list<std::string>
    Defines(llvm::cl::Prefix, "D",
            llvm::cl::desc("Define a #define directive."), llvm::cl::ZeroOrMore,
            llvm::cl::value_desc("define"));

static llvm::cl::list<std::string>
    InputsFilename(llvm::cl::Positional, llvm::cl::desc("<input files>"),
                   llvm::cl::ZeroOrMore);

static llvm::cl::opt<clang::Language> InputLanguage(
    "x", llvm::cl::desc("Select input type"),
    llvm::cl::init(clang::Language::OpenCL),
    llvm::cl::values(clEnumValN(clang::Language::OpenCL, "cl", "OpenCL source"),
                     clEnumValN(clang::Language::LLVM_IR, "ir", "LLVM IR")));

static llvm::cl::opt<std::string>
    OutputFilename("o", llvm::cl::desc("Override output filename"),
                   llvm::cl::value_desc("filename"));

static llvm::cl::opt<char>
    OptimizationLevel(llvm::cl::Prefix, "O", llvm::cl::init('2'),
                      llvm::cl::desc("Optimization level to use"),
                      llvm::cl::value_desc("level"));

static llvm::cl::opt<bool> verify("verify", llvm::cl::init(false),
                                  llvm::cl::desc("Verify diagnostic outputs"));

static llvm::cl::opt<bool>
    IgnoreWarnings("w", llvm::cl::init(false),
                   llvm::cl::desc("Disable all warnings"));

static llvm::cl::opt<bool>
    WarningsAsErrors("Werror", llvm::cl::init(false),
                     llvm::cl::desc("Turn warnings into errors"));

enum OutputFormat {
  OutputFormatLLVMIR,
  OutputFormatLLVMIRBinary,
  OutputFormatSPIRV,
  OutputFormatC,
};

static llvm::cl::opt<enum OutputFormat> OutputFormat(
    "output-format", llvm::cl::desc("Select output format (ll|bc|spv|c)"),
    llvm::cl::init(OutputFormatSPIRV),
    llvm::cl::values(
        clEnumValN(OutputFormatSPIRV, "spv", "Vulkan SPIR-V"),
        clEnumValN(
            OutputFormatLLVMIR, "ll",
            "Readable LLVM IR (Stop compilation before clspv specific passes)"),
        clEnumValN(
            OutputFormatLLVMIRBinary, "bc",
            "Binary LLVM IR (Stop compilation before clspv specific passes)"),
        clEnumValN(OutputFormatC, "c",
                   "C initializer list (of Vulkan SPIR-V)")));

static llvm::cl::opt<SPIRArch> target_arch(
    "arch", llvm::cl::desc("Specify the target SPIR architecture"),
    llvm::cl::init(SPIRArch::SPIR),
    llvm::cl::values(
        clEnumValN(SPIRArch::SPIR, "spir",
                   "spir-unknown-unknown target (pointers are 32-bit)"),
        clEnumValN(SPIRArch::SPIR64, "spir64",
                   "spir64-unknown-unknown target (pointers are 64-bit)")));

namespace {
struct OpenCLBuiltinMemoryBuffer final : public llvm::MemoryBuffer {
  OpenCLBuiltinMemoryBuffer(const void *data, uint64_t data_length) {
    const char *dataCasted = reinterpret_cast<const char *>(data);
    init(dataCasted, dataCasted + data_length, true);
  }

  virtual llvm::MemoryBuffer::BufferKind getBufferKind() const override {
    return llvm::MemoryBuffer::MemoryBuffer_Malloc;
  }

  virtual ~OpenCLBuiltinMemoryBuffer() override {}
};
} // namespace

clang::TargetInfo *PrepareTargetInfo(CompilerInstance &instance) {
  // Create target info
  auto TargetInfo = clang::TargetInfo::CreateTargetInfo(
      instance.getDiagnostics(),
      std::make_shared<clang::TargetOptions>(instance.getTargetOpts()));

  // The SPIR target enables all possible options, disable the ones we don't
  // want
  auto &Opts = TargetInfo->getSupportedOpenCLOpts();

  // Conditionally disable extensions based on support
  if (!clspv::Option::FP16()) {
    Opts["cl_khr_fp16"] = false;
  }
  if (!clspv::Option::FP64()) {
    Opts["cl_khr_fp64"] = false;
  }
  // Enable/Disable CL3.0 feature macros for unsupported features
  if (instance.getLangOpts().LangStd == clang::LangStandard::lang_opencl30) {

    auto EnabledFeatureMacros = clspv::Option::EnabledFeatureMacros();
    // overwrite feature macro list for certain options
    if (clspv::Option::FP64()) {
      EnabledFeatureMacros.insert(clspv::FeatureMacro::__opencl_c_fp64);
    }
    if (clspv::Option::ImageSupport()) {
      EnabledFeatureMacros.insert(clspv::FeatureMacro::__opencl_c_images);
    }

    // TODO remove when feature macros are added to OpenCLExtensions.def
    // https://github.com/llvm/llvm-project/blob/main/clang/include/clang/Basic/OpenCLExtensions.def#L119
    constexpr std::array<clspv::FeatureMacro, 3> specialDefines{
        clspv::FeatureMacro::__opencl_c_atomic_scope_device,
        clspv::FeatureMacro::__opencl_c_atomic_scope_all_devices,
        clspv::FeatureMacro::__opencl_c_work_group_collective_functions};

    const auto featureList = clspv::FeatureMacroList;
    for (auto [feat, str] : featureList) {
      const bool enabled =
          std::find(EnabledFeatureMacros.cbegin(), EnabledFeatureMacros.cend(),
                    feat) != EnabledFeatureMacros.cend();
      Opts[str] = enabled;

      if (std::count(specialDefines.cbegin(), specialDefines.cend(), feat) &&
          enabled) {
        instance.getPreprocessorOpts().addMacroDef(str);
      }
      if (feat == clspv::FeatureMacro::__opencl_c_int64 && !enabled){
        instance.getPreprocessorOpts().addMacroUndef(str);
      }
    }
  }
  return TargetInfo;
}

// Sets |instance|'s options for compiling. Returns 0 if successful.
int SetCompilerInstanceOptions(
    CompilerInstance &instance, const llvm::StringRef &overiddenInputFilename,
    clang::FrontendInputFile &kernelFile, const std::string &program,
    std::unique_ptr<llvm::MemoryBuffer> &file_memory_buffer,
    llvm::raw_string_ostream *diagnosticsStream) {
  if (program.empty()) {
    return -1;
  }
  file_memory_buffer =
      llvm::MemoryBuffer::getMemBuffer(program, overiddenInputFilename);

  if (verify) {
    instance.getDiagnosticOpts().VerifyDiagnostics = true;
    instance.getDiagnosticOpts().VerifyPrefixes.push_back("expected");
  }

  clang::LangStandard::Kind standard;
  switch (clspv::Option::Language()) {
  case clspv::Option::SourceLanguage::OpenCL_C_10:
    standard = clang::LangStandard::lang_opencl10;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_11:
    standard = clang::LangStandard::lang_opencl11;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_12:
    standard = clang::LangStandard::lang_opencl12;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_20:
    standard = clang::LangStandard::lang_opencl20;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_30:
    standard = clang::LangStandard::lang_opencl30;
    break;
  case clspv::Option::SourceLanguage::OpenCL_CPP:
    standard = clang::LangStandard::lang_openclcpp10;
    break;
  default:
    llvm_unreachable("Unknown source language");
  }

  instance.getLangOpts().C99 = true;
  instance.getLangOpts().RTTI = false;
  instance.getLangOpts().RTTIData = false;
  instance.getLangOpts().MathErrno = false;
  instance.getLangOpts().Optimize = false;
  instance.getLangOpts().NoBuiltin = true;
  instance.getLangOpts().ModulesSearchAll = false;
  instance.getLangOpts().SinglePrecisionConstants = true;
  instance.getLangOpts().DeclareOpenCLBuiltins = true;
  if (clspv::Option::FP16()) {
    instance.getLangOpts().NativeHalfType = true;
    instance.getLangOpts().NativeHalfArgsAndReturns = true;
  }
  instance.getCodeGenOpts().StackRealignment = true;
  instance.getCodeGenOpts().SimplifyLibCalls = false;
  instance.getCodeGenOpts().EmitOpenCLArgMetadata = false;
  instance.getCodeGenOpts().DisableO0ImplyOptNone = true;
  instance.getDiagnosticOpts().IgnoreWarnings = IgnoreWarnings;
  // We always undef __SPIR__ and __SPIRV__ (see below) so don't warn about it.
  instance.getDiagnosticOpts().Warnings.push_back("no-builtin-macro-redefined");
  // TODO(#995): Re-enable this warning.
  instance.getDiagnosticOpts().Warnings.push_back("no-unsafe-buffer-usage");

  instance.getLangOpts().SinglePrecisionConstants =
      cl_single_precision_constants;
  // cl_denorms_are_zero ignored for now!
  // cl_fp32_correctly_rounded_divide_sqrt ignored for now!
  instance.getCodeGenOpts().LessPreciseFPMAD =
      cl_mad_enable || clspv::Option::UnsafeMath();
  // cl_no_signed_zeros ignored for now!
  instance.getLangOpts().UnsafeFPMath = clspv::Option::UnsafeMath();
  instance.getLangOpts().FiniteMathOnly = clspv::Option::FiniteMath();
  instance.getLangOpts().FastRelaxedMath = clspv::Option::FastRelaxedMath();

  // Preprocessor options
  if (!clspv::Option::ImageSupport()) {
    instance.getPreprocessorOpts().addMacroUndef("__IMAGE_SUPPORT__");
  }
  if (clspv::Option::FastRelaxedMath()) {
    instance.getPreprocessorOpts().addMacroDef("__FAST_RELAXED_MATH__");
  }

  for (auto define : Defines) {
    instance.getPreprocessorOpts().addMacroDef(define);
  }

  // Header search options
  for (auto include : Includes) {
    instance.getHeaderSearchOpts().AddPath(include, clang::frontend::After,
                                           false, false);
  }

  // We always compile on opt 0 so we preserve as much debug information about
  // the source as possible. We'll run optimization later, once we've had a
  // chance to view the unoptimal code first
  instance.getCodeGenOpts().OptimizationLevel = 0;

  if (clspv::Option::DebugInfo()) {
    instance.getCodeGenOpts().setDebugInfo(llvm::codegenoptions::FullDebugInfo);
  }

  // Select the correct SPIR triple
  llvm::Triple triple{target_arch == SPIRArch::SPIR64 ? "spir64-unknown-unknown"
                                                      : "spir-unknown-unknown"};

  // We manually include the OpenCL headers below, so this vector is unused.
  std::vector<std::string> includes;

  LangOptions::setLangDefaults(instance.getLangOpts(), clang::Language::OpenCL,
                               triple, includes, standard);

  // Override the C99 inline semantics to accommodate for more OpenCL C
  // programs in the wild.
  instance.getLangOpts().GNUInline = true;

  // Set up diagnostics
  instance.createDiagnostics(
      new clang::TextDiagnosticPrinter(*diagnosticsStream,
                                       &instance.getDiagnosticOpts()),
      true);
  instance.getDiagnostics().setWarningsAsErrors(WarningsAsErrors);
  instance.getDiagnostics().setEnableAllWarnings(true);

  instance.getTargetOpts().Triple = triple.str();

  instance.getCodeGenOpts().MainFileName = overiddenInputFilename.str();
  instance.getCodeGenOpts().PreserveVec3Type = true;
  // Disable generation of lifetime intrinsic.
  instance.getCodeGenOpts().DisableLifetimeMarkers = true;
  if (InputLanguage == clang::Language::OpenCL) {
    instance.getPreprocessorOpts().addRemappedFile(
        overiddenInputFilename, file_memory_buffer.release());
  } else if (!program.empty()) {
    // Can't use preprocessor to do file remapping for LLVM_IR
    kernelFile = clang::FrontendInputFile(*file_memory_buffer,
                                          clang::InputKind(InputLanguage));
  }
  instance.getFrontendOpts().Inputs.push_back(kernelFile);

  std::unique_ptr<llvm::MemoryBuffer> openCLBaseBuiltinMemoryBuffer(
      new OpenCLBuiltinMemoryBuffer(opencl_base_builtins_header_data,
                                    opencl_base_builtins_header_size - 1));

  // TODO this is a hack to get around optional feature macros always being
  // defined in opencl-c-base.h
  instance.getPreprocessorOpts().addMacroUndef("__SPIR__");
  instance.getPreprocessorOpts().addMacroUndef("__SPIRV__");

  instance.getPreprocessorOpts().Includes.push_back("opencl-c-base.h");

  std::unique_ptr<llvm::MemoryBuffer> clspvBuiltinMemoryBuffer(
      new OpenCLBuiltinMemoryBuffer(clspv_builtins_header_data,
                                    clspv_builtins_header_size - 1));

  instance.getPreprocessorOpts().Includes.push_back("clspv-builtins.h");

  // Add the VULKAN macro.
  instance.getPreprocessorOpts().addMacroDef("VULKAN=100");

  // Add the __OPENCL_VERSION__ macro.
  instance.getPreprocessorOpts().addMacroDef("__OPENCL_VERSION__=120");

  instance.setTarget(PrepareTargetInfo(instance));

  instance.createFileManager();
  instance.createSourceManager(instance.getFileManager());

#ifdef _MSC_VER
  std::string includePrefix("include\\");
#else
  std::string includePrefix("include/");
#endif

  auto entry = instance.getFileManager().getVirtualFile(
      includePrefix + "clspv-builtins.h",
      clspvBuiltinMemoryBuffer->getBufferSize(), 0);

  instance.getSourceManager().overrideFileContents(
      entry, std::move(clspvBuiltinMemoryBuffer));

  auto base_entry = instance.getFileManager().getVirtualFile(
      includePrefix + "opencl-c-base.h",
      openCLBaseBuiltinMemoryBuffer->getBufferSize(), 0);

  instance.getSourceManager().overrideFileContents(
      base_entry, std::move(openCLBaseBuiltinMemoryBuffer));

  return 0;
}

int RunPassPipeline(llvm::Module &M, llvm::raw_svector_ostream *binaryStream) {
  llvm::LoopAnalysisManager lam;
  llvm::FunctionAnalysisManager fam;
  llvm::CGSCCAnalysisManager cgam;
  llvm::ModuleAnalysisManager mam;
  llvm::PassInstrumentationCallbacks PIC;
  llvm::StandardInstrumentations si(M.getContext(), false /*DebugLogging*/);
  clspv::RegisterClspvPasses(&PIC);
  si.registerCallbacks(PIC, &mam);
  llvm::PassBuilder pb(nullptr, llvm::PipelineTuningOptions(), std::nullopt,
                       &PIC);
  pb.registerModuleAnalyses(mam);
  pb.registerCGSCCAnalyses(cgam);
  pb.registerFunctionAnalyses(fam);
  pb.registerLoopAnalyses(lam);
  pb.crossRegisterProxies(lam, fam, cgam, mam);

  llvm::ModulePassManager pm;
  llvm::FunctionPassManager fpm;

  switch (OptimizationLevel) {
  case '0':
  case '1':
  case '2':
  case '3':
  case 's':
  case 'z':
    break;
  default:
    llvm::errs() << "Unknown optimization level -O" << OptimizationLevel
                 << " specified!\n";
    return -1;
  }

  llvm::OptimizationLevel level;
  switch (OptimizationLevel) {
  case '0':
    level = llvm::OptimizationLevel::O0;
    break;
  case '1':
    level = llvm::OptimizationLevel::O1;
    break;
  case '2':
    level = llvm::OptimizationLevel::O2;
    break;
  case '3':
    level = llvm::OptimizationLevel::O3;
    break;
  case 's':
    level = llvm::OptimizationLevel::Os;
    break;
  case 'z':
    level = llvm::OptimizationLevel::Oz;
    break;
  default:
    break;
  }

  // Run the following optimizations prior to the standard LLVM pass pipeline.
  pb.registerPipelineStartEPCallback([](llvm::ModulePassManager &pm,
                                        llvm::OptimizationLevel level) {
    pm.addPass(clspv::NativeMathPass());
    pm.addPass(clspv::ZeroInitializeAllocasPass());
    pm.addPass(clspv::KernelArgNamesToMetadataPass());
    pm.addPass(clspv::AnnotationToMetadataPass());
    pm.addPass(clspv::AddFunctionAttributesPass());
    pm.addPass(clspv::AutoPodArgsPass());
    pm.addPass(clspv::DeclarePushConstantsPass());
    pm.addPass(clspv::DefineOpenCLWorkItemBuiltinsPass());

    // RewritePackedStructsPass will rewrite packed struct types, and
    // ReplacePointerBitcastPass will lower the new packed struct type. So,
    // RewritePackedStructsPass must come before ReplacePointerBitcastPass.
    if (clspv::Option::RewritePackedStructs()) {
      pm.addPass(clspv::RewritePackedStructs());
    }

    if (clspv::Option::PrintfSupport()) {
      pm.addPass(clspv::PrintfPass());
    }

    if (level.getSpeedupLevel() > 0) {
      pm.addPass(clspv::OpenCLInlinerPass());
    }

    pm.addPass(clspv::UndoByvalPass());
    pm.addPass(clspv::UndoSRetPass());

    // Handle physical pointer arguments by converting them to POD integers,
    // and update all uses to bitcast them to a pointer first. This allows these
    // arguments to be handled in later passes as if they were regular PODs.
    if (clspv::Option::PhysicalStorageBuffers()) {
      pm.addPass(clspv::PhysicalPointerArgsPass());
    }

    pm.addPass(llvm::createModuleToFunctionPassAdaptor(
        llvm::InferAddressSpacesPass(clspv::AddressSpace::Generic)));

    // We need to run mem2reg and inst combine early because some of our passes
    // (e.g. ThreeElementVectorLowering and InlineFuncWithBitCastArgsPass)
    // cannot handle the pattern:
    //
    //   %1 = alloca i32 1
    //        store <something> %1
    //   %2 = bitcast float* %1
    //   %3 = load float %2
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::PromotePass()));
    pm.addPass(clspv::ClusterPodKernelArgumentsPass());

    pm.addPass(clspv::InlineEntryPointsPass());
    pm.addPass(clspv::FunctionInternalizerPass());
    // This pass needs to be after every inlining to make sure we are capable of
    // removing every addrspacecast. It only needs to run if generic addrspace
    // is used.
    if (clspv::Option::LanguageUsesGenericAddressSpace()) {
      pm.addPass(clspv::ReplaceOpenCLBuiltinPass());
      pm.addPass(clspv::LowerAddrSpaceCastPass());
    }

    // ReplaceOpenCLBuiltinPass can generate vec8 and vec16 elements. It needs
    // to be before the potential LongVectorLoweringPass pass.
    pm.addPass(clspv::ReplaceOpenCLBuiltinPass());
    pm.addPass(clspv::FixupBuiltinsPass());
    pm.addPass(clspv::ThreeElementVectorLoweringPass());

    // Lower longer vectors when requested. Note that this pass depends on
    // ReplaceOpenCLBuiltinPass and expects DeadCodeEliminationPass to be run
    // afterwards.
    if (clspv::Option::LongVectorSupport()) {
      pm.addPass(clspv::LongVectorLoweringPass());
    }

    // Try to deal with pointer bitcasts early. This can prevent problems like
    // issue #409 where LLVM is looser about access chain addressing than
    // SPIR-V. This needs to happen before instcombine and after replacing
    // OpenCL builtins.  This run of the pass will not handle all pointer
    // bitcasts that could be handled. It should be run again after other
    // optimizations (e.g InlineFuncWithPointerBitCastArgPass).
    pm.addPass(clspv::SimplifyPointerBitcastPass());
    pm.addPass(clspv::ReplacePointerBitcastPass());
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::DCEPass()));

    // Hide loads from __constant address space away from instcombine.
    // This prevents us from generating select between pointers-to-__constant.
    // See https://github.com/google/clspv/issues/71
    pm.addPass(clspv::HideConstantLoadsPass());

    pm.addPass(
        llvm::createModuleToFunctionPassAdaptor(llvm::InstCombinePass()));

    pm.addPass(clspv::InlineFuncWithImageMetadataGetterPass());
    pm.addPass(clspv::InlineFuncWithPointerBitCastArgPass());
    pm.addPass(clspv::InlineFuncWithPointerToFunctionArgPass());
    pm.addPass(clspv::InlineFuncWithSingleCallSitePass());

    if (clspv::Option::HackLogicalPtrtoint()) {
      pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::PromotePass()));
      pm.addPass(clspv::LogicalPointerToIntPass());
    }

    // Mem2Reg pass should be run early because O0 level optimization leaves
    // redundant alloca, load and store instructions from function arguments.
    // clspv needs to remove them ahead of transformation.
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::PromotePass()));

    // SROA pass is run because it will fold structs/unions that are
    // problematic on Vulkan SPIR-V away.
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(
        llvm::SROAPass(llvm::SROAOptions::PreserveCFG)));

    // InstructionCombining pass folds bitcast and gep instructions which are
    // not supported by Vulkan SPIR-V.
    pm.addPass(
        llvm::createModuleToFunctionPassAdaptor(llvm::InstCombinePass()));

    pm.addPass(llvm::createModuleToFunctionPassAdaptor(
        llvm::InferAddressSpacesPass(clspv::AddressSpace::Generic)));
  });

  // Run the following passes after the default LLVM pass pipeline.
  pb.registerOptimizerLastEPCallback([binaryStream](llvm::ModulePassManager &pm,
                                                    llvm::OptimizationLevel) {
    // No point attempting to handle freeze currently so strip them from the
    // IR.
    pm.addPass(clspv::StripFreezePass());

    // Unhide loads from __constant address space.  Undoes the action of
    // HideConstantLoadsPass.
    pm.addPass(clspv::UnhideConstantLoadsPass());

    pm.addPass(clspv::UndoInstCombinePass());
    pm.addPass(clspv::FunctionInternalizerPass());

    // Run SimplifyPointerBitcastPass before ReplaceLLVMInstrinsicsPass to help
    // lower memcpy.
    pm.addPass(clspv::SimplifyPointerBitcastPass());
    pm.addPass(clspv::ReplaceLLVMIntrinsicsPass());
    // Replace LLVM intrinsics can leave dead code around.
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::DCEPass()));
    pm.addPass(clspv::UndoBoolPass());
    pm.addPass(clspv::UndoTruncateToOddIntegerPass());
    // StructurizeCFG requires LowerSwitch to run first.
    pm.addPass(
        llvm::createModuleToFunctionPassAdaptor(llvm::LowerSwitchPass()));
    pm.addPass(
        llvm::createModuleToFunctionPassAdaptor(llvm::StructurizeCFGPass()));
    // Must be run after structurize cfg.
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(
        clspv::FixupStructuredCFGPass()));
    // Must be run after structured cfg fixup.
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(
        clspv::ReorderBasicBlocksPass()));
    pm.addPass(clspv::UndoGetElementPtrConstantExprPass());
    pm.addPass(clspv::SplatArgPass());
    pm.addPass(clspv::SimplifyPointerBitcastPass());
    pm.addPass(clspv::ReplacePointerBitcastPass());
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::DCEPass()));
  
    pm.addPass(clspv::UndoTranslateSamplerFoldPass());

    if (clspv::Option::ModuleConstantsInStorageBuffer()) {
      pm.addPass(clspv::ClusterModuleScopeConstantVars());
    }

    pm.addPass(clspv::ShareModuleScopeVariablesPass());
    // Specialize images before assigning descriptors to disambiguate the
    // various types.
    pm.addPass(clspv::SpecializeImageTypesPass());
    // This should be run after LLVM and OpenCL intrinsics are replaced.
    pm.addPass(clspv::AllocateDescriptorsPass());
    pm.addPass(llvm::VerifierPass());
    pm.addPass(clspv::DirectResourceAccessPass());
    // Replacing pointer bitcasts can leave some trivial GEPs
    // that are easy to remove.  Also replace GEPs of GEPS
    // left by replacing indirect buffer accesses.
    pm.addPass(clspv::SimplifyPointerBitcastPass());
    // Run after DRA to clean up parameters and help reduce the need for
    // variable pointers.
    pm.addPass(clspv::RemoveUnusedArguments());
    pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::DCEPass()));

    // SPIR-V 1.4 and higher do not need to splat scalar conditions for vector
    // data.
    if (clspv::Option::SpvVersion() < clspv::Option::SPIRVVersion::SPIRV_1_4) {
      pm.addPass(clspv::SplatSelectConditionPass());
    }
    pm.addPass(clspv::SignedCompareFixupPass());
    // This pass generates insertions that need to be rewritten.
    pm.addPass(clspv::ScalarizePass());
    pm.addPass(clspv::RewriteInsertsPass());
    // UBO Transformations
    if (clspv::Option::ConstantArgsInUniformBuffer() &&
        !clspv::Option::InlineEntryPoints()) {
      // MultiVersionUBOFunctionsPass will examine non-kernel functions with
      // UBO arguments and either multi-version them as necessary or inline
      // them if multi-versioning cannot be accomplished.
      pm.addPass(clspv::MultiVersionUBOFunctionsPass());
      // Cleanup passes.
      // Specialization can blindly generate GEP chains that are easily
      // cleaned up by SimplifyPointerBitcastPass.
      pm.addPass(clspv::SimplifyPointerBitcastPass());
      // RemoveUnusedArgumentsPass removes the actual UBO arguments that were
      // problematic to begin with now that they have no uses.
      pm.addPass(clspv::RemoveUnusedArguments());
      // DCE cleans up callers of the specialized functions.
      pm.addPass(llvm::createModuleToFunctionPassAdaptor(llvm::DCEPass()));
    }

    // This pass needs to run before an interation of
    // SimplifyPointerBitcastPass/ReplacePointerBitcastPass.
    pm.addPass(clspv::LowerPrivatePointerPHIPass());

    // Last minute pointer simplification. With opaque pointers, we can often
    // end up in a situation where LLVM has simplified GEPs by removing zero
    // indices where an equivalent address would be computed. These lead to
    // situations that are awkward for clspv. The following passes canonicalize
    // GEPs into forms easier to codegen in SPIR-V, including those more likely
    // to avoid extra functionality (e.g. VariablePointers).
    pm.addPass(clspv::SimplifyPointerBitcastPass());
    pm.addPass(clspv::ReplacePointerBitcastPass());
    pm.addPass(clspv::SimplifyPointerBitcastPass());

    // This pass mucks with types to point where you shouldn't rely on
    // DataLayout anymore so leave this right before SPIR-V generation.
    pm.addPass(clspv::UBOTypeTransformPass());

    // This pass depends on the inlining of the image metadata getter from
    // InlineFuncWithImageMetadataGetterPass
    pm.addPass(clspv::SetImageChannelMetadataPass());

    // This is needed to remove long vectors created by SROA passes. Especially
    // with vstore_half, which tends to always recreate long vectors after the
    // first iteration of the longvectorlowering pass
    if (clspv::Option::LongVectorSupport()) {
      pm.addPass(clspv::LongVectorLoweringPass());
    }

    pm.addPass(
        clspv::SPIRVProducerPass(binaryStream, OutputFormat == OutputFormatC));
  });

  // Add the default optimizations for the requested optimization level.
  if (level.getSpeedupLevel() > 0) {
    auto mpm = pb.buildPerModuleDefaultPipeline(level);
    mpm.run(M, mam);
  } else {
    auto mpm = pb.buildO0DefaultPipeline(level);
    mpm.run(M, mam);
  }

  return 0;
}

int ParseOptions(const int argc, const char *const argv[]) {
  // We need to change how some of the called passes works by spoofing
  // ParseCommandLineOptions with the specific options.
  bool has_pre = false;
  bool has_load_pre = false;
  const std::string pre = "-enable-pre";
  const std::string load_pre = "-enable-load-pre";
  for (int i = 1; i < argc; ++i) {
    std::string option(argv[i]);
    auto pre_pos = option.find(pre);
    auto load_pos = option.find(load_pre);
    if (pre_pos == 0 || (pre_pos == 1 && option[0] == '-')) {
      has_pre = true;
    } else if (load_pos == 0 || (load_pos == 1 && option[0] == '-')) {
      has_load_pre = true;
    }
  }

  int llvmArgc = 3;
  const char *llvmArgv[6];
  llvmArgv[0] = argv[0];
  llvmArgv[1] = "-simplifycfg-sink-common=false";
  // TODO(#738): find a better solution to this.
  llvmArgv[2] = "-disable-vector-combine";
  if (!has_pre) {
    llvmArgv[llvmArgc++] = "-enable-pre=0";
  }
  if (!has_load_pre) {
    llvmArgv[llvmArgc++] = "-enable-load-pre=0";
  }

  llvm::cl::ResetAllOptionOccurrences();
  llvm::cl::ParseCommandLineOptions(llvmArgc, llvmArgv);
  llvm::cl::ParseCommandLineOptions(argc, argv);

  if (!clspv::Option::OpaquePointers()) {
    llvm::errs() << "transparent pointer is not supported anymore\n";
    return -1;
  }

  if (clspv::Option::LanguageUsesGenericAddressSpace() &&
      !clspv::Option::InlineEntryPoints()) {
    llvm::errs() << "cannot compile languages that use the generic address "
                    "space (e.g. CLC++, CL2.0) without -inline-entry-points\n";
    return -1;
  }

  if (clspv::Option::ScalarBlockLayout()) {
    llvm::errs() << "scalar block layout support unimplemented\n";
    return -1;
  }

  if (clspv::Option::RewritePackedStructs() && !clspv::Option::Int8Support()) {
    llvm::errs()
        << "Int8 has to be supported with rewrite-packed-structs option";
    return -1;
  }

  // Push constant option validation.
  if (clspv::Option::PodArgsInPushConstants()) {
    if (clspv::Option::PodArgsInUniformBuffer()) {
      llvm::errs() << "POD arguments can only be in either uniform buffers or "
                      "push constants\n";
      return -1;
    }

    if (!clspv::Option::ClusterPodKernelArgs()) {
      llvm::errs() << "POD arguments must be clustered to be passed as push "
                      "constants\n";
      return -1;
    }

    // Conservatively error if a module scope push constant could be used.
    if (clspv::Option::GlobalOffsetPushConstant() ||
        clspv::Option::Language() ==
            clspv::Option::SourceLanguage::OpenCL_C_20 ||
        clspv::Option::Language() ==
            clspv::Option::SourceLanguage::OpenCL_CPP) {
      llvm::errs() << "POD arguments as push constants are not compatible with "
                      "module scope push constants\n";
      return -1;
    }
  }

  if (clspv::Option::ArmNonUniformWorkGroupSize() &&
      clspv::Option::UniformWorkgroupSize()) {
    llvm::errs() << "cannot enable Arm non-uniform workgroup extension support "
                    "and assume uniform workgroup sizes\n";
    return -1;
  }

  if (clspv::Option::Vec3ToVec4() ==
      clspv::Option::Vec3ToVec4SupportClass::vec3ToVec4SupportError) {
    llvm::errs() << "error: -vec3-to-vec4 and -no-vec3-to-vec4 are exclusive "
                    "so they cannot be used together!\n";
    return -1;
  }

  const auto enabled_feature_macros = clspv::Option::EnabledFeatureMacros();
  if (!clspv::Option::FP64() &&
      enabled_feature_macros.count(clspv::FeatureMacro::__opencl_c_fp64)) {
    llvm::errs() << "error: Cannot enabled feature macro __opencl_c_fp64 while "
                    "-fp64 is disabled!\n";
    return -1;
  }

  if (clspv::Option::PhysicalStorageBuffers() &&
      target_arch != SPIRArch::SPIR64) {
    llvm::errs() << "error: -physical-storage-buffers can only be used with "
                    "the spir64 target\n";
    return -1;
  }

  if (!clspv::Option::ImageSupport() &&
      enabled_feature_macros.count(clspv::FeatureMacro::__opencl_c_images)) {
    llvm::errs()
        << "error: Cannot enabled feature macro __opencl_c_images while "
           "-images is disabled!\n";
    return -1;
  }

  if (!clspv::Option::FP16() &&
      ExecutionModeRoundingModeRTE(clspv::Option::RoundingModeRTE::fp16)) {
    llvm::errs() << "error: Cannot set RoundingModeRTE for fp16 if fp16 is not "
                    "supported\n";
    return -1;
  }
  if (!clspv::Option::FP64() &&
      ExecutionModeRoundingModeRTE(clspv::Option::RoundingModeRTE::fp64)) {
    llvm::errs() << "error: Cannot set RoundingModeRTE for fp64 if fp64 is not "
                    "supported\n";
    return -1;
  }

  return 0;
}

int WriteOutput(const std::string &output,
                std::vector<uint32_t> *output_buffer) {
  if (!OutputFilename.empty()) {
    std::error_code error;
    llvm::raw_fd_ostream outStream(OutputFilename, error,
                                   llvm::sys::fs::FA_Write);

    if (error) {
      llvm::errs() << "Unable to open output file '" << OutputFilename
                   << "': " << error.message() << '\n';
      return -1;
    }
    outStream << output;
  }
  if (output_buffer) {
    output_buffer->resize((output.size() + sizeof(uint32_t) - 1) /
                          sizeof(uint32_t));
    memcpy(output_buffer->data(), output.data(), output.size());
  }
  return 0;
}

int GenerateIRFile(std::unique_ptr<llvm::Module> &module,
                   std::vector<uint32_t> *output_binary) {
  std::string module_string;
  llvm::raw_string_ostream stream(module_string);
  switch (OutputFormat) {
  case OutputFormatLLVMIRBinary:
    llvm::WriteBitcodeToFile(*module, stream);
    break;
  case OutputFormatLLVMIR:
    stream << *module;
    stream.flush();
    break;
  default:
    llvm_unreachable("unknown LLVM IR Format");
  }

  return WriteOutput(module_string, output_binary);
}

bool GetEquivalentBuiltinsWithoutGenericPointer(llvm::Module *module,
                                                std::string &lib_str) {
  std::string fct_list;
  llvm::raw_string_ostream stream_fct_list(fct_list);
  llvm::raw_string_ostream stream_fct_decl(lib_str);
  bool found = false;
  for (auto &F : module->functions()) {
    auto name = F.getName();
    if (!name.contains("PU3AS4") ||
        !clspv::Builtins::BuiltinWithGenericPointer(name)) {
      continue;
    }

    auto get_fct_decl = [](llvm::Function &F) {
      std::string str;
      llvm::raw_string_ostream stream(str);
      F.print(stream);
      stream.flush();
      return str;
    };
    std::string str = get_fct_decl(F);

    auto add_impl = [&found, &str, &stream_fct_decl, &stream_fct_list,
                     &module](std::string mangling, std::string AS) {
      auto substr = [&str](size_t start, size_t end) {
        return str.substr(start, end - start);
      };
      if (!found) {
        stream_fct_decl << "target datalayout = \""
                        << module->getDataLayoutStr() << "\"";
      }
      std::string mangling_pattern = "PU3AS4";
      auto mangling_start = str.find(mangling_pattern);
      auto mangling_end = mangling_start + mangling_pattern.size();
      std::string AS_pattern = " addrspace(4)";
      auto AS_start = str.find(AS_pattern);
      auto AS_end = AS_start + AS_pattern.size();
      stream_fct_decl << substr(0, mangling_start) << mangling
                      << substr(mangling_end, AS_start) << AS
                      << substr(AS_end, str.find('#', AS_end) - 1) << "\n";

      if (found) {
        stream_fct_list << ", ptr ";
      }
      stream_fct_list << substr(str.find('@'), mangling_start) << mangling
                      << substr(mangling_end, str.find('(', mangling_end));
    };

    add_impl("P", ""); // private
    found = true;
    add_impl("PU3AS1", " addrspace(1)"); // local
    add_impl("PU3AS3", " addrspace(3)"); // global
  }
  if (found) {
    stream_fct_list.flush();
    stream_fct_decl << "@" << clspv::CLSPVBuiltinsUsed()
                    << " = appending global ["
                    << std::count(fct_list.begin(), fct_list.end(), '@')
                    << " x ptr] [ptr " << fct_list
                    << "], section \"llvm.metadata\"";
    stream_fct_decl.flush();
  }
  return found;
}

bool LinkBuiltinLibrary(llvm::Module *module) {
  auto library_data = clspv::PointersAre64Bit(*module)
                          ? clspv64_builtin_library_data
                          : clspv_builtin_library_data;

  auto library_size = clspv::PointersAre64Bit(*module)
                          ? clspv64_builtin_library_size
                          : clspv_builtin_library_size;

  std::unique_ptr<llvm::MemoryBuffer> buffer(
      new OpenCLBuiltinMemoryBuffer(library_data, library_size - 1));

  llvm::SMDiagnostic Err;
  auto library =
      llvm::getLazyIRModule(std::move(buffer), Err, module->getContext());
  if (!library) {
    llvm::errs() << "Failed to parse builtins library:\n";
    llvm::errs() << Err.getMessage();
    return false;
  }

  llvm::Linker L(*module);

  // When clang generates builtins using the generic address space, different
  // builtins are used for pointer-based builtins. Need to do some work to
  // ensure they are kept around.
  // Affects: modf, remquo, lgamma_r, frexp, fract
  std::string additional_library;
  if (GetEquivalentBuiltinsWithoutGenericPointer(module, additional_library)) {
    auto add_buffer = llvm::MemoryBuffer::getMemBuffer(additional_library);
    auto add_library = llvm::parseIR(*add_buffer, Err, module->getContext());
    if (add_library == nullptr) {
      fprintf(stderr, "%s\n", additional_library.c_str());
      Err.print("internal_additional_library:", llvm::errs());
      return false;
    }
    L.linkInModule(std::move(add_library), 0);
  }

  L.linkInModule(std::move(library), 0);

  return true;
}

std::unique_ptr<llvm::Module>
ProgramToModule(llvm::LLVMContext &context,
                const llvm::StringRef &inputFilename,
                const std::string &program, std::string *output_log, int *err) {

  clang::CompilerInstance instance;
  clang::FrontendInputFile kernelFile(inputFilename,
                                      clang::InputKind(InputLanguage));
  std::string log;
  llvm::raw_string_ostream diagnosticsStream(log);
  std::unique_ptr<llvm::MemoryBuffer> file_memory_buffer;
  if (auto error = SetCompilerInstanceOptions(
          instance, inputFilename, kernelFile, program, file_memory_buffer,
          &diagnosticsStream)) {
    *err = error;
    return nullptr;
  }

  // Parse.
  clang::EmitLLVMOnlyAction action(&context);

  // Prepare the action for processing kernelFile
  const bool success = action.BeginSourceFile(instance, kernelFile);
  if (!success) {
    *err = -1;
    return nullptr;
  }

  auto result = action.Execute();
  action.EndSourceFile();

  clang::DiagnosticConsumer *const consumer =
      instance.getDiagnostics().getClient();
  consumer->finish();

  auto num_warnings = consumer->getNumWarnings();
  auto num_errors = consumer->getNumErrors();
  if (output_log != nullptr) {
    output_log->append(log);
  } else if ((num_errors > 0) || (num_warnings > 0)) {
    llvm::errs() << log;
  }
  if (result || num_errors > 0) {
    *err = -1;
    return nullptr;
  }

  *err = 0;

  // Don't run the passes or produce any output in verify mode.
  // Clang doesn't always produce a valid module.
  if (verify) {
    return nullptr;
  }

  return action.takeModule();
}

// Clang generates definitions for the following builtins:
// * sqrt
//
// These interfere with linking cllib builtins so we strip them.
// See https://reviews.llvm.org/D156743
// TODO(#1231): find a better solution for this.
void StripBuiltinDefinitions(llvm::Module *module) {
  for (auto &F : module->functions()) {
    if (F.isDeclaration())
      continue;

    const auto info = clspv::Builtins::Lookup(&F);
    if (info.getType() == clspv::Builtins::kSqrt) {
      F.deleteBody();
    }
  }
}

int CompileModule(const llvm::StringRef &input_filename,
                  std::unique_ptr<llvm::Module> &module,
                  std::vector<uint32_t> *output_buffer,
                  std::string *output_log) {
  // Optimize.
  // Create a memory buffer for temporarily writing the result.
  SmallVector<char, 10000> binary;
  llvm::raw_svector_ostream binaryStream(binary);

  // If LLVM IR output format was requested, emit the file and stop
  // compilation.
  if (OutputFormat == OutputFormatLLVMIR ||
      OutputFormat == OutputFormatLLVMIRBinary) {
    return GenerateIRFile(module, output_buffer);
  }

  if (!LinkBuiltinLibrary(module.get())) {
    return -1;
  }

  // Run the passes to produce SPIR-V.
  if (RunPassPipeline(*module, &binaryStream) != 0) {
    return -1;
  }

  // Wait until now to try writing the file so that we only write it on
  // successful compilation.
  return WriteOutput(binaryStream.str().str(), output_buffer);
}

int CompilePrograms(const std::vector<std::string> &programs,
                    std::vector<uint32_t> *output_buffer,
                    std::string *output_log) {
  std::vector<std::unique_ptr<llvm::Module>> modules;
  modules.reserve(programs.size());

  llvm::LLVMContext context;
  for (auto program : programs) {
    int error;
    modules.push_back(
        ProgramToModule(context, "source", program, output_log, &error));
    if (error != 0)
      return error;

    StripBuiltinDefinitions(modules.back().get());
  }
  assert(modules.size() > 0 && modules.back() != nullptr);

  std::unique_ptr<llvm::Module> module(modules.back().release());
  modules.pop_back();
  llvm::Linker L(*module);
  for (auto &mod : modules) {
    L.linkInModule(std::move(mod), 0);
  }

  return CompileModule("source", module, output_buffer, output_log);
}

int CompileProgram(const llvm::StringRef &input_filename,
                   const std::string &program,
                   std::vector<uint32_t> *output_buffer,
                   std::string *output_log) {
  int error;
  llvm::LLVMContext context;
  std::unique_ptr<llvm::Module> module =
      ProgramToModule(context, input_filename, program, output_log, &error);
  if (module == nullptr) {
    return error;
  }

  StripBuiltinDefinitions(module.get());

  return CompileModule(input_filename, module, output_buffer, output_log);
}

} // namespace

namespace clspv {

int Compile(const int argc, const char *const argv[]) {
  if (auto error = ParseOptions(argc, argv))
    return error;

  if (OutputFilename.empty()) {
    switch (OutputFormat) {
    case OutputFormatLLVMIR:
      OutputFilename = "a.ll";
      break;
    case OutputFormatLLVMIRBinary:
      OutputFilename = "a.bc";
      break;
    case OutputFormatC:
      OutputFilename = "a.spvinc";
      break;
    case OutputFormatSPIRV:
      OutputFilename = "a.spv";
      break;
    default:
      llvm_unreachable("unknown output format");
    }
  }

  std::ios_base::openmode openMode = std::ios::in;
  if (InputLanguage == clang::Language::LLVM_IR) {
    openMode |= std::ios::binary;
  }

  if (InputsFilename.size() == 0 ||
      (InputsFilename.size() == 1 && InputsFilename[0] == "-")) {
    llvm::StringRef inputFilename;
    switch (InputLanguage) {
    case clang::Language::OpenCL:
      inputFilename = "stdin.cl";
      break;
    case clang::Language::LLVM_IR:
      inputFilename = "stdin.ll";
      break;
    default:
      // Default to fix compiler warnings/errors. Option parsing will reject a
      // bad enum value for the option so there is no need for a message.
      return -1;
    }
    std::string program((std::istreambuf_iterator<char>(std::cin)),
                        std::istreambuf_iterator<char>());
    return CompileProgram(inputFilename, program, nullptr, nullptr);
  } else if (InputsFilename.size() == 1) {
    llvm::StringRef inputFilename = InputsFilename[0];
    std::ifstream stream(inputFilename.str(), openMode);
    if (!stream.is_open()) {
      llvm::errs() << "Failed to open '" << inputFilename << "'\n";
      return -1;
    }
    std::string program((std::istreambuf_iterator<char>(stream)),
                        std::istreambuf_iterator<char>());
    return CompileProgram(inputFilename, program, nullptr, nullptr);
  } else {
    std::vector<std::string> programs;
    programs.reserve(InputsFilename.size());
    for (auto InputFilename : InputsFilename) {
      std::ifstream stream(InputFilename, openMode);
      if (!stream.is_open()) {
        llvm::errs() << "Failed to open '" << InputFilename << "'\n";
        return -1;
      }
      programs.emplace_back(std::istreambuf_iterator<char>(stream),
                            std::istreambuf_iterator<char>());
    }

    return CompilePrograms(programs, nullptr, nullptr);
  }
}

int CompileFromSourcesString(const std::vector<std::string> &programs,
                             const std::string &options,
                             std::vector<uint32_t> *output_buffer,
                             std::string *output_log) {
  llvm::SmallVector<const char *, 20> argv;
  llvm::BumpPtrAllocator A;
  llvm::StringSaver Saver(A);
  argv.push_back(Saver.save("clspv").data());
  llvm::cl::TokenizeGNUCommandLine(options, Saver, argv);
  int argc = static_cast<int>(argv.size());

  if (auto error = ParseOptions(argc, &argv[0]))
    return error;

  return CompilePrograms(programs, output_buffer, output_log);
}

int CompileFromSourceString(const std::string &program,
                            const std::string & /*removed*/,
                            const std::string &options,
                            std::vector<uint32_t> *output_binary,
                            std::string *output_log) {

  llvm::SmallVector<const char *, 20> argv;
  llvm::BumpPtrAllocator A;
  llvm::StringSaver Saver(A);
  argv.push_back(Saver.save("clspv").data());
  llvm::cl::TokenizeGNUCommandLine(options, Saver, argv);
  int argc = static_cast<int>(argv.size());

  if (auto error = ParseOptions(argc, &argv[0]))
    return error;

  return CompileProgram("source", program, output_binary, output_log);
}
} // namespace clspv
