// Copyright 2017 The Clspv Authors. All rights reserved.
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

#include <clang/AST/RecordLayout.h>
#include <clang/AST/RecursiveASTVisitor.h>
#include <clang/Basic/TargetInfo.h>
#include <clang/CodeGen/CodeGenAction.h>
#include <clang/Frontend/CompilerInstance.h>
#include <clang/Frontend/FrontendPluginRegistry.h>
#include <clang/Frontend/TextDiagnosticPrinter.h>
#include <clang/Lex/PreprocessorOptions.h>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/LegacyPassManager.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/Verifier.h>
#include <llvm/LinkAllPasses.h>
#include <llvm/Support/CommandLine.h>
#include <llvm/Support/MathExtras.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/Transforms/IPO/PassManagerBuilder.h>

#include "clspv/Option.h"
#include "clspv/Passes.h"
#include "clspv/opencl_builtins_header.h"

#include <numeric>
#include <string>

using namespace clang;

namespace {
struct ExtraValidationConsumer final : public ASTConsumer {
private:
  CompilerInstance &Instance;
  llvm::StringRef InFile;

  enum CustomDiagnosticType {
    CustomDiagnosticVectorsMoreThan4Elements = 0,
    CustomDiagnosticVoidPointer = 1,
    CustomDiagnosticUBOUnalignedScalar = 2,
    CustomDiagnosticUBOUnalignedVec2 = 3,
    CustomDiagnosticUBOUnalignedVec4 = 4,
    CustomDiagnosticUBOUnalignedArray = 5,
    CustomDiagnosticUBOUnalignedStruct = 6,
    CustomDiagnosticUBOSmallStraddle = 7,
    CustomDiagnosticUBOLargeStraddle = 8,
    CustomDiagnosticUBOUnalignedStructMember = 9,
    CustomDiagnosticUBORestrictedSize = 10,
    CustomDiagnosticUBORestrictedStruct = 11,
    CustomDiagnosticTotal
  };
  std::vector<unsigned> CustomDiagnosticsIDMap;

  bool IsSupportedType(QualType QT, SourceRange SR) {
    auto *Ty = QT.getTypePtr();

    // First check if we have a pointer type.
    if (Ty->isPointerType()) {
      const Type *pointeeTy = Ty->getPointeeType().getTypePtr();
      if (pointeeTy && pointeeTy->isVoidType()) {
        // We don't support void pointers.
        Instance.getDiagnostics().Report(
            SR.getBegin(), CustomDiagnosticsIDMap[CustomDiagnosticVoidPointer]);
        return false;
      }
      // Otherwise check recursively.
      return IsSupportedType(Ty->getPointeeType(), SR);
    }

    const auto &canonicalType = QT.getCanonicalType();
    if (auto *VT = llvm::dyn_cast<ExtVectorType>(canonicalType)) {
      // We don't support vectors with more than 4 elements.
      if (4 < VT->getNumElements()) {
        Instance.getDiagnostics().Report(
            SR.getBegin(),
            CustomDiagnosticsIDMap[CustomDiagnosticVectorsMoreThan4Elements]);
        return false;
      }
    }

    return true;
  }

  // Returns the alignment of |QT| to satisfy standard Uniform buffer layout
  // rules.
  uint64_t GetAlignment(const QualType QT, const ASTContext &context) const {
    const auto canonical = QT.getCanonicalType();
    uint64_t alignment = context.getTypeAlignInChars(canonical).getQuantity();
    if (canonical->isRecordType() || canonical->isArrayType()) {
      return llvm::alignTo(alignment, 16);
    }
    return alignment;
  }

  // Returns true if |QT| is a valid layout for a Uniform buffer. Refer to
  // 14.5.4 in the Vulkan specification.
  bool IsSupportedUniformLayout(QualType QT, uint64_t offset,
                                ASTContext &context, SourceRange SR) {
    const auto canonical = QT.getCanonicalType();
    if (canonical->isScalarType()) {
      if (!IsSupportedUniformScalarLayout(canonical, offset, context, SR))
        return false;
    } else if (canonical->isExtVectorType()) {
      if (!IsSupportedUniformVectorLayout(canonical, offset, context, SR))
        return false;
    } else if (canonical->isArrayType()) {
      if (!IsSupportedUniformArrayLayout(canonical, offset, context, SR))
        return false;
    } else if (canonical->isRecordType()) {
      if (!IsSupportedUniformRecordLayout(canonical, offset, context, SR))
        return false;
    }

    // TODO(alan-baker): Find a way to avoid this restriction.
    // Don't allow padding. This prevents structs like:
    // struct {
    //   int x[2];
    //   int y __attribute((aligned(16)));
    // };
    //
    // This would map in LLVM to { [2 x i32], [8 x i8], i32, [12 xi8] }.
    // There is no easy way to manipulate the padding after the array to
    // satisfy the standard Uniform buffer layout rules in this case. The usual
    // trick is replacing the i8 arrays with an i32 element, but the i32 would
    // still be laid out too close to the array.
    const auto type_size = context.getTypeSizeInChars(canonical).getQuantity();
    const auto type_align = GetAlignment(canonical, context);
    if (type_size % type_align != 0) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBORestrictedSize]);
      return false;
    }

    return true;
  }

  bool IsSupportedUniformScalarLayout(QualType QT, uint64_t offset,
                                      ASTContext &context, SourceRange SR) {
    // A scalar type of size N has a base alignment on N.
    const unsigned type_size = context.getTypeSizeInChars(QT).getQuantity();
    if (offset % type_size != 0) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedScalar]);
      return false;
    }

    return true;
  }

  bool IsSupportedUniformVectorLayout(QualType QT, uint64_t offset,
                                      ASTContext &context, SourceRange SR) {
    // 2-component vectors have a base alignment of 2 * (size of element).
    // 3- and 4-component vectors hae a base alignment of 4 * (size of
    // element).
    const auto *VT = llvm::cast<VectorType>(QT);
    const auto ele_size =
        context.getTypeSizeInChars(VT->getElementType()).getQuantity();
    if (VT->getNumElements() == 2) {
      if (offset % (ele_size * 2) != 0) {
        Instance.getDiagnostics().Report(
            SR.getBegin(),
            CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedVec2]);
        return false;
      }
    } else if (offset % (ele_size * 4) != 0) {
      // Other vector sizes cause errors elsewhere.
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedVec4]);
      return false;
    }

    // Straddling rules:
    // * If total vector size is less than 16 bytes, the offset must place the
    // entire vector within the same 16 bytes.
    // * If total vector size is greater than 16 bytes, the offset must be a
    // multiple of 16.
    const auto size = context.getTypeSizeInChars(QT).getQuantity();
    if (size <= 16 && (offset / 16 != (offset + size - 1) / 16)) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOSmallStraddle]);
      return false;
    } else if (size > 16 && (offset % 16 != 0)) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOLargeStraddle]);
      return false;
    }

    return IsSupportedUniformLayout(VT->getElementType(), offset, context, SR);
  }

  bool IsSupportedUniformArrayLayout(QualType QT, uint64_t offset,
                                     ASTContext &context, SourceRange SR) {
    // An array has a base alignment of is element type, rounded up to a
    // multiple of 16.
    const auto *AT = llvm::cast<ArrayType>(QT);
    const auto type_align =
        llvm::alignTo(GetAlignment(AT->getElementType(), context), 16);
    if (offset % type_align != 0) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedArray]);
      return false;
    }

    return IsSupportedUniformLayout(AT->getElementType(), offset, context, SR);
  }

  bool IsSupportedUniformRecordLayout(QualType QT, uint64_t offset,
                                      ASTContext &context, SourceRange SR) {
    // A structure has a base alignment of its largest member, rounded up to a
    // multiple of 16.
    const auto *RT = llvm::cast<RecordType>(QT);
    const auto type_alignment = GetAlignment(QT, context);
    if (offset % type_alignment != 0) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedStruct]);
      return false;
    }

    const auto &layout = context.getASTRecordLayout(RT->getDecl());
    const FieldDecl *prev = nullptr;
    for (auto field_decl : RT->getDecl()->fields()) {
      const auto field_type = field_decl->getType();
      const auto field_alignment = GetAlignment(field_type, context);
      const unsigned field_no = field_decl->getFieldIndex();
      const uint64_t field_offset =
          layout.getFieldOffset(field_no) / context.getCharWidth();

      // Rules must be checked recursively.
      if (!IsSupportedUniformLayout(field_type, field_offset, context, SR)) {
        return false;
      }

      if (prev) {
        const auto prev_canonical = prev->getType().getCanonicalType();
        const uint64_t prev_offset =
            layout.getFieldOffset(field_no - 1) / context.getCharWidth();
        const auto prev_size = context.getTypeSizeInChars(prev_canonical).getQuantity();
        const auto prev_alignment = GetAlignment(prev_canonical, context);
        const auto next_available = prev_offset + llvm::alignTo(prev_size, prev_alignment);
        if (prev_canonical->isArrayType() || prev_canonical->isRecordType()) {
          // The next element after an array or struct must be placed on or
          // after the next multiple of the alignment of that array or
          // struct.
          // Both arrays and structs must be aligned to a multiple of 16 bytes.
          if (llvm::alignTo(next_available, 16) > field_offset) {
            Instance.getDiagnostics().Report(
                SR.getBegin(), CustomDiagnosticsIDMap
                                   [CustomDiagnosticUBOUnalignedStructMember]);
            return false;
          }
        }
      }

      prev = field_decl;
    }

    return true;
  }

  // This will be used to check the inside of function bodies.
  class DeclVisitor : public RecursiveASTVisitor<DeclVisitor> {
  private:
    ExtraValidationConsumer &consumer;

  public:
    explicit DeclVisitor(ExtraValidationConsumer &VC) : consumer(VC) {}

    // Visits a declaration.  Emits a diagnostic and returns false if the
    // declaration represents an unsupported vector value or vector type.
    // Otherwise returns true.
    bool VisitDecl(Decl *D) {
      // Looking at the Decl class hierarchy, it seems ValueDecl and TypeDecl
      // are the only two that might represent an unsupported vector type.
      if (auto *VD = dyn_cast<ValueDecl>(D)) {
        return consumer.IsSupportedType(VD->getType(), D->getSourceRange());
      } else if (auto *TD = dyn_cast<TypeDecl>(D)) {
        QualType DefinedType = TD->getASTContext().getTypeDeclType(TD);
        return consumer.IsSupportedType(DefinedType, TD->getSourceRange());
      }
      return true;
    }
  };

  DeclVisitor Visitor;

public:
  explicit ExtraValidationConsumer(CompilerInstance &Instance,
                                   llvm::StringRef InFile)
      : Instance(Instance), InFile(InFile),
        CustomDiagnosticsIDMap(CustomDiagnosticTotal), Visitor(*this) {
    auto &DE = Instance.getDiagnostics();

    CustomDiagnosticsIDMap[CustomDiagnosticVectorsMoreThan4Elements] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "vectors with more than 4 elements are not supported");
    CustomDiagnosticsIDMap[CustomDiagnosticVoidPointer] = DE.getCustomDiagID(
        DiagnosticsEngine::Error, "pointer-to-void is not supported");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedScalar] = DE.getCustomDiagID(
        DiagnosticsEngine::Error, "in an UBO, scalar elements must be aligned to their size");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedVec2] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, two-component vectors must be aligned "
                           "to 2 times their element size");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedVec4] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, three- and four-component vectors must "
                           "be aligned to 4 times their element size");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedArray] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, arrays must be aligned to their element "
                           "alignment, rounded up to a multiple of 16 bytes");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedStruct] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, structs must be aligned to their "
                           "largest element alignment, rounded up to a multiple of "
                           "16 bytes");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOSmallStraddle] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, vectors with a total size less than or "
                           "equal to 16 bytes must be placed entirely within a "
                           "16 byte aligned region");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOLargeStraddle] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, vectors with a total size greater than "
                           "16 bytes must aligned to 16 bytes");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedStructMember] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in an UBO, a structure member must not be placed "
                           "between the end of a structure or array and the "
                           "next multiple of the base alignment of that "
                           "structure or array");
    CustomDiagnosticsIDMap[CustomDiagnosticUBORestrictedSize] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "clspv restriction: UBO element size must be a "
                           "multiple of that element's alignment");
    CustomDiagnosticsIDMap[CustomDiagnosticUBORestrictedStruct] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "clspv restriction: UBO structures may not have implicit padding");
  }

  virtual bool HandleTopLevelDecl(DeclGroupRef DG) override {
    for (auto *D : DG) {
      if (auto *FD = llvm::dyn_cast<FunctionDecl>(D)) {
        // If the function has a body it means we are not an OpenCL builtin
        // function.
        if (FD->hasBody()) {
          if (!IsSupportedType(FD->getReturnType(),
                               FD->getReturnTypeSourceRange())) {
            return false;
          }

          bool is_opencl_kernel = false;
          if (FD->hasAttrs()) {
            for (auto* attr : FD->attrs()) {
              if (attr->getKind() == attr::Kind::OpenCLKernel) {
                is_opencl_kernel = true;
              }
            }
          }

          for (auto *P : FD->parameters()) {
            auto type = P->getType();
            if (!IsSupportedType(P->getOriginalType(), P->getSourceRange())) {
              return false;
            }

            if (is_opencl_kernel &&
                clspv::Option::ConstantArgsInUniformBuffer() &&
                type->isPointerType() &&
                type->getPointeeType().getAddressSpace() ==
                    LangAS::opencl_constant) {
              if (!IsSupportedUniformLayout(
                      type->getPointeeType(), 0,
                      FD->getASTContext(), P->getSourceRange())) {
                return false;
              }
            }
          }

          // Check for unsupported vector types.
          Visitor.TraverseDecl(FD);
        }
      }
    }

    return true;
  }
};

struct ExtraValidationASTAction final : public PluginASTAction {
  virtual std::unique_ptr<ASTConsumer>
  CreateASTConsumer(CompilerInstance &CI, llvm::StringRef InFile) override {
    return std::unique_ptr<ASTConsumer>(
        new ExtraValidationConsumer(CI, InFile));
  }

  virtual bool ParseArgs(const CompilerInstance &CI,
                         const std::vector<std::string> &arg) override {
    // Parsing succeeded.
    return true;
  }

  virtual PluginASTAction::ActionType getActionType() override {
    return PluginASTAction::AddBeforeMainAction;
  }
};
} // namespace

static FrontendPluginRegistry::Add<ExtraValidationASTAction>
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

int main(const int argc, const char *const argv[]) {
  // We need to change how one of the called passes works by spoofing
  // ParseCommandLineOptions with the specific option.
  const int llvmArgc = 2;
  const char *llvmArgv[llvmArgc] = {
      argv[0], "-simplifycfg-sink-common=false",
  };

  llvm::cl::ParseCommandLineOptions(llvmArgc, llvmArgv);

  llvm::cl::ParseCommandLineOptions(argc, argv);

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

  llvm::StringRef overiddenInputFilename = InputFilename.getValue();

  // If we are reading our input file from stdin.
  if ("-" == InputFilename) {
    // We need to overwrite the file name we use.
    overiddenInputFilename = "stdin.cl";
  }

  auto errorOrInputFile =
      llvm::MemoryBuffer::getFileOrSTDIN(InputFilename.getValue());

  // If there was an error in getting the input file.
  if (!errorOrInputFile) {
    llvm::errs() << "Error: " << errorOrInputFile.getError().message() << " '"
                 << InputFilename.getValue() << "'\n";
    return -1;
  }

  // if no output file was provided, use a default
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

  std::string descriptor_map;
  llvm::raw_string_ostream descriptor_map_out(descriptor_map);

  llvm::SmallVector<std::pair<unsigned, std::string>, 8> SamplerMapEntries;

  if (!SamplerMap.empty()) {
    auto errorOrSamplerMapFile =
        llvm::MemoryBuffer::getFile(SamplerMap.getValue());

    // If there was an error in getting the sampler map file.
    if (!errorOrSamplerMapFile) {
      llvm::errs() << "Error: " << errorOrSamplerMapFile.getError().message()
                   << " '" << SamplerMap.getValue() << "'\n";
      return -1;
    }

    auto samplerMapBuffer = std::move(errorOrSamplerMapFile.get());

    if (0 == samplerMapBuffer->getBufferSize()) {
      llvm::errs() << "Error: Sampler map was an empty file!\n";
      return -1;
    }

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

        SamplerMapEntries.emplace_back(
            NormalizedCoord | AddressingMode | FilterMode, samplerExpr);

        // And reset the sampler strings for the next sampler in the map.
        samplerStrings.clear();
      }

      // And lastly, if we are at the end of the file
      if (i == e) {
        break;
      }
    }
  }

  // Create a memory buffer for temporarily writing the result.
  SmallVector<char, 10000> binary;
  llvm::raw_svector_ostream binaryStream(binary);

  clang::CompilerInstance instance;

  if (verify) {
    instance.getDiagnosticOpts().VerifyDiagnostics = true;
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
  instance.getDiagnosticOpts().IgnoreWarnings = false;

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
  if (cl_fast_relaxed_math) {
    instance.getPreprocessorOpts().addMacroDef("__FAST_RELAXED_MATH__");
  }

  for (auto define : Defines) {
    instance.getPreprocessorOpts().addMacroDef(define);
  }

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
  std::string log;
  llvm::raw_string_ostream diagnosticsStream(log);
  instance.createDiagnostics(
      new clang::TextDiagnosticPrinter(diagnosticsStream,
                                       &instance.getDiagnosticOpts()),
      true);

  instance.getTargetOpts().Triple = triple.str();

  instance.getCodeGenOpts().MainFileName = overiddenInputFilename;
  instance.getCodeGenOpts().PreserveVec3Type = true;
  // Disable generation of lifetime intrinsic.
  instance.getCodeGenOpts().DisableLifetimeMarkers = true;
  clang::FrontendInputFile kernelFile(overiddenInputFilename,
                                      clang::InputKind::OpenCL);
  instance.getFrontendOpts().Inputs.push_back(kernelFile);
  instance.getPreprocessorOpts().addRemappedFile(
      overiddenInputFilename, errorOrInputFile.get().release());

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

  llvm::legacy::PassManager pm;

  llvm::PassManagerBuilder pmBuilder;

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

  pm.add(clspv::createZeroInitializeAllocasPass());
  pm.add(clspv::createDefineOpenCLWorkItemBuiltinsPass());

  if (0 < pmBuilder.OptLevel) {
    pm.add(clspv::createOpenCLInlinerPass());
  }

  pm.add(clspv::createUndoByvalPass());
  pm.add(clspv::createUndoSRetPass());
  if (cluster_non_pointer_kernel_args) {
    pm.add(clspv::createClusterPodKernelArgumentsPass());
  }
  pm.add(clspv::createReplaceOpenCLBuiltinPass());

  // We need to run mem2reg and inst combine early because our
  // createInlineFuncWithPointerBitCastArgPass pass cannot handle the pattern
  //   %1 = alloca i32 1
  //        store <something> %1
  //   %2 = bitcast float* %1
  //   %3 = load float %2
  pm.add(llvm::createPromoteMemoryToRegisterPass());

  // Hide loads from __constant address space away from instcombine.
  // This prevents us from generating select between pointers-to-__constant.
  // See https://github.com/google/clspv/issues/71
  pm.add(clspv::createHideConstantLoadsPass());

  pm.add(llvm::createInstructionCombiningPass());

  if (clspv::Option::InlineEntryPoints()) {
    pm.add(clspv::createInlineEntryPointsPass());
  } else {
    pm.add(clspv::createInlineFuncWithPointerBitCastArgPass());
    pm.add(clspv::createInlineFuncWithPointerToFunctionArgPass());
    pm.add(clspv::createInlineFuncWithSingleCallSitePass());
  }

  if (0 == pmBuilder.OptLevel) {
    // Mem2Reg pass should be run early because O0 level optimization leaves
    // redundant alloca, load and store instructions from function arguments.
    // clspv needs to remove them ahead of transformation.
    pm.add(llvm::createPromoteMemoryToRegisterPass());

    // SROA pass is run because it will fold structs/unions that are problematic
    // on Vulkan SPIR-V away.
    pm.add(llvm::createSROAPass());

    // InstructionCombining pass folds bitcast and gep instructions which are
    // not supported by Vulkan SPIR-V.
    pm.add(llvm::createInstructionCombiningPass());
  }

  // Now we add any of the LLVM optimizations we wanted
  pmBuilder.populateModulePassManager(pm);

  // Unhide loads from __constant address space.  Undoes the action of
  // HideConstantLoadsPass.
  pm.add(clspv::createUnhideConstantLoadsPass());

  pm.add(clspv::createFunctionInternalizerPass());
  pm.add(clspv::createReplaceLLVMIntrinsicsPass());
  pm.add(clspv::createUndoBoolPass());
  pm.add(clspv::createUndoTruncatedSwitchConditionPass());
  pm.add(llvm::createStructurizeCFGPass(false));
  pm.add(clspv::createReorderBasicBlocksPass());
  pm.add(clspv::createUndoGetElementPtrConstantExprPass());
  pm.add(clspv::createSplatArgPass());
  pm.add(clspv::createSimplifyPointerBitcastPass());
  pm.add(clspv::createReplacePointerBitcastPass());

  pm.add(clspv::createUndoTranslateSamplerFoldPass());

  if (clspv::Option::ModuleConstantsInStorageBuffer()) {
    pm.add(clspv::createClusterModuleScopeConstantVars());
  }

  pm.add(clspv::createShareModuleScopeVariablesPass());
  pm.add(clspv::createAllocateDescriptorsPass(SamplerMapEntries));
  pm.add(llvm::createVerifierPass());
  pm.add(clspv::createDirectResourceAccessPass());
  // Replacing pointer bitcasts can leave some trivial GEPs
  // that are easy to remove.  Also replace GEPs of GEPS
  // left by replacing indirect buffer accesses.
  pm.add(clspv::createSimplifyPointerBitcastPass());

  pm.add(clspv::createSplatSelectConditionPass());
  pm.add(clspv::createSignedCompareFixupPass());
  // This pass generates insertions that need to be rewritten.
  pm.add(clspv::createScalarizePass());
  pm.add(clspv::createRewriteInsertsPass());
  // This pass mucks with types to point where you shouldn't rely on DataLayout
  // anymore so leave this right before SPIR-V generation.
  pm.add(clspv::createUBOTypeTransformPass());
  pm.add(clspv::createSPIRVProducerPass(
      binaryStream, descriptor_map_out, SamplerMapEntries,
      OutputAssembly.getValue(), OutputFormat == "c"));
  pm.run(*module);

  // Write outputs

  // Write the descriptor map, if requested.
  std::error_code error;
  if (!DescriptorMapFilename.empty()) {
    descriptor_map_out.flush();

    llvm::raw_fd_ostream descriptor_map_out_fd(DescriptorMapFilename, error,
                                               llvm::sys::fs::F_RW |
                                                   llvm::sys::fs::F_Text);
    if (error) {
      llvm::errs() << "Unable to open descriptor map file '"
                   << DescriptorMapFilename << "': " << error.message() << '\n';
      return -1;
    }
    descriptor_map_out_fd << descriptor_map;
    descriptor_map_out_fd.close();
  }

  // Write the resulting binary.
  // Wait until now to try writing the file so that we only write it on
  // successful compilation.
  llvm::raw_fd_ostream outStream(OutputFilename, error, llvm::sys::fs::F_RW);

  if (error) {
    llvm::errs() << "Unable to open output file '" << OutputFilename
                 << "': " << error.message() << '\n';
    return -1;
  }
  outStream << binaryStream.str();

  return 0;
}
