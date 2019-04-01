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

#include "clang/Basic/TargetInfo.h"
#include "clang/CodeGen/CodeGenAction.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Frontend/TextDiagnosticPrinter.h"
#include "clang/Lex/PreprocessorOptions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/LinkAllPasses.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorOr.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/StringSaver.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"

#include "clspv/DescriptorMap.h"
#include "clspv/Option.h"
#include "clspv/Passes.h"
#include "clspv/opencl_builtins_header.h"

#include "FrontendPlugin.h"

#include <cassert>
#include <numeric>
#include <string>
#include <sstream>

using namespace clang;

namespace {
// This registration must be located in the same file as the execution of the
// action.
static FrontendPluginRegistry::Add<clspv::ExtraValidationASTAction>
    X("extra-validation",
      "Perform extra validation on OpenCL C when targeting Vulkan");

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

static llvm::cl::opt<bool> cl_unsafe_math_optimizations(
    "cl-unsafe-math-optimizations", llvm::cl::init(false),
    llvm::cl::desc("Allow optimizations for floating-point arithmetic that (a) "
                   "assume that arguments and results are valid, (b) may "
                   "violate IEEE 754 standard and (c) may violate the OpenCL "
                   "numerical compliance requirements. This option includes "
                   "the -cl-no-signed-zeros and -cl-mad-enable options."));

static llvm::cl::opt<bool> cl_finite_math_only(
    "cl-finite-math-only", llvm::cl::init(false),
    llvm::cl::desc("Allow optimizations for floating-point arithmetic that "
                   "assume that arguments and results are not NaNs or INFs."));

static llvm::cl::opt<bool> cl_fast_relaxed_math(
    "cl-fast-relaxed-math", llvm::cl::init(false),
    llvm::cl::desc("This option causes the preprocessor macro "
                   "__FAST_RELAXED_MATH__ to be defined. Sets the optimization "
                   "options -cl-finite-math-only and "
                   "-cl-unsafe-math-optimizations."));

static llvm::cl::list<std::string>
    Includes(llvm::cl::Prefix, "I",
             llvm::cl::desc("Add a directory to the list of directories "
                            "to be searched for header files."),
             llvm::cl::ZeroOrMore, llvm::cl::value_desc("include path"));

static llvm::cl::list<std::string>
    Defines(llvm::cl::Prefix, "D",
            llvm::cl::desc("Define a #define directive."), llvm::cl::ZeroOrMore,
            llvm::cl::value_desc("define"));

static llvm::cl::opt<std::string>
    InputFilename(llvm::cl::Positional, llvm::cl::desc("<input .cl file>"),
                  llvm::cl::init("-"));

static llvm::cl::opt<std::string>
    OutputFilename("o", llvm::cl::desc("Override output filename"),
                   llvm::cl::value_desc("filename"));

static llvm::cl::opt<std::string>
    DescriptorMapFilename("descriptormap",
                          llvm::cl::desc("Output file for descriptor map"),
                          llvm::cl::value_desc("filename"));

static llvm::cl::opt<char>
    OptimizationLevel(llvm::cl::Prefix, "O", llvm::cl::init('2'),
                      llvm::cl::desc("Optimization level to use"),
                      llvm::cl::value_desc("level"));

static llvm::cl::opt<bool>
    OutputAssembly("S", llvm::cl::init(false),
                   llvm::cl::desc("This option controls output of assembly"));

static llvm::cl::opt<std::string> OutputFormat(
    "mfmt", llvm::cl::init(""),
    llvm::cl::desc(
        "Specify special output format. 'c' is as a C initializer list"),
    llvm::cl::value_desc("format"));

static llvm::cl::opt<std::string>
    SamplerMap("samplermap", llvm::cl::desc("Literal sampler map"),
               llvm::cl::value_desc("filename"));

static llvm::cl::opt<bool> cluster_non_pointer_kernel_args(
    "cluster-pod-kernel-args", llvm::cl::init(false),
    llvm::cl::desc("Collect plain-old-data kernel arguments into a struct in "
                   "a single storage buffer, using a binding number after "
                   "other arguments. Use this to reduce storage buffer "
                   "descriptors."));

static llvm::cl::opt<bool> verify("verify", llvm::cl::init(false),
                                  llvm::cl::desc("Verify diagnostic outputs"));

static llvm::cl::opt<bool>
    IgnoreWarnings("w", llvm::cl::init(false),
                   llvm::cl::desc("Disable all warnings"));

static llvm::cl::opt<bool>
    WarningsAsErrors("Werror", llvm::cl::init(false),
                   llvm::cl::desc("Turn warnings into errors"));

// Populates |SamplerMapEntries| with data from the input sampler map. Returns 0
// if successful.
int ParseSamplerMap(const std::string &sampler_map,
                    llvm::SmallVectorImpl<std::pair<unsigned, std::string>>
                        *SamplerMapEntries) {
  std::unique_ptr<llvm::MemoryBuffer> samplerMapBuffer(nullptr);
  if (!sampler_map.empty()) {
    // Parse the sampler map from the provided string.
    samplerMapBuffer = llvm::MemoryBuffer::getMemBuffer(sampler_map);

    if (!SamplerMap.empty()) {
      llvm::outs() << "Warning: -samplermap is ignored when the sampler map is "
                      "provided through a string.\n";
    }
  } else if (!SamplerMap.empty()) {
    // Parse the sampler map from the option provided file.
    auto errorOrSamplerMapFile =
        llvm::MemoryBuffer::getFile(SamplerMap.getValue());

    // If there was an error in getting the sampler map file.
    if (!errorOrSamplerMapFile) {
      llvm::errs() << "Error: " << errorOrSamplerMapFile.getError().message()
                   << " '" << SamplerMap.getValue() << "'\n";
      return -1;
    }

    samplerMapBuffer = std::move(errorOrSamplerMapFile.get());
    if (0 == samplerMapBuffer->getBufferSize()) {
      llvm::errs() << "Error: Sampler map was an empty file!\n";
      return -1;
    }
  }

  // No sampler map to parse.
  if (!samplerMapBuffer || 0 == samplerMapBuffer->getBufferSize())
    return 0;

  llvm::SmallVector<llvm::StringRef, 3> samplerStrings;

  // We need to keep track of the beginning of the current entry.
  const char *b = samplerMapBuffer->getBufferStart();
  for (const char *i = b, *e = samplerMapBuffer->getBufferEnd();; i++) {
    // If we have a separator between declarations.
    if ((*i == '|') || (*i == ',') || (i == e)) {
      if (i == b) {
        llvm::errs() << "Error: Sampler map contained an empty entry!\n";
        return -1;
      }

      samplerStrings.push_back(llvm::StringRef(b, i - b).trim());

      // And set b the next character after i.
      b = i + 1;
    }

    // If we have a separator between declarations within a single sampler.
    if ((*i == ',') || (i == e)) {
      enum NormalizedCoords {
        CLK_NORMALIZED_COORDS_FALSE = 0x00,
        CLK_NORMALIZED_COORDS_TRUE = 0x01,
        CLK_NORMALIZED_COORDS_NOT_SET
      } NormalizedCoord = CLK_NORMALIZED_COORDS_NOT_SET;

      enum AddressingModes {
        CLK_ADDRESS_NONE = 0x00,
        CLK_ADDRESS_CLAMP_TO_EDGE = 0x02,
        CLK_ADDRESS_CLAMP = 0x04,
        CLK_ADDRESS_MIRRORED_REPEAT = 0x08,
        CLK_ADDRESS_REPEAT = 0x06,
        CLK_ADDRESS_NOT_SET
      } AddressingMode = CLK_ADDRESS_NOT_SET;

      enum FilterModes {
        CLK_FILTER_NEAREST = 0x10,
        CLK_FILTER_LINEAR = 0x20,
        CLK_FILTER_NOT_SET
      } FilterMode = CLK_FILTER_NOT_SET;

      for (auto str : samplerStrings) {
        if ("CLK_NORMALIZED_COORDS_FALSE" == str) {
          if (CLK_NORMALIZED_COORDS_NOT_SET != NormalizedCoord) {
            llvm::errs() << "Error: Sampler map normalized coordinates was "
                            "previously set!\n";
            return -1;
          }
          NormalizedCoord = CLK_NORMALIZED_COORDS_FALSE;
        } else if ("CLK_NORMALIZED_COORDS_TRUE" == str) {
          if (CLK_NORMALIZED_COORDS_NOT_SET != NormalizedCoord) {
            llvm::errs() << "Error: Sampler map normalized coordinates was "
                            "previously set!\n";
            return -1;
          }
          NormalizedCoord = CLK_NORMALIZED_COORDS_TRUE;
        } else if ("CLK_ADDRESS_NONE" == str) {
          if (CLK_ADDRESS_NOT_SET != AddressingMode) {
            llvm::errs()
                << "Error: Sampler map addressing mode was previously set!\n";
            return -1;
          }
          AddressingMode = CLK_ADDRESS_NONE;
        } else if ("CLK_ADDRESS_CLAMP_TO_EDGE" == str) {
          if (CLK_ADDRESS_NOT_SET != AddressingMode) {
            llvm::errs()
                << "Error: Sampler map addressing mode was previously set!\n";
            return -1;
          }
          AddressingMode = CLK_ADDRESS_CLAMP_TO_EDGE;
        } else if ("CLK_ADDRESS_CLAMP" == str) {
          if (CLK_ADDRESS_NOT_SET != AddressingMode) {
            llvm::errs()
                << "Error: Sampler map addressing mode was previously set!\n";
            return -1;
          }
          AddressingMode = CLK_ADDRESS_CLAMP;
        } else if ("CLK_ADDRESS_MIRRORED_REPEAT" == str) {
          if (CLK_ADDRESS_NOT_SET != AddressingMode) {
            llvm::errs()
                << "Error: Sampler map addressing mode was previously set!\n";
            return -1;
          }
          AddressingMode = CLK_ADDRESS_MIRRORED_REPEAT;
        } else if ("CLK_ADDRESS_REPEAT" == str) {
          if (CLK_ADDRESS_NOT_SET != AddressingMode) {
            llvm::errs()
                << "Error: Sampler map addressing mode was previously set!\n";
            return -1;
          }
          AddressingMode = CLK_ADDRESS_REPEAT;
        } else if ("CLK_FILTER_NEAREST" == str) {
          if (CLK_FILTER_NOT_SET != FilterMode) {
            llvm::errs()
                << "Error: Sampler map filtering mode was previously set!\n";
            return -1;
          }
          FilterMode = CLK_FILTER_NEAREST;
        } else if ("CLK_FILTER_LINEAR" == str) {
          if (CLK_FILTER_NOT_SET != FilterMode) {
            llvm::errs()
                << "Error: Sampler map filtering mode was previously set!\n";
            return -1;
          }
          FilterMode = CLK_FILTER_LINEAR;
        } else {
          llvm::errs() << "Error: Unknown sampler string '" << str
                       << "' found!\n";
          return -1;
        }
      }

      if (CLK_NORMALIZED_COORDS_NOT_SET == NormalizedCoord) {
        llvm::errs() << "Error: Sampler map entry did not contain normalized "
                        "coordinates entry!\n";
        return -1;
      }

      if (CLK_ADDRESS_NOT_SET == AddressingMode) {
        llvm::errs() << "Error: Sampler map entry did not contain addressing "
                        "mode entry!\n";
        return -1;
      }

      if (CLK_FILTER_NOT_SET == FilterMode) {
        llvm::errs()
            << "Error: Sampler map entry did not contain filer mode entry!\n";
        return -1;
      }

      // Generate an equivalent expression in string form.  Sort the
      // strings to get a canonical ordering.
      std::sort(samplerStrings.begin(), samplerStrings.end(),
                std::less<StringRef>());
      const auto samplerExpr = std::accumulate(
          samplerStrings.begin(), samplerStrings.end(), std::string(),
          [](std::string left, std::string right) {
            return left + std::string(left.empty() ? "" : "|") + right;
          });

      // SamplerMapEntries->push_back(std::make_pair(
      //    NormalizedCoord | AddressingMode | FilterMode, samplerExpr));
      SamplerMapEntries->emplace_back(
          NormalizedCoord | AddressingMode | FilterMode, samplerExpr);

      // And reset the sampler strings for the next sampler in the map.
      samplerStrings.clear();
    }

    // And lastly, if we are at the end of the file
    if (i == e) {
      break;
    }
  }

  return 0;
}

// Sets |instance|'s options for compiling. Returns 0 if successful.
int SetCompilerInstanceOptions(CompilerInstance &instance,
                               const llvm::StringRef &overiddenInputFilename,
                               const clang::FrontendInputFile &kernelFile,
                               const std::string &program,
                               llvm::raw_string_ostream *diagnosticsStream) {
  std::unique_ptr<llvm::MemoryBuffer> memory_buffer(nullptr);
  llvm::ErrorOr<std::unique_ptr<llvm::MemoryBuffer>> errorOrInputFile(nullptr);
  if (program.empty()) {
    auto errorOrInputFile =
        llvm::MemoryBuffer::getFileOrSTDIN(InputFilename.getValue());

    // If there was an error in getting the input file.
    if (!errorOrInputFile) {
      llvm::errs() << "Error: " << errorOrInputFile.getError().message() << " '"
                   << InputFilename.getValue() << "'\n";
      return -1;
    }
    memory_buffer.reset(errorOrInputFile.get().release());
  } else {
    memory_buffer = llvm::MemoryBuffer::getMemBuffer(program.c_str(),
                                                     overiddenInputFilename);
  }

  if (verify) {
    instance.getDiagnosticOpts().VerifyDiagnostics = true;
    instance.getDiagnosticOpts().VerifyPrefixes.push_back("expected");
  }

  clang::LangStandard::Kind standard = clang::LangStandard::lang_opencl12;

  // We are targeting OpenCL 1.2 only
  instance.getLangOpts().OpenCLVersion = 120;

  instance.getLangOpts().C99 = true;
  instance.getLangOpts().RTTI = false;
  instance.getLangOpts().RTTIData = false;
  instance.getLangOpts().MathErrno = false;
  instance.getLangOpts().Optimize = false;
  instance.getLangOpts().NoBuiltin = true;
  instance.getLangOpts().ModulesSearchAll = false;
  instance.getLangOpts().SinglePrecisionConstants = true;
  instance.getCodeGenOpts().StackRealignment = true;
  instance.getCodeGenOpts().SimplifyLibCalls = false;
  instance.getCodeGenOpts().EmitOpenCLArgMetadata = false;
  instance.getCodeGenOpts().DisableO0ImplyOptNone = true;
  instance.getDiagnosticOpts().IgnoreWarnings = IgnoreWarnings;

  instance.getLangOpts().SinglePrecisionConstants =
      cl_single_precision_constants;
  // cl_denorms_are_zero ignored for now!
  // cl_fp32_correctly_rounded_divide_sqrt ignored for now!
  instance.getCodeGenOpts().LessPreciseFPMAD =
      cl_mad_enable || cl_unsafe_math_optimizations;
  // cl_no_signed_zeros ignored for now!
  instance.getCodeGenOpts().UnsafeFPMath =
      cl_unsafe_math_optimizations || cl_fast_relaxed_math;
  instance.getLangOpts().FiniteMathOnly =
      cl_finite_math_only || cl_fast_relaxed_math;
  instance.getLangOpts().FastRelaxedMath = cl_fast_relaxed_math;

  // Preprocessor options
  instance.getPreprocessorOpts().addMacroDef("__IMAGE_SUPPORT__");
  if (cl_fast_relaxed_math) {
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

// Debug information is disabled temporarily to call instruction.
#if 0
  instance.getCodeGenOpts().setDebugInfo(clang::codegenoptions::FullDebugInfo);
#endif

  // We use the 32-bit pointer-width SPIR triple
  llvm::Triple triple("spir-unknown-unknown");

  instance.getInvocation().setLangDefaults(
      instance.getLangOpts(), clang::InputKind::OpenCL, triple,
      instance.getPreprocessorOpts(), standard);

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

  instance.getCodeGenOpts().MainFileName = overiddenInputFilename;
  instance.getCodeGenOpts().PreserveVec3Type = true;
  // Disable generation of lifetime intrinsic.
  instance.getCodeGenOpts().DisableLifetimeMarkers = true;
  instance.getFrontendOpts().Inputs.push_back(kernelFile);
  // instance.getPreprocessorOpts().addRemappedFile(
  //    overiddenInputFilename, errorOrInputFile.get().release());
  instance.getPreprocessorOpts().addRemappedFile(overiddenInputFilename,
                                                 memory_buffer.release());

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

  std::unique_ptr<llvm::MemoryBuffer> openCLBuiltinMemoryBuffer(
      new OpenCLBuiltinMemoryBuffer(opencl_builtins_header_data,
                                    opencl_builtins_header_size - 1));

  instance.getPreprocessorOpts().Includes.push_back("openclc.h");

  // Add the VULKAN macro.
  instance.getPreprocessorOpts().addMacroDef("VULKAN=100");

  // Add the __OPENCL_VERSION__ macro.
  instance.getPreprocessorOpts().addMacroDef("__OPENCL_VERSION__=120");

  instance.setTarget(clang::TargetInfo::CreateTargetInfo(
      instance.getDiagnostics(),
      std::make_shared<clang::TargetOptions>(instance.getTargetOpts())));

  instance.createFileManager();
  instance.createSourceManager(instance.getFileManager());

#ifdef _MSC_VER
  std::string includePrefix("include\\");
#else
  std::string includePrefix("include/");
#endif

  auto entry = instance.getFileManager().getVirtualFile(
      includePrefix + "openclc.h", openCLBuiltinMemoryBuffer->getBufferSize(),
      0);

  instance.getSourceManager().overrideFileContents(
      entry, std::move(openCLBuiltinMemoryBuffer));

  return 0;
}

// Populates |pm| with necessary passes to optimize and legalize the IR.
int PopulatePassManager(
    llvm::legacy::PassManager *pm, llvm::raw_svector_ostream *binaryStream,
    std::vector<clspv::version0::DescriptorMapEntry> *descriptor_map_entries,
    llvm::SmallVectorImpl<std::pair<unsigned, std::string>>
        *SamplerMapEntries) {
  llvm::PassManagerBuilder pmBuilder;

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

  switch (OptimizationLevel) {
  case '0':
    pmBuilder.OptLevel = 0;
    break;
  case '1':
    pmBuilder.OptLevel = 1;
    break;
  case '2':
    pmBuilder.OptLevel = 2;
    break;
  case '3':
    pmBuilder.OptLevel = 3;
    break;
  case 's':
    pmBuilder.SizeLevel = 1;
    break;
  case 'z':
    pmBuilder.SizeLevel = 2;
    break;
  default:
    break;
  }

  pm->add(clspv::createZeroInitializeAllocasPass());
  pm->add(clspv::createDefineOpenCLWorkItemBuiltinsPass());

  if (0 < pmBuilder.OptLevel) {
    pm->add(clspv::createOpenCLInlinerPass());
  }

  pm->add(clspv::createUndoByvalPass());
  pm->add(clspv::createUndoSRetPass());
  if (cluster_non_pointer_kernel_args) {
    pm->add(clspv::createClusterPodKernelArgumentsPass());
  }
  pm->add(clspv::createReplaceOpenCLBuiltinPass());

  // We need to run mem2reg and inst combine early because our
  // createInlineFuncWithPointerBitCastArgPass pass cannot handle the pattern
  //   %1 = alloca i32 1
  //        store <something> %1
  //   %2 = bitcast float* %1
  //   %3 = load float %2
  pm->add(llvm::createPromoteMemoryToRegisterPass());

  // Hide loads from __constant address space away from instcombine.
  // This prevents us from generating select between pointers-to-__constant.
  // See https://github.com/google/clspv/issues/71
  pm->add(clspv::createHideConstantLoadsPass());

  pm->add(llvm::createInstructionCombiningPass());

  if (clspv::Option::InlineEntryPoints()) {
    pm->add(clspv::createInlineEntryPointsPass());
  } else {
    pm->add(clspv::createInlineFuncWithPointerBitCastArgPass());
    pm->add(clspv::createInlineFuncWithPointerToFunctionArgPass());
    pm->add(clspv::createInlineFuncWithSingleCallSitePass());
  }

  if (0 == pmBuilder.OptLevel) {
    // Mem2Reg pass should be run early because O0 level optimization leaves
    // redundant alloca, load and store instructions from function arguments.
    // clspv needs to remove them ahead of transformation.
    pm->add(llvm::createPromoteMemoryToRegisterPass());

    // SROA pass is run because it will fold structs/unions that are problematic
    // on Vulkan SPIR-V away.
    pm->add(llvm::createSROAPass());

    // InstructionCombining pass folds bitcast and gep instructions which are
    // not supported by Vulkan SPIR-V.
    pm->add(llvm::createInstructionCombiningPass());
  }

  // Now we add any of the LLVM optimizations we wanted
  pmBuilder.populateModulePassManager(*pm);


  // Unhide loads from __constant address space.  Undoes the action of
  // HideConstantLoadsPass.
  pm->add(clspv::createUnhideConstantLoadsPass());

  pm->add(clspv::createFunctionInternalizerPass());
  pm->add(clspv::createReplaceLLVMIntrinsicsPass());
  pm->add(clspv::createUndoBoolPass());
  pm->add(clspv::createUndoTruncatedSwitchConditionPass());
  pm->add(llvm::createStructurizeCFGPass(false));
  // Must be run after structurize cfg.
  pm->add(clspv::createReorderBasicBlocksPass());
  pm->add(clspv::createUndoGetElementPtrConstantExprPass());
  pm->add(clspv::createSplatArgPass());
  pm->add(clspv::createSimplifyPointerBitcastPass());
  pm->add(clspv::createReplacePointerBitcastPass());

  pm->add(clspv::createUndoTranslateSamplerFoldPass());

  if (clspv::Option::ModuleConstantsInStorageBuffer()) {
    pm->add(clspv::createClusterModuleScopeConstantVars());
  }

  pm->add(clspv::createShareModuleScopeVariablesPass());
  // This should be run after LLVM and OpenCL intrinsics are replaced.
  pm->add(clspv::createAllocateDescriptorsPass(*SamplerMapEntries));
  pm->add(llvm::createVerifierPass());
  pm->add(clspv::createDirectResourceAccessPass());
  // Replacing pointer bitcasts can leave some trivial GEPs
  // that are easy to remove.  Also replace GEPs of GEPS
  // left by replacing indirect buffer accesses.
  pm->add(clspv::createSimplifyPointerBitcastPass());
  // Run after DRA to clean up parameters and help reduce the need for variable
  // pointers.
  pm->add(clspv::createRemoveUnusedArgumentsPass());

  pm->add(clspv::createSplatSelectConditionPass());
  pm->add(clspv::createSignedCompareFixupPass());
  // This pass generates insertions that need to be rewritten.
  pm->add(clspv::createScalarizePass());
  pm->add(clspv::createRewriteInsertsPass());
  // This pass mucks with types to point where you shouldn't rely on DataLayout
  // anymore so leave this right before SPIR-V generation.
  pm->add(clspv::createUBOTypeTransformPass());
  pm->add(clspv::createSPIRVProducerPass(
      *binaryStream, descriptor_map_entries, *SamplerMapEntries,
      OutputAssembly.getValue(), OutputFormat == "c"));

  return 0;
}
} // namespace

namespace clspv {
int Compile(const int argc, const char *const argv[]) {
  // We need to change how one of the called passes works by spoofing
  // ParseCommandLineOptions with the specific option.
  const int llvmArgc = 2;
  const char *llvmArgv[llvmArgc] = {
      argv[0],
      "-simplifycfg-sink-common=false",
  };

  llvm::cl::ParseCommandLineOptions(llvmArgc, llvmArgv);

  llvm::cl::ParseCommandLineOptions(argc, argv);

  llvm::SmallVector<std::pair<unsigned, std::string>, 8> SamplerMapEntries;
  if (auto error = ParseSamplerMap("", &SamplerMapEntries))
    return error;

  // if no output file was provided, use a default
  llvm::StringRef overiddenInputFilename = InputFilename.getValue();

  // If we are reading our input file from stdin.
  if ("-" == InputFilename) {
    // We need to overwrite the file name we use.
    overiddenInputFilename = "stdin.cl";
  }

  clang::CompilerInstance instance;
  clang::FrontendInputFile kernelFile(overiddenInputFilename,
                                      clang::InputKind::OpenCL);
  std::string log;
  llvm::raw_string_ostream diagnosticsStream(log);
  if (auto error = SetCompilerInstanceOptions(
          instance, overiddenInputFilename, kernelFile, "", &diagnosticsStream))
    return error;

  // Parse.
  llvm::LLVMContext context;
  clang::EmitLLVMOnlyAction action(&context);

  // Prepare the action for processing kernelFile
  const bool success = action.BeginSourceFile(instance, kernelFile);
  if (!success) {
    return -1;
  }

  action.Execute();
  action.EndSourceFile();

  clang::DiagnosticConsumer *const consumer =
      instance.getDiagnostics().getClient();
  consumer->finish();

  auto num_warnings = consumer->getNumWarnings();
  auto num_errors = consumer->getNumErrors();
  if ((num_errors > 0) || (num_warnings > 0)) {
    llvm::errs() << log;
  }
  if (num_errors > 0) {
    return -1;
  }

  if (clspv::Option::ConstantArgsInUniformBuffer() &&
      !clspv::Option::InlineEntryPoints()) {
    llvm::errs() << "clspv restriction: -constant-args-ubo requires "
                    "-inline-entry-points\n";
    return -1;
  }

  // Don't run the passes or produce any output in verify mode.
  // Clang doesn't always produce a valid module.
  if (verify) {
    return 0;
  }

  llvm::PassRegistry &Registry = *llvm::PassRegistry::getPassRegistry();
  llvm::initializeCore(Registry);
  llvm::initializeScalarOpts(Registry);

  std::unique_ptr<llvm::Module> module(action.takeModule());

  // Optimize.
  // Create a memory buffer for temporarily writing the result.
  SmallVector<char, 10000> binary;
  llvm::raw_svector_ostream binaryStream(binary);
  std::string descriptor_map;
  llvm::legacy::PassManager pm;
  std::vector<version0::DescriptorMapEntry> descriptor_map_entries;
  if (auto error =
          PopulatePassManager(&pm, &binaryStream,
                              &descriptor_map_entries, &SamplerMapEntries))
    return error;
  pm.run(*module);

  // Write outputs

  // Write the descriptor map, if requested.
  std::error_code error;
  if (!DescriptorMapFilename.empty()) {
    llvm::raw_fd_ostream descriptor_map_out_fd(DescriptorMapFilename, error,
                                               llvm::sys::fs::CD_CreateAlways,
                                               llvm::sys::fs::FA_Write,
                                               llvm::sys::fs::F_Text);
    if (error) {
      llvm::errs() << "Unable to open descriptor map file '"
                   << DescriptorMapFilename << "': " << error.message() << '\n';
      return -1;
    }
    std::string descriptor_map_string;
    std::ostringstream str(descriptor_map_string);
    for (const auto &entry : descriptor_map_entries) {
      str << entry << "\n";
    }
    descriptor_map_out_fd << str.str();
    descriptor_map_out_fd.close();
  }

  // Write the resulting binary.
  // Wait until now to try writing the file so that we only write it on
  // successful compilation.
  if (OutputFilename.empty()) {
    // if we've to output assembly
    if (OutputAssembly) {
      OutputFilename = "a.spvasm";
    } else if (OutputFormat == "c") {
      OutputFilename = "a.spvinc";
    } else {
      OutputFilename = "a.spv";
    }
  }
  llvm::raw_fd_ostream outStream(OutputFilename, error, llvm::sys::fs::FA_Write);

  if (error) {
    llvm::errs() << "Unable to open output file '" << OutputFilename
                 << "': " << error.message() << '\n';
    return -1;
  }
  outStream << binaryStream.str();

  return 0;
}

int CompileFromSourceString(const std::string &program,
                            const std::string &sampler_map,
                            const std::string &options,
                            std::vector<uint32_t> *output_binary,
                            std::vector<clspv::version0::DescriptorMapEntry> *descriptor_map_entries) {
  // We need to change how one of the called passes works by spoofing
  // ParseCommandLineOptions with the specific option.
  const int llvmArgc = 2;
  const char *llvmArgv[llvmArgc] = {
      "clspv",
      "-simplifycfg-sink-common=false",
  };

  llvm::cl::ResetAllOptionOccurrences();
  llvm::cl::ParseCommandLineOptions(llvmArgc, llvmArgv);

  llvm::SmallVector<const char *, 20> argv;
  llvm::BumpPtrAllocator A;
  llvm::StringSaver Saver(A);
  argv.push_back(Saver.save("clspv").data());
  llvm::cl::TokenizeGNUCommandLine(options, Saver, argv);
  int argc = static_cast<int>(argv.size());
  llvm::cl::ParseCommandLineOptions(argc, &argv[0]);

  llvm::SmallVector<std::pair<unsigned, std::string>, 8> SamplerMapEntries;
  if (auto error = ParseSamplerMap(sampler_map, &SamplerMapEntries))
    return error;

  InputFilename = "source.cl";
  llvm::StringRef overiddenInputFilename = InputFilename.getValue();

  clang::CompilerInstance instance;
  clang::FrontendInputFile kernelFile(overiddenInputFilename,
                                      clang::InputKind::OpenCL);
  std::string log;
  llvm::raw_string_ostream diagnosticsStream(log);
  if (auto error =
          SetCompilerInstanceOptions(instance, overiddenInputFilename,
                                     kernelFile, program, &diagnosticsStream))
    return error;

  // Parse.
  llvm::LLVMContext context;
  clang::EmitLLVMOnlyAction action(&context);

  // Prepare the action for processing kernelFile
  const bool success = action.BeginSourceFile(instance, kernelFile);
  if (!success) {
    return -1;
  }

  action.Execute();
  action.EndSourceFile();

  clang::DiagnosticConsumer *const consumer =
      instance.getDiagnostics().getClient();
  consumer->finish();

  auto num_errors = consumer->getNumErrors();
  if (num_errors > 0) {
    llvm::errs() << log << "\n";
    return -1;
  }

  if (clspv::Option::ConstantArgsInUniformBuffer() &&
      !clspv::Option::InlineEntryPoints()) {
    llvm::errs() << "clspv restriction: -constant-arg-ubo requires "
                    "-inline-entry-points\n";
    return -1;
  }

  llvm::PassRegistry &Registry = *llvm::PassRegistry::getPassRegistry();
  llvm::initializeCore(Registry);
  llvm::initializeScalarOpts(Registry);

  std::unique_ptr<llvm::Module> module(action.takeModule());

  // Optimize.
  // Create a memory buffer for temporarily writing the result.
  SmallVector<char, 10000> binary;
  llvm::raw_svector_ostream binaryStream(binary);
  std::string descriptor_map;
  llvm::legacy::PassManager pm;
  if (auto error =
          PopulatePassManager(&pm, &binaryStream,
                              descriptor_map_entries, &SamplerMapEntries))
    return error;
  pm.run(*module);

  // Write outputs

  // Write the descriptor map. This is required.
  assert(descriptor_map_entries && "Valid descriptor map container is required.");
  if (!DescriptorMapFilename.empty()) {
    llvm::errs() << "Warning: -descriptormap is ignored descriptor map container is provided.\n";
  }

  // Write the resulting binary.
  // Wait until now to try writing the file so that we only write it on
  // successful compilation.
  assert(output_binary && "Valid binary container is required.");
  if (!OutputFilename.empty()) {
    llvm::outs()
        << "Warning: -o is ignored when binary container is provided.\n";
  }
  output_binary->resize(binary.size() / 4);
  memcpy(output_binary->data(), binary.data(), binary.size());

  return 0;
}
} // namespace clspv
