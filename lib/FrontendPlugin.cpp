// Copyright 2018-2021 The Clspv Authors. All rights reserved.
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

#include "llvm/Support/Debug.h"

#include "clspv/Option.h"

#include "Constants.h"
#include "FrontendPlugin.h"

#include <algorithm>
#include <unordered_set>

using namespace clang;

namespace {

static uint32_t kClusteredCount = 0;

struct ExtraValidationConsumer final : public ASTConsumer {
private:
  CompilerInstance &Instance;
  llvm::StringRef InFile;

  enum Layout { UBO, SSBO };

  enum CustomDiagnosticType {
    CustomDiagnosticVectorsMoreThan4Elements,
    CustomDiagnosticVoidPointer,
    CustomDiagnosticUnalignedScalar,
    CustomDiagnosticUnalignedVec2,
    CustomDiagnosticUnalignedVec4,
    CustomDiagnosticUBOUnalignedArray,
    CustomDiagnosticUBOUnalignedStruct,
    CustomDiagnosticSmallStraddle,
    CustomDiagnosticLargeStraddle,
    CustomDiagnosticUnalignedStructMember,
    CustomDiagnosticUBORestrictedSize,
    CustomDiagnosticUBORestrictedStruct,
    CustomDiagnosticUBOArrayStride,
    CustomDiagnosticLocationInfo,
    CustomDiagnosticSSBOUnalignedArray,
    CustomDiagnosticSSBOUnalignedStruct,
    CustomDiagnosticOverloadedKernel,
    CustomDiagnosticStructContainsPointer,
    CustomDiagnosticRecursiveStruct,
    CustomDiagnosticPushConstantSizeExceeded,
    CustomDiagnosticPushConstantContainsArray,
    CustomDiagnosticUnsupported16BitStorage,
    CustomDiagnosticUnsupported8BitStorage,
    CustomDiagnosticUnsupportedPipes,
    CustomDiagnosticMemoryOrderSeqCst,
    CustomDiagnosticMemoryOrderScopeConstant,
    CustomDiagnosticMemoryScopeAllDevices,
    CustomDiagnosticMemoryScopeWorkItem,
    CustomDiagnosticAtomicClearAcquire,
    CustomDiagnosticInt128,
    CustomDiagnosticTotal
  };
  std::vector<unsigned> CustomDiagnosticsIDMap;

  clspv::Option::StorageClass ConvertToStorageClass(clang::LangAS aspace) {
    switch (aspace) {
    case LangAS::opencl_constant:
      if (clspv::Option::ConstantArgsInUniformBuffer()) {
        return clspv::Option::StorageClass::kUBO;
      } else {
        return clspv::Option::StorageClass::kSSBO;
      }
    case LangAS::opencl_global:
    default:
      return clspv::Option::StorageClass::kSSBO;
    }
  }

  bool ContainsSizedType(QualType QT, uint32_t width) {
    auto canonical = QT.getCanonicalType();
    if (auto *BT = dyn_cast<BuiltinType>(canonical)) {
      switch (BT->getKind()) {
      case BuiltinType::UShort:
      case BuiltinType::Short:
      case BuiltinType::Half:
      case BuiltinType::Float16:
        return width == 16;
      case BuiltinType::UChar:
      case BuiltinType::Char_U:
      case BuiltinType::SChar:
      case BuiltinType::Char_S:
        return width == 8;
      default:
        return false;
      }
    } else if (auto *PT = dyn_cast<PointerType>(canonical)) {
      return ContainsSizedType(PT->getPointeeType(), width);
    } else if (auto *AT = dyn_cast<ArrayType>(canonical)) {
      return ContainsSizedType(AT->getElementType(), width);
    } else if (auto *VT = dyn_cast<VectorType>(canonical)) {
      return ContainsSizedType(VT->getElementType(), width);
    } else if (auto *RT = dyn_cast<RecordType>(canonical)) {
      for (auto field_decl : RT->getDecl()->fields()) {
        if (ContainsSizedType(field_decl->getType(), width))
          return true;
      }
    }

    return false;
  }

  bool ContainsPointerType(QualType QT) {
    auto canonical = QT.getCanonicalType();
    if (canonical->isPointerType()) {
      return true;
    } else if (auto *AT = dyn_cast<ArrayType>(canonical)) {
      return ContainsPointerType(AT->getElementType());
    } else if (auto *RT = dyn_cast<RecordType>(canonical)) {
      for (auto field_decl : RT->getDecl()->fields()) {
        if (ContainsPointerType(field_decl->getType()))
          return true;
      }
    }

    return false;
  }

  bool ContainsArrayType(QualType QT) {
    auto canonical = QT.getCanonicalType();
    if (auto *PT = dyn_cast<PointerType>(canonical)) {
      return ContainsArrayType(PT->getPointeeType());
    } else if (isa<ArrayType>(canonical)) {
      return true;
    } else if (auto *RT = dyn_cast<RecordType>(canonical)) {
      for (auto field_decl : RT->getDecl()->fields()) {
        if (ContainsArrayType(field_decl->getType()))
          return true;
      }
    }

    return false;
  }

  bool IsRecursiveType(QualType QT, llvm::DenseSet<const Type *> *seen) {
    auto canonical = QT.getCanonicalType();
    if (canonical->isRecordType() &&
        !seen->insert(canonical.getTypePtr()).second) {
      return true;
    }

    if (auto *PT = dyn_cast<PointerType>(canonical)) {
      return IsRecursiveType(PT->getPointeeType(), seen);
    } else if (auto *AT = dyn_cast<ArrayType>(canonical)) {
      return IsRecursiveType(AT->getElementType(), seen);
    } else if (auto *RT = dyn_cast<RecordType>(canonical)) {
      for (auto field_decl : RT->getDecl()->fields()) {
        if (IsRecursiveType(field_decl->getType(), seen))
          return true;
      }
    }

    seen->erase(canonical.getTypePtr());
    return false;
  }

  bool IsSupportedType(QualType QT, SourceRange SR, bool IsKernelParameter) {
    auto *Ty = QT.getTypePtr();

    // Reject Pipe types with an error
    if (Ty->getTypeClass() == Type::Pipe) {
      Instance.getDiagnostics().Report(
          SR.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticUnsupportedPipes]);
      return false;
    }

    // First check if we have a pointer type.
    if (Ty->isPointerType() || (!IsKernelParameter && Ty->isReferenceType())) {
      const Type *pointeeTy = Ty->getPointeeType().getTypePtr();
      if (pointeeTy && pointeeTy->isVoidType() &&
          !clspv::Option::Int8Support()) {
        // We don't support void pointers.
        Instance.getDiagnostics().Report(
            SR.getBegin(), CustomDiagnosticsIDMap[CustomDiagnosticVoidPointer]);
        return false;
      }
      // Otherwise check recursively.
      return IsSupportedType(Ty->getPointeeType(), SR, IsKernelParameter);
    }

    const auto &canonicalType = QT.getCanonicalType();
    if (auto *VT = llvm::dyn_cast<ExtVectorType>(canonicalType)) {
      // We don't support vectors with more than 4 elements under all
      // circumstances.
      if (clspv::SPIRVMaxVectorSize() < VT->getNumElements() &&
          !clspv::Option::LongVectorSupport()) {
        Report(CustomDiagnosticVectorsMoreThan4Elements, SR, SR);
        return false;
      }

      return true;
    }

    if (auto *RT = llvm::dyn_cast<RecordType>(canonicalType)) {
      // Do not allow recursive struct definitions.
      llvm::DenseSet<const Type *> seen;
      if (IsRecursiveType(canonicalType, &seen)) {
        Instance.getDiagnostics().Report(
            SR.getBegin(),
            CustomDiagnosticsIDMap[CustomDiagnosticRecursiveStruct]);
        return false;
      }

      // To avoid infinite recursion, first verify that the record is not
      // recursive and then that its fields are supported.
      for (auto *field_decl : RT->getDecl()->fields()) {
        if (!IsSupportedType(field_decl->getType(), SR, IsKernelParameter)) {
          return false;
        }
      }

      return true;
    }

    if (auto *AT = llvm::dyn_cast<ArrayType>(canonicalType)) {
      return IsSupportedType(AT->getElementType(), SR, IsKernelParameter);
    }

    // For function prototypes, recurse on return type and parameter types.
    if (auto *FT = llvm::dyn_cast<FunctionProtoType>(canonicalType)) {
      IsKernelParameter =
          IsKernelParameter || (FT->getCallConv() == CC_DeviceKernel);
      for (auto param : FT->getParamTypes()) {
        if (!IsSupportedType(param, SR, IsKernelParameter)) {
          return false;
        }
      }

      if (!IsSupportedType(FT->getReturnType(), SR, IsKernelParameter)) {
        return false;
      }

      return true;
    }

    if (QT->isEnumeralType()) {
      return true;
    }

    if (auto *BT = llvm::dyn_cast<BuiltinType>(canonicalType)) {
      switch (BT->getKind()) {
      case clang::BuiltinType::ULongLong:
      case clang::BuiltinType::UInt128:
      case clang::BuiltinType::LongLong:
      case clang::BuiltinType::Int128:
        Instance.getDiagnostics().Report(
            SR.getBegin(), CustomDiagnosticsIDMap[CustomDiagnosticInt128]);
        return false;
      default:
        return true;
      }
    }

    if (QT->isAtomicType()) {
      return true;
    }

#ifndef NDEBUG
    llvm::dbgs() << "IsSupportedType lacks support for QualType: "
                 << QT.getAsString() << '\n';
#endif
    llvm_unreachable("Type not covered by IsSupportedType.");
  }

  // Report a diagnostic using |diag|. If |arg_range| and |specific_range|
  // differ, also issue a note with the specific location of the error.
  void Report(const CustomDiagnosticType &diag, SourceRange arg_range,
              SourceRange specific_range) {
    Instance.getDiagnostics().Report(arg_range.getBegin(),
                                     CustomDiagnosticsIDMap[diag]);
    if (arg_range != specific_range) {
      Instance.getDiagnostics().Report(
          specific_range.getBegin(),
          CustomDiagnosticsIDMap[CustomDiagnosticLocationInfo]);
    }
  }

  // Returns the alignment of |QT| to satisfy |layout|'s rules.
  uint64_t GetAlignment(const QualType QT, const Layout &layout,
                        const ASTContext &context) const {
    const auto canonical = QT.getCanonicalType();
    uint64_t alignment = context.getTypeAlignInChars(canonical).getQuantity();
    if (layout == UBO &&
        (canonical->isRecordType() || canonical->isArrayType())) {
      return llvm::alignTo(alignment, 16);
    }
    return alignment;
  }

  // Returns true if |QT| is a valid layout for a Uniform buffer. Refer to
  // 14.5.4 in the Vulkan specification.
  bool IsSupportedLayout(QualType QT, uint64_t offset, const Layout &layout,
                         ASTContext &context, SourceRange arg_range,
                         SourceRange specific_range) {
    const auto canonical = QT.getCanonicalType();
    if (canonical->isScalarType()) {
      if (!IsSupportedScalarLayout(canonical, offset, layout, context,
                                   arg_range, specific_range))
        return false;
    } else if (canonical->isExtVectorType()) {
      if (!IsSupportedVectorLayout(canonical, offset, layout, context,
                                   arg_range, specific_range))
        return false;
    } else if (canonical->isArrayType()) {
      if (!IsSupportedArrayLayout(canonical, offset, layout, context, arg_range,
                                  specific_range))
        return false;
    } else if (canonical->isRecordType()) {
      if (!IsSupportedRecordLayout(canonical, offset, layout, context,
                                   arg_range, specific_range))
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
    const auto type_align = GetAlignment(canonical, layout, context);
    if (layout == UBO && (type_size % type_align != 0)) {
      Report(CustomDiagnosticUBORestrictedSize, arg_range, specific_range);
      return false;
    }

    return true;
  }

  bool IsSupportedScalarLayout(QualType QT, uint64_t offset,
                               const Layout & /*layout*/, ASTContext &context,
                               SourceRange arg_range,
                               SourceRange specific_range) {
    // A scalar type of size N has a base alignment on N.
    const unsigned type_size = context.getTypeSizeInChars(QT).getQuantity();
    if (offset % type_size != 0) {
      Report(CustomDiagnosticUnalignedScalar, arg_range, specific_range);
      return false;
    }

    return true;
  }

  bool IsSupportedVectorLayout(QualType QT, uint64_t offset,
                               const Layout &layout, ASTContext &context,
                               SourceRange arg_range,
                               SourceRange specific_range) {
    // 2-component vectors have a base alignment of 2 * (size of element).
    // 3- and 4-component vectors hae a base alignment of 4 * (size of
    // element).
    const auto *VT = llvm::cast<VectorType>(QT);
    const auto ele_size =
        context.getTypeSizeInChars(VT->getElementType()).getQuantity();
    if (VT->getNumElements() == 2) {
      if (offset % (ele_size * 2) != 0) {
        Report(CustomDiagnosticUnalignedVec2, arg_range, specific_range);
        return false;
      }
    } else if (offset % (ele_size * 4) != 0) {
      // Other vector sizes cause errors elsewhere.
      Report(CustomDiagnosticUnalignedVec4, arg_range, specific_range);
      return false;
    }

    // Straddling rules:
    // * If total vector size is less than 16 bytes, the offset must place the
    // entire vector within the same 16 bytes.
    // * If total vector size is greater than 16 bytes, the offset must be a
    // multiple of 16.
    const auto size = context.getTypeSizeInChars(QT).getQuantity();
    if (size <= 16 && (offset / 16 != (offset + size - 1) / 16)) {
      Report(CustomDiagnosticSmallStraddle, arg_range, specific_range);
      return false;
    } else if (size > 16 && (offset % 16 != 0)) {
      Report(CustomDiagnosticLargeStraddle, arg_range, specific_range);
      return false;
    }

    return IsSupportedLayout(VT->getElementType(), offset, layout, context,
                             arg_range, specific_range);
  }

  bool IsSupportedArrayLayout(QualType QT, uint64_t offset,
                              const Layout &layout, ASTContext &context,
                              SourceRange arg_range,
                              SourceRange specific_range) {
    // An array has a base alignment of is element type.
    // If the layout is UBO, the alignment is rounded up to a multiple of 16.
    const auto *AT = llvm::cast<ArrayType>(QT);
    const auto element_align =
        GetAlignment(AT->getElementType(), layout, context);
    const auto type_align =
        layout == UBO ? llvm::alignTo(element_align, 16) : element_align;
    if (offset % type_align != 0) {
      auto diag_id = layout == UBO ? CustomDiagnosticUBOUnalignedArray
                                   : CustomDiagnosticSSBOUnalignedArray;
      Report(diag_id, arg_range, specific_range);
      return false;
    }
    if (layout == UBO && !clspv::Option::RelaxedUniformBufferLayout()) {
      // The ArrayStride must be a multiple of the base alignment of the array
      // (i.e. a multiple of 16).  This means that the element size must be
      // restricted to be the base alignment of the array.
      const auto element_size =
          context.getTypeSizeInChars(AT->getElementType()).getQuantity();
      if (element_size % type_align != 0) {
        Report(CustomDiagnosticUBOArrayStride, arg_range, specific_range);
        return false;
      }
    }

    return IsSupportedLayout(AT->getElementType(), offset, layout, context,
                             arg_range, specific_range);
  }

  bool IsSupportedRecordLayout(QualType QT, uint64_t offset,
                               const Layout &layout, ASTContext &context,
                               SourceRange arg_range,
                               SourceRange specific_range) {
    // A structure has a base alignment of its largest member. For UBO layouts,
    // alignment is rounded up to a multiple of 16.
    const auto *RT = llvm::cast<RecordType>(QT);
    auto type_alignment = GetAlignment(QT, layout, context);
    if (layout == UBO)
      llvm::alignTo(type_alignment, 16);
    if (offset % type_alignment != 0) {
      auto diag_id = layout == UBO ? CustomDiagnosticUBOUnalignedStruct
                                   : CustomDiagnosticSSBOUnalignedStruct;
      Report(diag_id, arg_range, specific_range);
      return false;
    }

    const auto &record_layout = context.getASTRecordLayout(RT->getDecl());
    const FieldDecl *prev = nullptr;
    for (auto field_decl : RT->getDecl()->fields()) {
      const auto field_type = field_decl->getType();
      const unsigned field_no = field_decl->getFieldIndex();
      const uint64_t field_offset =
          record_layout.getFieldOffset(field_no) / context.getCharWidth();

      // Rules must be checked recursively.
      if (!IsSupportedLayout(field_type, field_offset + offset, layout, context,
                             arg_range, field_decl->getSourceRange())) {
        return false;
      }

      if (prev) {
        const auto prev_canonical = prev->getType().getCanonicalType();
        const uint64_t prev_offset =
            record_layout.getFieldOffset(field_no - 1) / context.getCharWidth();
        const auto prev_size =
            context.getTypeSizeInChars(prev_canonical).getQuantity();
        const auto prev_alignment =
            GetAlignment(prev_canonical, layout, context);
        const auto next_available =
            prev_offset + llvm::alignTo(prev_size, prev_alignment);
        if (prev_canonical->isArrayType() || prev_canonical->isRecordType()) {
          // The next element after an array or struct must be placed on or
          // after the next multiple of the alignment of that array or
          // struct.
          // For UBO layouts, both arrays and structs must be aligned to a
          // multiple of 16 bytes.
          const uint64_t final_align = layout == UBO
                                           ? llvm::alignTo(next_available, 16)
                                           : next_available;
          if (final_align > field_offset) {
            Report(CustomDiagnosticUnalignedStructMember, arg_range,
                   field_decl->getSourceRange());
            return false;
          }
        }
      }

      prev = field_decl;
    }

    return true;
  }

  bool isSupportedFunctionCall(CallExpr *C) {
    constexpr std::array<StringRef, 2> implicit_atomic_funcs{
        "atomic_flag_test_and_set",
        "atomic_flag_clear",
    };
    constexpr std::array<StringRef, 2> explicit_atomic_funcs{
        "atomic_flag_test_and_set_explicit",
        "atomic_flag_clear_explicit",
    };
    const auto callee_decl = C->getCalleeDecl();
    if (callee_decl) {
      const auto decl_name =
          cast<FunctionDecl>(C->getCalleeDecl())->getDeclName().getAsString();
      if (std::count(implicit_atomic_funcs.begin(), implicit_atomic_funcs.end(),
                     decl_name)) {
        Instance.getDiagnostics().Report(
            C->getSourceRange().getBegin(),
            CustomDiagnosticsIDMap[CustomDiagnosticMemoryOrderSeqCst]);
      }

      if (std::count(explicit_atomic_funcs.begin(), explicit_atomic_funcs.end(),
                     decl_name)) {
        const auto order = C->getArg(1);
        clang::Expr::EvalResult result;
        if (!order->EvaluateAsInt(result, callee_decl->getASTContext())) {
          Instance.getDiagnostics().Report(
              order->getSourceRange().getBegin(),
              CustomDiagnosticsIDMap[CustomDiagnosticMemoryOrderScopeConstant]);
        } else if (decl_name == explicit_atomic_funcs[1]) {
          const auto value = result.Val.getInt();
          if (value == 2 ||
              value == 4) { // memory_order_acquire/memory_order_acq_rel
            Instance.getDiagnostics().Report(
                order->getSourceRange().getBegin(),
                CustomDiagnosticsIDMap[CustomDiagnosticAtomicClearAcquire]);
          }
        }

        if (C->getNumArgs() > 2) {
          const auto scope = C->getArg(2);
          if (!scope->EvaluateAsInt(result, callee_decl->getASTContext())) {
            Instance.getDiagnostics().Report(
                scope->getSourceRange().getBegin(),
                CustomDiagnosticsIDMap
                    [CustomDiagnosticMemoryOrderScopeConstant]);
          } else {
            const auto value = result.Val.getInt();
            if (value == 0) { // memory_scope_work_item
              Instance.getDiagnostics().Report(
                  scope->getSourceRange().getBegin(),
                  CustomDiagnosticsIDMap[CustomDiagnosticMemoryScopeWorkItem]);
            } else if (value == 3) { // memory_scope_all(_svm)_devices
              Instance.getDiagnostics().Report(
                  scope->getSourceRange().getBegin(),
                  CustomDiagnosticsIDMap
                      [CustomDiagnosticMemoryScopeAllDevices]);
            }
          }
        }
      }
    }
    return true;
  }

  bool isSupportedDeclRef(DeclRefExpr *D) {
    if (auto enumConstant = dyn_cast<EnumConstantDecl>(D->getDecl())) {
      if (enumConstant->getName() == "memory_order_seq_cst") {
        Instance.getDiagnostics().Report(
            D->getSourceRange().getBegin(),
            CustomDiagnosticsIDMap[CustomDiagnosticMemoryOrderSeqCst]);
      }
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
    //
    // Looking at the Decl class hierarchy, it seems ValueDecl and TypeDecl
    // are the only two that might represent an unsupported vector type.
    bool VisitValueDecl(ValueDecl *VD) {
      return consumer.IsSupportedType(VD->getType(), VD->getSourceRange(),
                                      false);
    }
    bool VisitValueDecl(TypeDecl *TD) {
      QualType DefinedType = TD->getASTContext().getTypeDeclType(TD);
      return consumer.IsSupportedType(DefinedType, TD->getSourceRange(), false);
    }

    bool VisitCallExpr(CallExpr *C) {
      return consumer.isSupportedFunctionCall(C);
    }
    bool VisitDeclRefExpr(DeclRefExpr *D) {
      return consumer.isSupportedDeclRef(D);
    }
  };

  DeclVisitor Visitor;
  std::unordered_set<std::string> Kernels;

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
        DiagnosticsEngine::Error, "pointer-to-void is only supported with int8 "
                                  "support and opaque pointers");
    CustomDiagnosticsIDMap[CustomDiagnosticUnalignedScalar] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "scalar elements must be aligned to their size");
    CustomDiagnosticsIDMap[CustomDiagnosticUnalignedVec2] = DE.getCustomDiagID(
        DiagnosticsEngine::Error,
        "two-component vectors must be aligned to 2 times their element size");
    CustomDiagnosticsIDMap[CustomDiagnosticUnalignedVec4] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "three- and four-component vectors must be aligned "
                           "to 4 times their element size");
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
    CustomDiagnosticsIDMap[CustomDiagnosticSmallStraddle] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "vectors with a total size less than or equal to 16 "
                           "bytes must be placed entirely within a 16 byte "
                           "aligned region");
    CustomDiagnosticsIDMap[CustomDiagnosticLargeStraddle] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "vectors with a total size greater than 16 bytes "
                           "must aligned to 16 bytes");
    CustomDiagnosticsIDMap[CustomDiagnosticUnalignedStructMember] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "a structure member must not be placed between the "
                           "end of a structure or array and the next multiple "
                           "of the base alignment of that structure or array");
    CustomDiagnosticsIDMap[CustomDiagnosticUBORestrictedSize] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "clspv restriction: UBO element size must be a "
                           "multiple of that element's alignment");
    CustomDiagnosticsIDMap[CustomDiagnosticUBORestrictedStruct] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "clspv restriction: UBO structures may not have implicit padding");
    CustomDiagnosticsIDMap[CustomDiagnosticUBOArrayStride] = DE.getCustomDiagID(
        DiagnosticsEngine::Error,
        "clspv restriction: to satisfy UBO ArrayStride restrictions, element "
        "size must be a multiple of array alignment");
    CustomDiagnosticsIDMap[CustomDiagnosticLocationInfo] =
        DE.getCustomDiagID(DiagnosticsEngine::Note, "here");
    CustomDiagnosticsIDMap[CustomDiagnosticSSBOUnalignedArray] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "in a SSBO, arrays must be aligned to their element alignment");
    CustomDiagnosticsIDMap[CustomDiagnosticSSBOUnalignedStruct] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "in a SSBO, structs must be aligned to their "
                           "largest element alignment");
    CustomDiagnosticsIDMap[CustomDiagnosticOverloadedKernel] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "kernel functions can't be overloaded");
    CustomDiagnosticsIDMap[CustomDiagnosticStructContainsPointer] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "structures may not contain pointers");
    CustomDiagnosticsIDMap[CustomDiagnosticRecursiveStruct] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "recursive structures are not supported");
    CustomDiagnosticsIDMap[CustomDiagnosticPushConstantSizeExceeded] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "max push constant size exceeded");
    CustomDiagnosticsIDMap[CustomDiagnosticPushConstantContainsArray] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "arrays are not supported in push constants currently");
    CustomDiagnosticsIDMap[CustomDiagnosticUnsupported16BitStorage] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "16-bit storage is not supported for "
                           "%select{SSBOs|UBOs|push constants}0");
    CustomDiagnosticsIDMap[CustomDiagnosticUnsupported8BitStorage] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "8-bit storage is not supported for "
                           "%select{SSBOs|UBOs|push constants}0");
    CustomDiagnosticsIDMap[CustomDiagnosticUnsupportedPipes] =
        DE.getCustomDiagID(DiagnosticsEngine::Error, "pipes are not supported");
    CustomDiagnosticsIDMap[CustomDiagnosticMemoryOrderSeqCst] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Warning,
            "memory_order_seq_cst is treated as memory_order_acq_rel");
    CustomDiagnosticsIDMap[CustomDiagnosticMemoryOrderScopeConstant] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "Memory order and scope must be constant expressions when using "
            "the SPIR-V shader capability.");
    CustomDiagnosticsIDMap[CustomDiagnosticMemoryScopeAllDevices] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "memory_scope_all_svm_devices/"
                           "memory_scope_all_devices is not supported.");
    CustomDiagnosticsIDMap[CustomDiagnosticMemoryScopeWorkItem] =
        DE.getCustomDiagID(
            DiagnosticsEngine::Error,
            "memory_scope_work_item can only be used with "
            "atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.");
    CustomDiagnosticsIDMap[CustomDiagnosticAtomicClearAcquire] =
        DE.getCustomDiagID(DiagnosticsEngine::Error,
                           "The order of atomic_flag_clear_explicit cannot be "
                           "memory_order_acquire/memory_order_acq_rel.");
    CustomDiagnosticsIDMap[CustomDiagnosticInt128] = DE.getCustomDiagID(
        DiagnosticsEngine::Error, "128-bit Integers are not uspported.");
  }

  virtual bool HandleTopLevelDecl(DeclGroupRef DG) override {
    for (auto *D : DG) {
      if (auto *FD = llvm::dyn_cast<FunctionDecl>(D)) {
        // If the function has a body it means we are not an OpenCL builtin
        // function.
        if (FD->hasBody()) {
          if (!IsSupportedType(FD->getReturnType(),
                               FD->getReturnTypeSourceRange(), false)) {
            return false;
          }

          bool is_opencl_kernel = false;
          if (FD->hasAttrs()) {
            for (auto *attr : FD->attrs()) {
              if (attr->getKind() == attr::Kind::DeviceKernel) {
                is_opencl_kernel = true;
              }
            }
          }

          if (is_opencl_kernel) {
            if (Kernels.count(FD->getName().str()) != 0) {
              auto srcRange = FD->getSourceRange();
              Report(CustomDiagnosticOverloadedKernel, srcRange, srcRange);
            } else {
              Kernels.insert(FD->getName().str());
            }
          }

          RecordDecl *clustered_args = nullptr;
          if (is_opencl_kernel && clspv::Option::PodArgsInPushConstants()) {
            clustered_args = FD->getASTContext().buildImplicitRecord(
                "__clspv.clustered_args." + std::to_string(kClusteredCount++));
            clustered_args->startDefinition();
          }
          for (auto *P : FD->parameters()) {
            auto type = P->getType();
            if (!IsSupportedType(P->getOriginalType(), P->getSourceRange(),
                                 is_opencl_kernel)) {
              return false;
            }

            if (is_opencl_kernel && type->isPointerType() &&
                ((type->getPointeeType().getAddressSpace() ==
                  LangAS::opencl_constant) ||
                 (type->getPointeeType().getAddressSpace() ==
                  LangAS::opencl_global))) {
              // The argument will be generated as an array within a block.
              // Generate an array type to check the validity for the generated
              // case.
              Layout layout = SSBO;
              if (clspv::Option::ConstantArgsInUniformBuffer() &&
                  !clspv::Option::Std430UniformBufferLayout() &&
                  type->getPointeeType().getAddressSpace() ==
                      LangAS::opencl_constant) {
                layout = UBO;
              }
              auto array_type = FD->getASTContext().getIncompleteArrayType(
                  type->getPointeeType(), clang::ArraySizeModifier::Normal, 0);
              if (!clspv::Option::RewritePackedStructs() &&
                  !IsSupportedLayout(array_type, 0, layout, FD->getASTContext(),
                                     P->getSourceRange(),
                                     P->getSourceRange())) {
                return false;
              }
            }

            // Check if storage capabilities are supported.
            if (is_opencl_kernel) {
              bool contains_16bit =
                  ContainsSizedType(type.getCanonicalType(), 16);
              bool contains_8bit =
                  ContainsSizedType(type.getCanonicalType(), 8);
              auto sc = clspv::Option::StorageClass::kSSBO;
              if (type->isPointerType()) {
                sc = ConvertToStorageClass(
                    type->getPointeeType().getAddressSpace());
              } else if (clspv::Option::PodArgsInUniformBuffer()) {
                sc = clspv::Option::StorageClass::kUBO;
              } else if (clspv::Option::PodArgsInPushConstants()) {
                sc = clspv::Option::StorageClass::kPushConstant;
              }

              if (type->isPointerType() ||
                  sc != clspv::Option::StorageClass::kSSBO ||
                  !clspv::Option::ClusterPodKernelArgs()) {
                // For clustered pod args, assume we can fall back on
                // type-mangling.
                if (contains_16bit &&
                    !clspv::Option::Supports16BitStorageClass(sc)) {
                  Instance.getDiagnostics().Report(
                      P->getSourceRange().getBegin(),
                      CustomDiagnosticsIDMap
                          [CustomDiagnosticUnsupported16BitStorage])
                      << static_cast<int>(sc);
                }
                if (contains_8bit &&
                    !clspv::Option::Supports8BitStorageClass(sc)) {
                  Instance.getDiagnostics().Report(
                      P->getSourceRange().getBegin(),
                      CustomDiagnosticsIDMap
                          [CustomDiagnosticUnsupported8BitStorage])
                      << static_cast<int>(sc);
                }
              }
            }

            if (is_opencl_kernel && type->isPointerType()) {
              auto pointee_type = type->getPointeeType().getCanonicalType();
              if (ContainsPointerType(pointee_type)) {
                Instance.getDiagnostics().Report(
                    P->getSourceRange().getBegin(),
                    CustomDiagnosticsIDMap
                        [CustomDiagnosticStructContainsPointer]);
                return false;
              }
            }

            if (is_opencl_kernel && !type->isPointerType()) {
              if (clspv::Option::PodArgsInPushConstants()) {
                // Don't allow arrays in push constants currently.
                if (ContainsArrayType(type)) {
                  Report(CustomDiagnosticPushConstantContainsArray,
                         P->getSourceRange(), P->getSourceRange());
                  return false;
                }
                FieldDecl *field_decl = FieldDecl::Create(
                    FD->getASTContext(),
                    Decl::castToDeclContext(clustered_args),
                    P->getSourceRange().getBegin(),
                    P->getSourceRange().getEnd(), P->getIdentifier(),
                    P->getType(), nullptr, nullptr, false, ICIS_NoInit);
                field_decl->setAccess(AS_public);
                clustered_args->addDecl(field_decl);
              } else {
                Layout layout = SSBO;
                if (clspv::Option::PodArgsInUniformBuffer() &&
                    !clspv::Option::Std430UniformBufferLayout())
                  layout = UBO;

                if (!IsSupportedLayout(type, 0, layout, FD->getASTContext(),
                                       P->getSourceRange(),
                                       P->getSourceRange())) {
                  return false;
                }
              }
            }
          }

          if (clustered_args) {
            clustered_args->completeDefinition();
            if (!clustered_args->field_empty()) {
              auto record_type =
                  FD->getASTContext().getCanonicalTagType(clustered_args);
              if (!IsSupportedLayout(record_type, 0, SSBO, FD->getASTContext(),
                                     FD->getSourceRange(),
                                     FD->getSourceRange())) {
                return false;
              }

              if (FD->getASTContext()
                      .getTypeSizeInChars(record_type)
                      .getQuantity() > clspv::Option::MaxPushConstantsSize()) {
                Report(CustomDiagnosticPushConstantSizeExceeded,
                       FD->getSourceRange(), FD->getSourceRange());
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

class EntryPointAttrsConsumer final : public clang::ASTConsumer {
public:
  EntryPointAttrsConsumer(ASTContext *c) : context(c) {}
  virtual bool HandleTopLevelDecl(clang::DeclGroupRef DG) override {
    for (auto *D : DG) {
      if (auto *FD = llvm::dyn_cast<clang::FunctionDecl>(D)) {
        if (FD->hasBody() && FD->hasAttrs()) {
          std::string str;
          llvm::raw_string_ostream ss(str);
          bool kernel_attr_present = false;
          for (auto &A : FD->getAttrs()) {
            kernel_attr_present |= std::strcmp(A->getSpelling(), "kernel");
            kernel_attr_present |= std::strcmp(A->getSpelling(), "spir_kernel");
            // TODO maybe trim string

            // TODO stop the formatting
            A->printPretty(ss, context->getPrintingPolicy());
          }
          if (kernel_attr_present) {
            auto attr_str = ss.str();
            // inline newlines should be removed
            attr_str.erase(remove(attr_str.begin(), attr_str.end(), '\n'),
                           attr_str.end());
            FD->addAttr(AnnotateAttr::Create(FD->getASTContext(), attr_str,
                                             nullptr, 0, FD->getSourceRange()));
          }
        }
      }
    }
    return true; // TODO why true
  }

private:
  ASTContext *context;
};

} // namespace

namespace clspv {
std::unique_ptr<ASTConsumer>
ExtraValidationASTAction::CreateASTConsumer(CompilerInstance &CI,
                                            llvm::StringRef InFile) {
  return std::unique_ptr<ASTConsumer>(new ExtraValidationConsumer(CI, InFile));
}
std::unique_ptr<ASTConsumer>
EntryPointAttrsASTAction::CreateASTConsumer(CompilerInstance &CI,
                                            llvm::StringRef InFile) {
  return std::unique_ptr<ASTConsumer>(
      new EntryPointAttrsConsumer(&CI.getASTContext()));
}
} // namespace clspv
