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

#include "clang/AST/RecordLayout.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Basic/TargetInfo.h"
#include "clang/CodeGen/CodeGenAction.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/Frontend/TextDiagnosticPrinter.h"

#include "clspv/Option.h"

#include "FrontendPlugin.h"

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
        const auto prev_size =
            context.getTypeSizeInChars(prev_canonical).getQuantity();
        const auto prev_alignment = GetAlignment(prev_canonical, context);
        const auto next_available =
            prev_offset + llvm::alignTo(prev_size, prev_alignment);
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
    CustomDiagnosticsIDMap[CustomDiagnosticUBOUnalignedScalar] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "in an UBO, scalar elements must be aligned to their size");
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
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
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
            for (auto *attr : FD->attrs()) {
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
              if (!IsSupportedUniformLayout(type->getPointeeType(), 0,
                                            FD->getASTContext(),
                                            P->getSourceRange())) {
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
} // namespace

namespace clspv {
std::unique_ptr<ASTConsumer>
ExtraValidationASTAction::CreateASTConsumer(CompilerInstance &CI,
                                            llvm::StringRef InFile) {
  return std::unique_ptr<ASTConsumer>(new ExtraValidationConsumer(CI, InFile));
}
} // namespace clspv
