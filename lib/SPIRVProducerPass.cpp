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

#ifdef _MSC_VER
#pragma warning(push, 0)
#endif

#include <cassert>
#include <cstring>
#include <iomanip>
#include <list>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <tuple>
#include <unordered_set>
#include <utility>

#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include "spirv/1.0/spirv.hpp"

#include "clspv/AddressSpace.h"
#include "clspv/DescriptorMap.h"
#include "clspv/Option.h"
#include "clspv/spirv_c_strings.hpp"
#include "clspv/spirv_glsl.hpp"

#include "ArgKind.h"
#include "ConstantEmitter.h"
#include "Constants.h"
#include "DescriptorCounter.h"
#include "NormalizeGlobalVariable.h"
#include "Passes.h"

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

using namespace llvm;
using namespace clspv;
using namespace mdconst;

namespace {

cl::opt<bool> ShowResourceVars("show-rv", cl::init(false), cl::Hidden,
                               cl::desc("Show resource variable creation"));

// These hacks exist to help transition code generation algorithms
// without making huge noise in detailed test output.
const bool Hack_generate_runtime_array_stride_early = true;

// The value of 1/pi.  This value is from MSDN
// https://msdn.microsoft.com/en-us/library/4hwaceh6.aspx
const double kOneOverPi = 0.318309886183790671538;
const glsl::ExtInst kGlslExtInstBad = static_cast<glsl::ExtInst>(0);

const char *kCompositeConstructFunctionPrefix = "clspv.composite_construct.";

enum SPIRVOperandType {
  NUMBERID,
  LITERAL_INTEGER,
  LITERAL_STRING,
  LITERAL_FLOAT
};

struct SPIRVOperand {
  explicit SPIRVOperand(SPIRVOperandType Ty, uint32_t Num)
      : Type(Ty), LiteralNum(1, Num) {}
  explicit SPIRVOperand(SPIRVOperandType Ty, const char *Str)
      : Type(Ty), LiteralStr(Str) {}
  explicit SPIRVOperand(SPIRVOperandType Ty, StringRef Str)
      : Type(Ty), LiteralStr(Str) {}
  explicit SPIRVOperand(SPIRVOperandType Ty, ArrayRef<uint32_t> NumVec)
      : Type(Ty), LiteralNum(NumVec.begin(), NumVec.end()) {}

  SPIRVOperandType getType() { return Type; };
  uint32_t getNumID() { return LiteralNum[0]; };
  std::string getLiteralStr() { return LiteralStr; };
  ArrayRef<uint32_t> getLiteralNum() { return LiteralNum; };

  uint32_t GetNumWords() const {
    switch (Type) {
    case NUMBERID:
      return 1;
    case LITERAL_INTEGER:
    case LITERAL_FLOAT:
      return uint32_t(LiteralNum.size());
    case LITERAL_STRING:
      // Account for the terminating null character.
      return uint32_t((LiteralStr.size() + 4) / 4);
    }
    llvm_unreachable("Unhandled case in SPIRVOperand::GetNumWords()");
  }

private:
  SPIRVOperandType Type;
  std::string LiteralStr;
  SmallVector<uint32_t, 4> LiteralNum;
};

class SPIRVOperandList {
public:
  SPIRVOperandList() {}
  SPIRVOperandList(const SPIRVOperandList &other) = delete;
  SPIRVOperandList(SPIRVOperandList &&other) {
    contents_ = std::move(other.contents_);
    other.contents_.clear();
  }
  SPIRVOperandList(ArrayRef<SPIRVOperand *> init)
      : contents_(init.begin(), init.end()) {}
  operator ArrayRef<SPIRVOperand *>() { return contents_; }
  void push_back(SPIRVOperand *op) { contents_.push_back(op); }
  void clear() { contents_.clear(); }
  size_t size() const { return contents_.size(); }
  SPIRVOperand *&operator[](size_t i) { return contents_[i]; }

  const SmallVector<SPIRVOperand *, 8> &getOperands() const {
    return contents_;
  }

private:
  SmallVector<SPIRVOperand *, 8> contents_;
};

SPIRVOperandList &operator<<(SPIRVOperandList &list, SPIRVOperand *elem) {
  list.push_back(elem);
  return list;
}

SPIRVOperand *MkNum(uint32_t num) {
  return new SPIRVOperand(LITERAL_INTEGER, num);
}
SPIRVOperand *MkInteger(ArrayRef<uint32_t> num_vec) {
  return new SPIRVOperand(LITERAL_INTEGER, num_vec);
}
SPIRVOperand *MkFloat(ArrayRef<uint32_t> num_vec) {
  return new SPIRVOperand(LITERAL_FLOAT, num_vec);
}
SPIRVOperand *MkId(uint32_t id) { return new SPIRVOperand(NUMBERID, id); }
SPIRVOperand *MkString(StringRef str) {
  return new SPIRVOperand(LITERAL_STRING, str);
}

struct SPIRVInstruction {
  // Create an instruction with an opcode and no result ID, and with the given
  // operands.  This computes its own word count.
  explicit SPIRVInstruction(spv::Op Opc, ArrayRef<SPIRVOperand *> Ops)
      : WordCount(1), Opcode(static_cast<uint16_t>(Opc)), ResultID(0),
        Operands(Ops.begin(), Ops.end()) {
    for (auto *operand : Ops) {
      WordCount += uint16_t(operand->GetNumWords());
    }
  }
  // Create an instruction with an opcode and a no-zero result ID, and
  // with the given operands.  This computes its own word count.
  explicit SPIRVInstruction(spv::Op Opc, uint32_t ResID,
                            ArrayRef<SPIRVOperand *> Ops)
      : WordCount(2), Opcode(static_cast<uint16_t>(Opc)), ResultID(ResID),
        Operands(Ops.begin(), Ops.end()) {
    if (ResID == 0) {
      llvm_unreachable("Result ID of 0 was provided");
    }
    for (auto *operand : Ops) {
      WordCount += operand->GetNumWords();
    }
  }

  uint32_t getWordCount() const { return WordCount; }
  uint16_t getOpcode() const { return Opcode; }
  uint32_t getResultID() const { return ResultID; }
  ArrayRef<SPIRVOperand *> getOperands() const { return Operands; }

private:
  uint32_t WordCount; // Check the 16-bit bound at code generation time.
  uint16_t Opcode;
  uint32_t ResultID;
  SmallVector<SPIRVOperand *, 4> Operands;
};

struct SPIRVProducerPass final : public ModulePass {
  typedef DenseMap<Type *, uint32_t> TypeMapType;
  typedef UniqueVector<Type *> TypeList;
  typedef DenseMap<Value *, uint32_t> ValueMapType;
  typedef UniqueVector<Value *> ValueList;
  typedef std::vector<std::pair<Value *, uint32_t>> EntryPointVecType;
  typedef std::list<SPIRVInstruction *> SPIRVInstructionList;
  // A vector of tuples, each of which is:
  // - the LLVM instruction that we will later generate SPIR-V code for
  // - where the SPIR-V instruction should be inserted
  // - the result ID of the SPIR-V instruction
  typedef std::vector<
      std::tuple<Value *, SPIRVInstructionList::iterator, uint32_t>>
      DeferredInstVecType;
  typedef DenseMap<FunctionType *, std::pair<FunctionType *, uint32_t>>
      GlobalConstFuncMapType;

  explicit SPIRVProducerPass(
      raw_pwrite_stream &out,
      std::vector<clspv::version0::DescriptorMapEntry> *descriptor_map_entries,
      ArrayRef<std::pair<unsigned, std::string>> samplerMap,
      bool outputCInitList)
      : ModulePass(ID), samplerMap(samplerMap), out(out),
        binaryTempOut(binaryTempUnderlyingVector), binaryOut(&out),
        descriptorMapEntries(descriptor_map_entries),
        outputCInitList(outputCInitList), patchBoundOffset(0), nextID(1),
        OpExtInstImportID(0), HasVariablePointersStorageBuffer(false),
        HasVariablePointers(false), SamplerTy(nullptr), WorkgroupSizeValueID(0),
        WorkgroupSizeVarID(0), max_local_spec_id_(0), constant_i32_zero_id_(0) {
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
  }

  virtual bool runOnModule(Module &module) override;

  // output the SPIR-V header block
  void outputHeader();

  // patch the SPIR-V header block
  void patchHeader();

  uint32_t lookupType(Type *Ty) {
    if (Ty->isPointerTy() &&
        (Ty->getPointerAddressSpace() != AddressSpace::UniformConstant)) {
      auto PointeeTy = Ty->getPointerElementType();
      if (PointeeTy->isStructTy() &&
          dyn_cast<StructType>(PointeeTy)->isOpaque()) {
        Ty = PointeeTy;
      }
    }

    auto where = TypeMap.find(Ty);
    if (where == TypeMap.end()) {
      if (Ty) {
        errs() << "Unhandled type " << *Ty << "\n";
      } else {
        errs() << "Unhandled type (null)\n";
      }
      llvm_unreachable("\nUnhandled type!");
    }

    return where->second;
  }
  TypeMapType &getImageTypeMap() { return ImageTypeMap; }
  TypeList &getTypeList() { return Types; };
  ValueList &getConstantList() { return Constants; };
  ValueMapType &getValueMap() { return ValueMap; }
  ValueMapType &getAllocatedValueMap() { return AllocatedValueMap; }
  SPIRVInstructionList &getSPIRVInstList() { return SPIRVInsts; };
  EntryPointVecType &getEntryPointVec() { return EntryPointVec; };
  DeferredInstVecType &getDeferredInstVec() { return DeferredInstVec; };
  ValueList &getEntryPointInterfacesVec() { return EntryPointInterfacesVec; };
  uint32_t &getOpExtInstImportID() { return OpExtInstImportID; };
  std::vector<uint32_t> &getBuiltinDimVec() { return BuiltinDimensionVec; };
  bool hasVariablePointersStorageBuffer() {
    return HasVariablePointersStorageBuffer;
  }
  void setVariablePointersStorageBuffer(bool Val) {
    HasVariablePointersStorageBuffer = Val;
  }
  bool hasVariablePointers() { return HasVariablePointers; };
  void setVariablePointers(bool Val) { HasVariablePointers = Val; };
  ArrayRef<std::pair<unsigned, std::string>> &getSamplerMap() {
    return samplerMap;
  }
  GlobalConstFuncMapType &getGlobalConstFuncTypeMap() {
    return GlobalConstFuncTypeMap;
  }
  SmallPtrSet<Value *, 16> &getGlobalConstArgSet() {
    return GlobalConstArgumentSet;
  }
  TypeList &getTypesNeedingArrayStride() { return TypesNeedingArrayStride; }

  void GenerateLLVMIRInfo(Module &M, const DataLayout &DL);
  // Populate GlobalConstFuncTypeMap. Also, if module-scope __constant will
  // *not* be converted to a storage buffer, replace each such global variable
  // with one in the storage class expecgted by SPIR-V.
  void FindGlobalConstVars(Module &M, const DataLayout &DL);
  // Populate ResourceVarInfoList, FunctionToResourceVarsMap, and
  // ModuleOrderedResourceVars.
  void FindResourceVars(Module &M, const DataLayout &DL);
  void FindWorkgroupVars(Module &M);
  bool FindExtInst(Module &M);
  void FindTypePerGlobalVar(GlobalVariable &GV);
  void FindTypePerFunc(Function &F);
  void FindTypesForSamplerMap(Module &M);
  void FindTypesForResourceVars(Module &M);
  // Inserts |Ty| and relevant sub-types into the |Types| member, indicating
  // that |Ty| and its subtypes will need a corresponding SPIR-V type.
  void FindType(Type *Ty);
  void FindConstantPerGlobalVar(GlobalVariable &GV);
  void FindConstantPerFunc(Function &F);
  void FindConstant(Value *V);
  void GenerateExtInstImport();
  // Generates instructions for SPIR-V types corresponding to the LLVM types
  // saved in the |Types| member.  A type follows its subtypes.  IDs are
  // allocated sequentially starting with the current value of nextID, and
  // with a type following its subtypes.  Also updates nextID to just beyond
  // the last generated ID.
  void GenerateSPIRVTypes(LLVMContext &context, Module &module);
  void GenerateSPIRVConstants();
  void GenerateModuleInfo(Module &M);
  void GenerateGlobalVar(GlobalVariable &GV);
  void GenerateWorkgroupVars();
  // Generate descriptor map entries for resource variables associated with
  // arguments to F.
  void GenerateDescriptorMapInfo(const DataLayout &DL, Function &F);
  void GenerateSamplers(Module &M);
  // Generate OpVariables for %clspv.resource.var.* calls.
  void GenerateResourceVars(Module &M);
  void GenerateFuncPrologue(Function &F);
  void GenerateFuncBody(Function &F);
  void GenerateEntryPointInitialStores();
  spv::Op GetSPIRVCmpOpcode(CmpInst *CmpI);
  spv::Op GetSPIRVCastOpcode(Instruction &I);
  spv::Op GetSPIRVBinaryOpcode(Instruction &I);
  void GenerateInstruction(Instruction &I);
  void GenerateFuncEpilogue();
  void HandleDeferredInstruction();
  void HandleDeferredDecorations(const DataLayout &DL);
  bool is4xi8vec(Type *Ty) const;
  // Return the SPIR-V Id for 32-bit constant zero.  The constant must already
  // have been created.
  uint32_t GetI32Zero();
  spv::StorageClass GetStorageClass(unsigned AddrSpace) const;
  spv::StorageClass GetStorageClassForArgKind(clspv::ArgKind arg_kind) const;
  spv::BuiltIn GetBuiltin(StringRef globalVarName) const;
  // Returns the GLSL extended instruction enum that the given function
  // call maps to.  If none, then returns the 0 value, i.e. GLSLstd4580Bad.
  glsl::ExtInst getExtInstEnum(StringRef Name);
  // Returns the GLSL extended instruction enum indirectly used by the given
  // function.  That is, to implement the given function, we use an extended
  // instruction plus one more instruction. If none, then returns the 0 value,
  // i.e. GLSLstd4580Bad.
  glsl::ExtInst getIndirectExtInstEnum(StringRef Name);
  // Returns the single GLSL extended instruction used directly or
  // indirectly by the given function call.
  glsl::ExtInst getDirectOrIndirectExtInstEnum(StringRef Name);
  void WriteOneWord(uint32_t Word);
  void WriteResultID(SPIRVInstruction *Inst);
  void WriteWordCountAndOpcode(SPIRVInstruction *Inst);
  void WriteOperand(SPIRVOperand *Op);
  void WriteSPIRVBinary();

  // Returns true if |type| is compatible with OpConstantNull.
  bool IsTypeNullable(const Type *type) const;

  // Populate UBO remapped type maps.
  void PopulateUBOTypeMaps(Module &module);

  // Wrapped methods of DataLayout accessors. If |type| was remapped for UBOs,
  // uses the internal map, otherwise it falls back on the data layout.
  uint64_t GetTypeSizeInBits(Type *type, const DataLayout &DL);
  uint64_t GetTypeStoreSize(Type *type, const DataLayout &DL);
  uint64_t GetTypeAllocSize(Type *type, const DataLayout &DL);

  // Returns the base pointer of |v|.
  Value *GetBasePointer(Value *v);

  // Sets |HasVariablePointersStorageBuffer| or |HasVariablePointers| base on
  // |address_space|.
  void setVariablePointersCapabilities(unsigned address_space);

  // Returns true if |lhs| and |rhs| represent the same resource or workgroup
  // variable.
  bool sameResource(Value *lhs, Value *rhs) const;

  // Returns true if |inst| is phi or select that selects from the same
  // structure (or null).
  bool selectFromSameObject(Instruction *inst);

  // Returns true if |Arg| is called with a coherent resource.
  bool CalledWithCoherentResource(Argument &Arg);

private:
  static char ID;
  ArrayRef<std::pair<unsigned, std::string>> samplerMap;
  raw_pwrite_stream &out;

  // TODO(dneto): Wouldn't it be better to always just emit a binary, and then
  // convert to other formats on demand?

  // When emitting a C initialization list, the WriteSPIRVBinary method
  // will actually write its words to this vector via binaryTempOut.
  SmallVector<char, 100> binaryTempUnderlyingVector;
  raw_svector_ostream binaryTempOut;

  // Binary output writes to this stream, which might be |out| or
  // |binaryTempOut|.  It's the latter when we really want to write a C
  // initializer list.
  raw_pwrite_stream *binaryOut;
  std::vector<version0::DescriptorMapEntry> *descriptorMapEntries;
  const bool outputCInitList; // If true, output look like {0x7023, ... , 5}
  uint64_t patchBoundOffset;
  uint32_t nextID;

  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  TypeMapType TypeMap;
  // Maps an LLVM image type to its SPIR-V ID.
  TypeMapType ImageTypeMap;
  // A unique-vector of LLVM types that map to a SPIR-V type.
  TypeList Types;
  ValueList Constants;
  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  ValueMapType ValueMap;
  ValueMapType AllocatedValueMap;
  SPIRVInstructionList SPIRVInsts;

  EntryPointVecType EntryPointVec;
  DeferredInstVecType DeferredInstVec;
  ValueList EntryPointInterfacesVec;
  uint32_t OpExtInstImportID;
  std::vector<uint32_t> BuiltinDimensionVec;
  bool HasVariablePointersStorageBuffer;
  bool HasVariablePointers;
  Type *SamplerTy;
  DenseMap<unsigned, uint32_t> SamplerMapIndexToIDMap;

  // If a function F has a pointer-to-__constant parameter, then this variable
  // will map F's type to (G, index of the parameter), where in a first phase
  // G is F's type.  During FindTypePerFunc, G will be changed to F's type
  // but replacing the pointer-to-constant parameter with
  // pointer-to-ModuleScopePrivate.
  // TODO(dneto): This doesn't seem general enough?  A function might have
  // more than one such parameter.
  GlobalConstFuncMapType GlobalConstFuncTypeMap;
  SmallPtrSet<Value *, 16> GlobalConstArgumentSet;
  // An ordered set of pointer types of Base arguments to OpPtrAccessChain,
  // or array types, and which point into transparent memory (StorageBuffer
  // storage class).  These will require an ArrayStride decoration.
  // See SPV_KHR_variable_pointers rev 13.
  TypeList TypesNeedingArrayStride;

  // This is truly ugly, but works around what look like driver bugs.
  // For get_local_size, an earlier part of the flow has created a module-scope
  // variable in Private address space to hold the value for the workgroup
  // size.  Its intializer is a uint3 value marked as builtin WorkgroupSize.
  // When this is present, save the IDs of the initializer value and variable
  // in these two variables.  We only ever do a vector load from it, and
  // when we see one of those, substitute just the value of the intializer.
  // This mimics what Glslang does, and that's what drivers are used to.
  // TODO(dneto): Remove this once drivers are fixed.
  uint32_t WorkgroupSizeValueID;
  uint32_t WorkgroupSizeVarID;

  // Bookkeeping for mapping kernel arguments to resource variables.
  struct ResourceVarInfo {
    ResourceVarInfo(int index_arg, unsigned set_arg, unsigned binding_arg,
                    Function *fn, clspv::ArgKind arg_kind_arg, int coherent_arg)
        : index(index_arg), descriptor_set(set_arg), binding(binding_arg),
          var_fn(fn), arg_kind(arg_kind_arg), coherent(coherent_arg),
          addr_space(fn->getReturnType()->getPointerAddressSpace()) {}
    const int index; // Index into ResourceVarInfoList
    const unsigned descriptor_set;
    const unsigned binding;
    Function *const var_fn; // The @clspv.resource.var.* function.
    const clspv::ArgKind arg_kind;
    const int coherent;
    const unsigned addr_space; // The LLVM address space
    // The SPIR-V ID of the OpVariable.  Not populated at construction time.
    uint32_t var_id = 0;
  };
  // A list of resource var info.  Each one correponds to a module-scope
  // resource variable we will have to create.  Resource var indices are
  // indices into this vector.
  SmallVector<std::unique_ptr<ResourceVarInfo>, 8> ResourceVarInfoList;
  // This is a vector of pointers of all the resource vars, but ordered by
  // kernel function, and then by argument.
  UniqueVector<ResourceVarInfo *> ModuleOrderedResourceVars;
  // Map a function to the ordered list of resource variables it uses, one for
  // each argument.  If an argument does not use a resource variable, it
  // will have a null pointer entry.
  using FunctionToResourceVarsMapType =
      DenseMap<Function *, SmallVector<ResourceVarInfo *, 8>>;
  FunctionToResourceVarsMapType FunctionToResourceVarsMap;

  // What LLVM types map to SPIR-V types needing layout?  These are the
  // arrays and structures supporting storage buffers and uniform buffers.
  TypeList TypesNeedingLayout;
  // What LLVM struct types map to a SPIR-V struct type with Block decoration?
  UniqueVector<StructType *> StructTypesNeedingBlock;
  // For a call that represents a load from an opaque type (samplers, images),
  // map it to the variable id it should load from.
  DenseMap<CallInst *, uint32_t> ResourceVarDeferredLoadCalls;

  // One larger than the maximum used SpecId for pointer-to-local arguments.
  int max_local_spec_id_;
  // An ordered list of the kernel arguments of type pointer-to-local.
  using LocalArgList = SmallVector<Argument *, 8>;
  LocalArgList LocalArgs;
  // Information about a pointer-to-local argument.
  struct LocalArgInfo {
    // The SPIR-V ID of the array variable.
    uint32_t variable_id;
    // The element type of the
    Type *elem_type;
    // The ID of the array type.
    uint32_t array_size_id;
    // The ID of the array type.
    uint32_t array_type_id;
    // The ID of the pointer to the array type.
    uint32_t ptr_array_type_id;
    // The specialization constant ID of the array size.
    int spec_id;
  };
  // A mapping from Argument to its assigned SpecId.
  DenseMap<const Argument *, int> LocalArgSpecIds;
  // A mapping from SpecId to its LocalArgInfo.
  DenseMap<int, LocalArgInfo> LocalSpecIdInfoMap;
  // A mapping from a remapped type to its real offsets.
  DenseMap<Type *, std::vector<uint32_t>> RemappedUBOTypeOffsets;
  // A mapping from a remapped type to its real sizes.
  DenseMap<Type *, std::tuple<uint64_t, uint64_t, uint64_t>>
      RemappedUBOTypeSizes;

  // The ID of 32-bit integer zero constant.  This is only valid after
  // GenerateSPIRVConstants has run.
  uint32_t constant_i32_zero_id_;
};

char SPIRVProducerPass::ID;

} // namespace

namespace clspv {
ModulePass *createSPIRVProducerPass(
    raw_pwrite_stream &out,
    std::vector<version0::DescriptorMapEntry> *descriptor_map_entries,
    ArrayRef<std::pair<unsigned, std::string>> samplerMap,
    bool outputCInitList) {
  return new SPIRVProducerPass(out, descriptor_map_entries, samplerMap,
                               outputCInitList);
}
} // namespace clspv

bool SPIRVProducerPass::runOnModule(Module &module) {
  binaryOut = outputCInitList ? &binaryTempOut : &out;

  constant_i32_zero_id_ = 0; // Reset, for the benefit of validity checks.

  PopulateUBOTypeMaps(module);

  // SPIR-V always begins with its header information
  outputHeader();

  const DataLayout &DL = module.getDataLayout();

  // Gather information from the LLVM IR that we require.
  GenerateLLVMIRInfo(module, DL);

  // Collect information on global variables too.
  for (GlobalVariable &GV : module.globals()) {
    // If the GV is one of our special __spirv_* variables, remove the
    // initializer as it was only placed there to force LLVM to not throw the
    // value away.
    if (GV.getName().startswith("__spirv_")) {
      GV.setInitializer(nullptr);
    }

    // Collect types' information from global variable.
    FindTypePerGlobalVar(GV);

    // Collect constant information from global variable.
    FindConstantPerGlobalVar(GV);

    // If the variable is an input, entry points need to know about it.
    if (AddressSpace::Input == GV.getType()->getPointerAddressSpace()) {
      getEntryPointInterfacesVec().insert(&GV);
    }
  }

  // If there are extended instructions, generate OpExtInstImport.
  if (FindExtInst(module)) {
    GenerateExtInstImport();
  }

  // Generate SPIRV instructions for types.
  GenerateSPIRVTypes(module.getContext(), module);

  // Generate SPIRV constants.
  GenerateSPIRVConstants();

  // If we have a sampler map, we might have literal samplers to generate.
  if (0 < getSamplerMap().size()) {
    GenerateSamplers(module);
  }

  // Generate SPIRV variables.
  for (GlobalVariable &GV : module.globals()) {
    GenerateGlobalVar(GV);
  }
  GenerateResourceVars(module);
  GenerateWorkgroupVars();

  // Generate SPIRV instructions for each function.
  for (Function &F : module) {
    if (F.isDeclaration()) {
      continue;
    }

    GenerateDescriptorMapInfo(DL, F);

    // Generate Function Prologue.
    GenerateFuncPrologue(F);

    // Generate SPIRV instructions for function body.
    GenerateFuncBody(F);

    // Generate Function Epilogue.
    GenerateFuncEpilogue();
  }

  HandleDeferredInstruction();
  HandleDeferredDecorations(DL);

  // Generate SPIRV module information.
  GenerateModuleInfo(module);

  WriteSPIRVBinary();

  // We need to patch the SPIR-V header to set bound correctly.
  patchHeader();

  if (outputCInitList) {
    bool first = true;
    std::ostringstream os;

    auto emit_word = [&os, &first](uint32_t word) {
      if (!first)
        os << ",\n";
      os << word;
      first = false;
    };

    os << "{";
    const std::string str(binaryTempOut.str());
    for (unsigned i = 0; i < str.size(); i += 4) {
      const uint32_t a = static_cast<unsigned char>(str[i]);
      const uint32_t b = static_cast<unsigned char>(str[i + 1]);
      const uint32_t c = static_cast<unsigned char>(str[i + 2]);
      const uint32_t d = static_cast<unsigned char>(str[i + 3]);
      emit_word(a | (b << 8) | (c << 16) | (d << 24));
    }
    os << "}\n";
    out << os.str();
  }

  return false;
}

void SPIRVProducerPass::outputHeader() {
  binaryOut->write(reinterpret_cast<const char *>(&spv::MagicNumber),
                   sizeof(spv::MagicNumber));
  binaryOut->write(reinterpret_cast<const char *>(&spv::Version),
                   sizeof(spv::Version));

  // use Google's vendor ID
  const uint32_t vendor = 21 << 16;
  binaryOut->write(reinterpret_cast<const char *>(&vendor), sizeof(vendor));

  // we record where we need to come back to and patch in the bound value
  patchBoundOffset = binaryOut->tell();

  // output a bad bound for now
  binaryOut->write(reinterpret_cast<const char *>(&nextID), sizeof(nextID));

  // output the schema (reserved for use and must be 0)
  const uint32_t schema = 0;
  binaryOut->write(reinterpret_cast<const char *>(&schema), sizeof(schema));
}

void SPIRVProducerPass::patchHeader() {
  // for a binary we just write the value of nextID over bound
  binaryOut->pwrite(reinterpret_cast<char *>(&nextID), sizeof(nextID),
                    patchBoundOffset);
}

void SPIRVProducerPass::GenerateLLVMIRInfo(Module &M, const DataLayout &DL) {
  // This function generates LLVM IR for function such as global variable for
  // argument, constant and pointer type for argument access. These information
  // is artificial one because we need Vulkan SPIR-V output. This function is
  // executed ahead of FindType and FindConstant.
  LLVMContext &Context = M.getContext();

  FindGlobalConstVars(M, DL);

  FindResourceVars(M, DL);

  bool HasWorkGroupBuiltin = false;
  for (GlobalVariable &GV : M.globals()) {
    const spv::BuiltIn BuiltinType = GetBuiltin(GV.getName());
    if (spv::BuiltInWorkgroupSize == BuiltinType) {
      HasWorkGroupBuiltin = true;
    }
  }

  FindTypesForSamplerMap(M);
  FindTypesForResourceVars(M);
  FindWorkgroupVars(M);

  // These function calls need a <2 x i32> as an intermediate result but not
  // the final result.
  std::unordered_set<std::string> NeedsIVec2{
      "_Z15get_image_width14ocl_image2d_ro",
      "_Z15get_image_width14ocl_image2d_wo",
      "_Z16get_image_height14ocl_image2d_ro",
      "_Z16get_image_height14ocl_image2d_wo",
  };

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (I.getOpcode() == Instruction::ZExt ||
            I.getOpcode() == Instruction::SExt ||
            I.getOpcode() == Instruction::UIToFP) {
          // If there is zext with i1 type, it will be changed to OpSelect. The
          // OpSelect needs constant 0 and 1 so the constants are added here.

          auto OpTy = I.getOperand(0)->getType();

          if (OpTy->isIntOrIntVectorTy(1)) {
            if (I.getOpcode() == Instruction::ZExt) {
              FindConstant(Constant::getNullValue(I.getType()));
              FindConstant(ConstantInt::get(I.getType(), 1));
            } else if (I.getOpcode() == Instruction::SExt) {
              FindConstant(Constant::getNullValue(I.getType()));
              FindConstant(ConstantInt::getSigned(I.getType(), -1));
            } else {
              FindConstant(ConstantFP::get(Context, APFloat(0.0f)));
              FindConstant(ConstantFP::get(Context, APFloat(1.0f)));
            }
          }
        } else if (CallInst *Call = dyn_cast<CallInst>(&I)) {
          StringRef callee_name = Call->getCalledFunction()->getName();

          // Handle image type specially.
          if (callee_name.equals(
                  "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f") ||
              callee_name.equals(
                  "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f")) {
            TypeMapType &OpImageTypeMap = getImageTypeMap();
            Type *ImageTy =
                Call->getArgOperand(0)->getType()->getPointerElementType();
            OpImageTypeMap[ImageTy] = 0;

            FindConstant(ConstantFP::get(Context, APFloat(0.0f)));
          }

          if (NeedsIVec2.find(callee_name) != NeedsIVec2.end()) {
            FindType(VectorType::get(Type::getInt32Ty(Context), 2));
          }
        }
      }
    }

    // More things to do on kernel functions
    if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
      if (const MDNode *MD =
              dyn_cast<Function>(&F)->getMetadata("reqd_work_group_size")) {
        // We generate constants if the WorkgroupSize builtin is being used.
        if (HasWorkGroupBuiltin) {
          // Collect constant information for work group size.
          FindConstant(mdconst::extract<ConstantInt>(MD->getOperand(0)));
          FindConstant(mdconst::extract<ConstantInt>(MD->getOperand(1)));
          FindConstant(mdconst::extract<ConstantInt>(MD->getOperand(2)));
        }
      }
    }

    if (M.getTypeByName("opencl.image2d_ro_t") ||
        M.getTypeByName("opencl.image2d_wo_t") ||
        M.getTypeByName("opencl.image3d_ro_t") ||
        M.getTypeByName("opencl.image3d_wo_t")) {
      // Assume Image type's sampled type is float type.
      FindType(Type::getFloatTy(Context));
    }

    // Collect types' information from function.
    FindTypePerFunc(F);

    // Collect constant information from function.
    FindConstantPerFunc(F);
  }
}

void SPIRVProducerPass::FindGlobalConstVars(Module &M, const DataLayout &DL) {
  clspv::NormalizeGlobalVariables(M);

  SmallVector<GlobalVariable *, 8> GVList;
  SmallVector<GlobalVariable *, 8> DeadGVList;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getType()->getAddressSpace() == AddressSpace::Constant) {
      if (GV.use_empty()) {
        DeadGVList.push_back(&GV);
      } else {
        GVList.push_back(&GV);
      }
    }
  }

  // Remove dead global __constant variables.
  for (auto GV : DeadGVList) {
    GV->eraseFromParent();
  }
  DeadGVList.clear();

  if (clspv::Option::ModuleConstantsInStorageBuffer()) {
    // For now, we only support a single storage buffer.
    if (GVList.size() > 0) {
      assert(GVList.size() == 1);
      const auto *GV = GVList[0];
      const auto constants_byte_size =
          (GetTypeSizeInBits(GV->getInitializer()->getType(), DL)) / 8;
      const size_t kConstantMaxSize = 65536;
      if (constants_byte_size > kConstantMaxSize) {
        outs() << "Max __constant capacity of " << kConstantMaxSize
               << " bytes exceeded: " << constants_byte_size << " bytes used\n";
        llvm_unreachable("Max __constant capacity exceeded");
      }
    }
  } else {
    // Change global constant variable's address space to ModuleScopePrivate.
    auto &GlobalConstFuncTyMap = getGlobalConstFuncTypeMap();
    for (auto GV : GVList) {
      // Create new gv with ModuleScopePrivate address space.
      Type *NewGVTy = GV->getType()->getPointerElementType();
      GlobalVariable *NewGV = new GlobalVariable(
          M, NewGVTy, false, GV->getLinkage(), GV->getInitializer(), "",
          nullptr, GV->getThreadLocalMode(), AddressSpace::ModuleScopePrivate);
      NewGV->takeName(GV);

      const SmallVector<User *, 8> GVUsers(GV->user_begin(), GV->user_end());
      SmallVector<User *, 8> CandidateUsers;

      auto record_called_function_type_as_user =
          [&GlobalConstFuncTyMap](Value *gv, CallInst *call) {
            // Find argument index.
            unsigned index = 0;
            for (unsigned i = 0; i < call->getNumArgOperands(); i++) {
              if (gv == call->getOperand(i)) {
                // TODO(dneto): Should we break here?
                index = i;
              }
            }

            // Record function type with global constant.
            GlobalConstFuncTyMap[call->getFunctionType()] =
                std::make_pair(call->getFunctionType(), index);
          };

      for (User *GVU : GVUsers) {
        if (CallInst *Call = dyn_cast<CallInst>(GVU)) {
          record_called_function_type_as_user(GV, Call);
        } else if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(GVU)) {
          // Check GEP users.
          for (User *GEPU : GEP->users()) {
            if (CallInst *GEPCall = dyn_cast<CallInst>(GEPU)) {
              record_called_function_type_as_user(GEP, GEPCall);
            }
          }
        }

        CandidateUsers.push_back(GVU);
      }

      for (User *U : CandidateUsers) {
        // Update users of gv with new gv.
        if (!isa<Constant>(U)) {
          // #254: Can't change operands of a constant, but this shouldn't be
          // something that sticks around in the module.
          U->replaceUsesOfWith(GV, NewGV);
        }
      }

      // Delete original gv.
      GV->eraseFromParent();
    }
  }
}

void SPIRVProducerPass::FindResourceVars(Module &M, const DataLayout &) {
  ResourceVarInfoList.clear();
  FunctionToResourceVarsMap.clear();
  ModuleOrderedResourceVars.reset();
  // Normally, there is one resource variable per clspv.resource.var.*
  // function, since that is unique'd by arg type and index.  By design,
  // we can share these resource variables across kernels because all
  // kernels use the same descriptor set.
  //
  // But if the user requested distinct descriptor sets per kernel, then
  // the descriptor allocator has made different (set,binding) pairs for
  // the same (type,arg_index) pair.  Since we can decorate a resource
  // variable with only exactly one DescriptorSet and Binding, we are
  // forced in this case to make distinct resource variables whenever
  // the same clspv.reource.var.X function is seen with disintct
  // (set,binding) values.
  const bool always_distinct_sets =
      clspv::Option::DistinctKernelDescriptorSets();
  for (Function &F : M) {
    // Rely on the fact the resource var functions have a stable ordering
    // in the module.
    if (F.getName().startswith(clspv::ResourceAccessorFunction())) {
      // Find all calls to this function with distinct set and binding pairs.
      // Save them in ResourceVarInfoList.

      // Determine uniqueness of the (set,binding) pairs only withing this
      // one resource-var builtin function.
      using SetAndBinding = std::pair<unsigned, unsigned>;
      // Maps set and binding to the resource var info.
      DenseMap<SetAndBinding, ResourceVarInfo *> set_and_binding_map;
      bool first_use = true;
      for (auto &U : F.uses()) {
        if (auto *call = dyn_cast<CallInst>(U.getUser())) {
          const auto set = unsigned(
              dyn_cast<ConstantInt>(call->getArgOperand(0))->getZExtValue());
          const auto binding = unsigned(
              dyn_cast<ConstantInt>(call->getArgOperand(1))->getZExtValue());
          const auto arg_kind = clspv::ArgKind(
              dyn_cast<ConstantInt>(call->getArgOperand(2))->getZExtValue());
          const auto arg_index = unsigned(
              dyn_cast<ConstantInt>(call->getArgOperand(3))->getZExtValue());
          const auto coherent = unsigned(
              dyn_cast<ConstantInt>(call->getArgOperand(5))->getZExtValue());

          // Find or make the resource var info for this combination.
          ResourceVarInfo *rv = nullptr;
          if (always_distinct_sets) {
            // Make a new resource var any time we see a different
            // (set,binding) pair.
            SetAndBinding key{set, binding};
            auto where = set_and_binding_map.find(key);
            if (where == set_and_binding_map.end()) {
              rv = new ResourceVarInfo(int(ResourceVarInfoList.size()), set,
                                       binding, &F, arg_kind, coherent);
              ResourceVarInfoList.emplace_back(rv);
              set_and_binding_map[key] = rv;
            } else {
              rv = where->second;
            }
          } else {
            // The default is to make exactly one resource for each
            // clspv.resource.var.* function.
            if (first_use) {
              first_use = false;
              rv = new ResourceVarInfo(int(ResourceVarInfoList.size()), set,
                                       binding, &F, arg_kind, coherent);
              ResourceVarInfoList.emplace_back(rv);
            } else {
              rv = ResourceVarInfoList.back().get();
            }
          }

          // Now populate FunctionToResourceVarsMap.
          auto &mapping =
              FunctionToResourceVarsMap[call->getParent()->getParent()];
          while (mapping.size() <= arg_index) {
            mapping.push_back(nullptr);
          }
          mapping[arg_index] = rv;
        }
      }
    }
  }

  // Populate ModuleOrderedResourceVars.
  for (Function &F : M) {
    auto where = FunctionToResourceVarsMap.find(&F);
    if (where != FunctionToResourceVarsMap.end()) {
      for (auto &rv : where->second) {
        if (rv != nullptr) {
          ModuleOrderedResourceVars.insert(rv);
        }
      }
    }
  }
  if (ShowResourceVars) {
    for (auto *info : ModuleOrderedResourceVars) {
      outs() << "MORV index " << info->index << " (" << info->descriptor_set
             << "," << info->binding << ") " << *(info->var_fn->getReturnType())
             << "\n";
    }
  }
}

bool SPIRVProducerPass::FindExtInst(Module &M) {
  LLVMContext &Context = M.getContext();
  bool HasExtInst = false;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (CallInst *Call = dyn_cast<CallInst>(&I)) {
          Function *Callee = Call->getCalledFunction();
          // Check whether this call is for extend instructions.
          auto callee_name = Callee->getName();
          const glsl::ExtInst EInst = getExtInstEnum(callee_name);
          const glsl::ExtInst IndirectEInst =
              getIndirectExtInstEnum(callee_name);

          HasExtInst |=
              (EInst != kGlslExtInstBad) || (IndirectEInst != kGlslExtInstBad);

          if (IndirectEInst) {
            // Register extra constants if needed.

            // Registers a type and constant for computing the result of the
            // given instruction.  If the result of the instruction is a vector,
            // then make a splat vector constant with the same number of
            // elements.
            auto register_constant = [this, &I](Constant *constant) {
              FindType(constant->getType());
              FindConstant(constant);
              if (auto *vectorTy = dyn_cast<VectorType>(I.getType())) {
                // Register the splat vector of the value with the same
                // width as the result of the instruction.
                auto *vec_constant = ConstantVector::getSplat(
                    static_cast<unsigned>(vectorTy->getNumElements()),
                    constant);
                FindConstant(vec_constant);
                FindType(vec_constant->getType());
              }
            };
            switch (IndirectEInst) {
            case glsl::ExtInstFindUMsb:
              // clz needs OpExtInst and OpISub with constant 31, or splat
              // vector of 31.  Add it to the constant list here.
              register_constant(
                  ConstantInt::get(Type::getInt32Ty(Context), 31));
              break;
            case glsl::ExtInstAcos:
            case glsl::ExtInstAsin:
            case glsl::ExtInstAtan:
            case glsl::ExtInstAtan2:
              // We need 1/pi for acospi, asinpi, atan2pi.
              register_constant(
                  ConstantFP::get(Type::getFloatTy(Context), kOneOverPi));
              break;
            default:
              assert(false && "internally inconsistent");
            }
          }
        }
      }
    }
  }

  return HasExtInst;
}

void SPIRVProducerPass::FindTypePerGlobalVar(GlobalVariable &GV) {
  // Investigate global variable's type.
  FindType(GV.getType());
}

void SPIRVProducerPass::FindTypePerFunc(Function &F) {
  // Investigate function's type.
  FunctionType *FTy = F.getFunctionType();

  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
    auto &GlobalConstFuncTyMap = getGlobalConstFuncTypeMap();
    // Handle a regular function with global constant parameters.
    if (GlobalConstFuncTyMap.count(FTy)) {
      uint32_t GVCstArgIdx = GlobalConstFuncTypeMap[FTy].second;
      SmallVector<Type *, 4> NewFuncParamTys;
      for (unsigned i = 0; i < FTy->getNumParams(); i++) {
        Type *ParamTy = FTy->getParamType(i);
        if (i == GVCstArgIdx) {
          Type *EleTy = ParamTy->getPointerElementType();
          ParamTy = PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);
        }

        NewFuncParamTys.push_back(ParamTy);
      }

      FunctionType *NewFTy =
          FunctionType::get(FTy->getReturnType(), NewFuncParamTys, false);
      GlobalConstFuncTyMap[FTy] = std::make_pair(NewFTy, GVCstArgIdx);
      FTy = NewFTy;
    }

    FindType(FTy);
  } else {
    // As kernel functions do not have parameters, create new function type and
    // add it to type map.
    SmallVector<Type *, 4> NewFuncParamTys;
    FunctionType *NewFTy =
        FunctionType::get(FTy->getReturnType(), NewFuncParamTys, false);
    FindType(NewFTy);
  }

  // Investigate instructions' type in function body.
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (isa<ShuffleVectorInst>(I)) {
        for (unsigned i = 0; i < I.getNumOperands(); i++) {
          // Ignore type for mask of shuffle vector instruction.
          if (i == 2) {
            continue;
          }

          Value *Op = I.getOperand(i);
          if (!isa<MetadataAsValue>(Op)) {
            FindType(Op->getType());
          }
        }

        FindType(I.getType());
        continue;
      }

      CallInst *Call = dyn_cast<CallInst>(&I);

      if (Call && Call->getCalledFunction()->getName().startswith(
                      clspv::ResourceAccessorFunction())) {
        // This is a fake call representing access to a resource variable.
        // We handle that elsewhere.
        continue;
      }

      if (Call && Call->getCalledFunction()->getName().startswith(
                      clspv::WorkgroupAccessorFunction())) {
        // This is a fake call representing access to a workgroup variable.
        // We handle that elsewhere.
        continue;
      }

      // Work through the operands of the instruction.
      for (unsigned i = 0; i < I.getNumOperands(); i++) {
        Value *const Op = I.getOperand(i);
        // If any of the operands is a constant, find the type!
        if (isa<Constant>(Op) && !isa<GlobalValue>(Op)) {
          FindType(Op->getType());
        }
      }

      for (Use &Op : I.operands()) {
        if (isa<CallInst>(&I)) {
          // Avoid to check call instruction's type.
          break;
        }
        if (CallInst *OpCall = dyn_cast<CallInst>(Op)) {
          if (OpCall && OpCall->getCalledFunction()->getName().startswith(
                            clspv::WorkgroupAccessorFunction())) {
            // This is a fake call representing access to a workgroup variable.
            // We handle that elsewhere.
            continue;
          }
        }
        if (!isa<MetadataAsValue>(&Op)) {
          FindType(Op->getType());
          continue;
        }
      }

      // We don't want to track the type of this call as we are going to replace
      // it.
      if (Call && (clspv::LiteralSamplerFunction() ==
                   Call->getCalledFunction()->getName())) {
        continue;
      }

      if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        // If gep's base operand has ModuleScopePrivate address space, make gep
        // return ModuleScopePrivate address space.
        if (GEP->getPointerAddressSpace() == AddressSpace::ModuleScopePrivate) {
          // Add pointer type with private address space for global constant to
          // type list.
          Type *EleTy = I.getType()->getPointerElementType();
          Type *NewPTy =
              PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);

          FindType(NewPTy);
          continue;
        }
      }

      FindType(I.getType());
    }
  }
}

void SPIRVProducerPass::FindTypesForSamplerMap(Module &M) {
  // If we are using a sampler map, find the type of the sampler.
  if (M.getFunction(clspv::LiteralSamplerFunction()) ||
      0 < getSamplerMap().size()) {
    auto SamplerStructTy = M.getTypeByName("opencl.sampler_t");
    if (!SamplerStructTy) {
      SamplerStructTy = StructType::create(M.getContext(), "opencl.sampler_t");
    }

    SamplerTy = SamplerStructTy->getPointerTo(AddressSpace::UniformConstant);

    FindType(SamplerTy);
  }
}

void SPIRVProducerPass::FindTypesForResourceVars(Module &M) {
  // Record types so they are generated.
  TypesNeedingLayout.reset();
  StructTypesNeedingBlock.reset();

  // To match older clspv codegen, generate the float type first if required
  // for images.
  for (const auto *info : ModuleOrderedResourceVars) {
    if (info->arg_kind == clspv::ArgKind::ReadOnlyImage ||
        info->arg_kind == clspv::ArgKind::WriteOnlyImage) {
      // We need "float" for the sampled component type.
      FindType(Type::getFloatTy(M.getContext()));
      // We only need to find it once.
      break;
    }
  }

  for (const auto *info : ModuleOrderedResourceVars) {
    Type *type = info->var_fn->getReturnType();

    switch (info->arg_kind) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::BufferUBO:
      if (auto *sty = dyn_cast<StructType>(type->getPointerElementType())) {
        StructTypesNeedingBlock.insert(sty);
      } else {
        errs() << *type << "\n";
        llvm_unreachable("Buffer arguments must map to structures!");
      }
      break;
    case clspv::ArgKind::Pod:
      if (auto *sty = dyn_cast<StructType>(type->getPointerElementType())) {
        StructTypesNeedingBlock.insert(sty);
      } else {
        errs() << *type << "\n";
        llvm_unreachable("POD arguments must map to structures!");
      }
      break;
    case clspv::ArgKind::ReadOnlyImage:
    case clspv::ArgKind::WriteOnlyImage:
    case clspv::ArgKind::Sampler:
      // Sampler and image types map to the pointee type but
      // in the uniform constant address space.
      type = PointerType::get(type->getPointerElementType(),
                              clspv::AddressSpace::UniformConstant);
      break;
    default:
      break;
    }

    // The converted type is the type of the OpVariable we will generate.
    // If the pointee type is an array of size zero, FindType will convert it
    // to a runtime array.
    FindType(type);
  }

  // Traverse the arrays and structures underneath each Block, and
  // mark them as needing layout.
  std::vector<Type *> work_list(StructTypesNeedingBlock.begin(),
                                StructTypesNeedingBlock.end());
  while (!work_list.empty()) {
    Type *type = work_list.back();
    work_list.pop_back();
    TypesNeedingLayout.insert(type);
    switch (type->getTypeID()) {
    case Type::ArrayTyID:
      work_list.push_back(type->getArrayElementType());
      if (!Hack_generate_runtime_array_stride_early) {
        // Remember this array type for deferred decoration.
        TypesNeedingArrayStride.insert(type);
      }
      break;
    case Type::StructTyID:
      for (auto *elem_ty : cast<StructType>(type)->elements()) {
        work_list.push_back(elem_ty);
      }
    default:
      // This type and its contained types don't get layout.
      break;
    }
  }
}

void SPIRVProducerPass::FindWorkgroupVars(Module &M) {
  // The SpecId assignment for pointer-to-local arguments is recorded in
  // module-level metadata. Translate that information into local argument
  // information.
  NamedMDNode *nmd = M.getNamedMetadata(clspv::LocalSpecIdMetadataName());
  if (!nmd)
    return;
  for (auto operand : nmd->operands()) {
    MDTuple *tuple = cast<MDTuple>(operand);
    ValueAsMetadata *fn_md = cast<ValueAsMetadata>(tuple->getOperand(0));
    Function *func = cast<Function>(fn_md->getValue());
    ConstantAsMetadata *arg_index_md =
        cast<ConstantAsMetadata>(tuple->getOperand(1));
    int arg_index = static_cast<int>(
        cast<ConstantInt>(arg_index_md->getValue())->getSExtValue());
    Argument *arg = &*(func->arg_begin() + arg_index);

    ConstantAsMetadata *spec_id_md =
        cast<ConstantAsMetadata>(tuple->getOperand(2));
    int spec_id = static_cast<int>(
        cast<ConstantInt>(spec_id_md->getValue())->getSExtValue());

    max_local_spec_id_ = std::max(max_local_spec_id_, spec_id + 1);
    LocalArgSpecIds[arg] = spec_id;
    if (LocalSpecIdInfoMap.count(spec_id))
      continue;

    // We haven't seen this SpecId yet, so generate the LocalArgInfo for it.
    LocalArgInfo info{nextID,     arg->getType()->getPointerElementType(),
                      nextID + 1, nextID + 2,
                      nextID + 3, spec_id};
    LocalSpecIdInfoMap[spec_id] = info;
    nextID += 4;

    // Ensure the types necessary for this argument get generated.
    Type *IdxTy = Type::getInt32Ty(M.getContext());
    FindConstant(ConstantInt::get(IdxTy, 0));
    FindType(IdxTy);
    FindType(arg->getType());
  }
}

void SPIRVProducerPass::FindType(Type *Ty) {
  TypeList &TyList = getTypeList();

  if (0 != TyList.idFor(Ty)) {
    return;
  }

  if (Ty->isPointerTy()) {
    auto AddrSpace = Ty->getPointerAddressSpace();
    if ((AddressSpace::Constant == AddrSpace) ||
        (AddressSpace::Global == AddrSpace)) {
      auto PointeeTy = Ty->getPointerElementType();

      if (PointeeTy->isStructTy() &&
          dyn_cast<StructType>(PointeeTy)->isOpaque()) {
        FindType(PointeeTy);
        auto ActualPointerTy =
            PointeeTy->getPointerTo(AddressSpace::UniformConstant);
        FindType(ActualPointerTy);
        return;
      }
    }
  }

  // By convention, LLVM array type with 0 elements will map to
  // OpTypeRuntimeArray.  Otherwise, it will map to OpTypeArray, which
  // has a constant number of elements. We need to support type of the
  // constant.
  if (auto *arrayTy = dyn_cast<ArrayType>(Ty)) {
    if (arrayTy->getNumElements() > 0) {
      LLVMContext &Context = Ty->getContext();
      FindType(Type::getInt32Ty(Context));
    }
  }

  for (Type *SubTy : Ty->subtypes()) {
    FindType(SubTy);
  }

  TyList.insert(Ty);
}

void SPIRVProducerPass::FindConstantPerGlobalVar(GlobalVariable &GV) {
  // If the global variable has a (non undef) initializer.
  if (GV.hasInitializer() && !isa<UndefValue>(GV.getInitializer())) {
    // Generate the constant if it's not the initializer to a module scope
    // constant that we will expect in a storage buffer.
    const bool module_scope_constant_external_init =
        (GV.getType()->getPointerAddressSpace() == AddressSpace::Constant) &&
        clspv::Option::ModuleConstantsInStorageBuffer();
    if (!module_scope_constant_external_init) {
      FindConstant(GV.getInitializer());
    }
  }
}

void SPIRVProducerPass::FindConstantPerFunc(Function &F) {
  // Investigate constants in function body.
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *call = dyn_cast<CallInst>(&I)) {
        auto name = call->getCalledFunction()->getName();
        if (name == clspv::LiteralSamplerFunction()) {
          // We've handled these constants elsewhere, so skip it.
          continue;
        }
        if (name.startswith(clspv::ResourceAccessorFunction())) {
          continue;
        }
        if (name.startswith(clspv::WorkgroupAccessorFunction())) {
          continue;
        }
        if (name.startswith(clspv::SPIRVOpIntrinsicFunction())) {
          // Skip the first operand that has the SPIR-V Opcode
          for (unsigned i = 1; i < I.getNumOperands(); i++) {
            if (isa<Constant>(I.getOperand(i)) &&
                !isa<GlobalValue>(I.getOperand(i))) {
              FindConstant(I.getOperand(i));
            }
          }
          continue;
        }
      }

      if (isa<AllocaInst>(I)) {
        // Alloca instruction has constant for the number of element. Ignore it.
        continue;
      } else if (isa<ShuffleVectorInst>(I)) {
        for (unsigned i = 0; i < I.getNumOperands(); i++) {
          // Ignore constant for mask of shuffle vector instruction.
          if (i == 2) {
            continue;
          }

          if (isa<Constant>(I.getOperand(i)) &&
              !isa<GlobalValue>(I.getOperand(i))) {
            FindConstant(I.getOperand(i));
          }
        }

        continue;
      } else if (isa<InsertElementInst>(I)) {
        // Handle InsertElement with <4 x i8> specially.
        Type *CompositeTy = I.getOperand(0)->getType();
        if (is4xi8vec(CompositeTy)) {
          LLVMContext &Context = CompositeTy->getContext();
          if (isa<Constant>(I.getOperand(0))) {
            FindConstant(I.getOperand(0));
          }

          if (isa<Constant>(I.getOperand(1))) {
            FindConstant(I.getOperand(1));
          }

          // Add mask constant 0xFF.
          Constant *CstFF = ConstantInt::get(Type::getInt32Ty(Context), 0xFF);
          FindConstant(CstFF);

          // Add shift amount constant.
          if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2))) {
            uint64_t Idx = CI->getZExtValue();
            Constant *CstShiftAmount =
                ConstantInt::get(Type::getInt32Ty(Context), Idx * 8);
            FindConstant(CstShiftAmount);
          }

          continue;
        }

        for (unsigned i = 0; i < I.getNumOperands(); i++) {
          // Ignore constant for index of InsertElement instruction.
          if (i == 2) {
            continue;
          }

          if (isa<Constant>(I.getOperand(i)) &&
              !isa<GlobalValue>(I.getOperand(i))) {
            FindConstant(I.getOperand(i));
          }
        }

        continue;
      } else if (isa<ExtractElementInst>(I)) {
        // Handle ExtractElement with <4 x i8> specially.
        Type *CompositeTy = I.getOperand(0)->getType();
        if (is4xi8vec(CompositeTy)) {
          LLVMContext &Context = CompositeTy->getContext();
          if (isa<Constant>(I.getOperand(0))) {
            FindConstant(I.getOperand(0));
          }

          // Add mask constant 0xFF.
          Constant *CstFF = ConstantInt::get(Type::getInt32Ty(Context), 0xFF);
          FindConstant(CstFF);

          // Add shift amount constant.
          if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1))) {
            uint64_t Idx = CI->getZExtValue();
            Constant *CstShiftAmount =
                ConstantInt::get(Type::getInt32Ty(Context), Idx * 8);
            FindConstant(CstShiftAmount);
          } else {
            ConstantInt *Cst8 = ConstantInt::get(Type::getInt32Ty(Context), 8);
            FindConstant(Cst8);
          }

          continue;
        }

        for (unsigned i = 0; i < I.getNumOperands(); i++) {
          // Ignore constant for index of ExtractElement instruction.
          if (i == 1) {
            continue;
          }

          if (isa<Constant>(I.getOperand(i)) &&
              !isa<GlobalValue>(I.getOperand(i))) {
            FindConstant(I.getOperand(i));
          }
        }

        continue;
      } else if ((Instruction::Xor == I.getOpcode()) &&
                 I.getType()->isIntegerTy(1)) {
        // We special case for Xor where the type is i1 and one of the arguments
        // is a constant 1 (true), this is an OpLogicalNot in SPIR-V, and we
        // don't need the constant
        bool foundConstantTrue = false;
        for (Use &Op : I.operands()) {
          if (isa<Constant>(Op) && !isa<GlobalValue>(Op)) {
            auto CI = cast<ConstantInt>(Op);

            if (CI->isZero() || foundConstantTrue) {
              // If we already found the true constant, we might (probably only
              // on -O0) have an OpLogicalNot which is taking a constant
              // argument, so discover it anyway.
              FindConstant(Op);
            } else {
              foundConstantTrue = true;
            }
          }
        }

        continue;
      } else if (isa<TruncInst>(I)) {
        // Special case if i8 is not generally handled.
        if (!clspv::Option::Int8Support()) {
          // For truncation to i8 we mask against 255.
          Type *ToTy = I.getType();
          if (8u == ToTy->getPrimitiveSizeInBits()) {
            LLVMContext &Context = ToTy->getContext();
            Constant *Cst255 =
                ConstantInt::get(Type::getInt32Ty(Context), 0xff);
            FindConstant(Cst255);
          }
        }
      } else if (isa<AtomicRMWInst>(I)) {
        LLVMContext &Context = I.getContext();

        FindConstant(
            ConstantInt::get(Type::getInt32Ty(Context), spv::ScopeDevice));
        FindConstant(ConstantInt::get(
            Type::getInt32Ty(Context),
            spv::MemorySemanticsUniformMemoryMask |
                spv::MemorySemanticsSequentiallyConsistentMask));
      }

      for (Use &Op : I.operands()) {
        if (isa<Constant>(Op) && !isa<GlobalValue>(Op)) {
          FindConstant(Op);
        }
      }
    }
  }
}

void SPIRVProducerPass::FindConstant(Value *V) {
  ValueList &CstList = getConstantList();

  // If V is already tracked, ignore it.
  if (0 != CstList.idFor(V)) {
    return;
  }

  if (isa<GlobalValue>(V) && clspv::Option::ModuleConstantsInStorageBuffer()) {
    return;
  }

  Constant *Cst = cast<Constant>(V);
  Type *CstTy = Cst->getType();

  // Handle constant with <4 x i8> type specially.
  if (is4xi8vec(CstTy)) {
    if (!isa<GlobalValue>(V)) {
      CstList.insert(V);
    }
  }

  if (Cst->getNumOperands()) {
    for (User::const_op_iterator I = Cst->op_begin(), E = Cst->op_end(); I != E;
         ++I) {
      FindConstant(*I);
    }

    CstList.insert(Cst);
    return;
  } else if (const ConstantDataSequential *CDS =
                 dyn_cast<ConstantDataSequential>(Cst)) {
    // Add constants for each element to constant list.
    for (unsigned i = 0; i < CDS->getNumElements(); i++) {
      Constant *EleCst = CDS->getElementAsConstant(i);
      FindConstant(EleCst);
    }
  }

  if (!isa<GlobalValue>(V)) {
    CstList.insert(V);
  }
}

spv::StorageClass SPIRVProducerPass::GetStorageClass(unsigned AddrSpace) const {
  switch (AddrSpace) {
  default:
    llvm_unreachable("Unsupported OpenCL address space");
  case AddressSpace::Private:
    return spv::StorageClassFunction;
  case AddressSpace::Global:
    return spv::StorageClassStorageBuffer;
  case AddressSpace::Constant:
    return clspv::Option::ConstantArgsInUniformBuffer()
               ? spv::StorageClassUniform
               : spv::StorageClassStorageBuffer;
  case AddressSpace::Input:
    return spv::StorageClassInput;
  case AddressSpace::Local:
    return spv::StorageClassWorkgroup;
  case AddressSpace::UniformConstant:
    return spv::StorageClassUniformConstant;
  case AddressSpace::Uniform:
    return spv::StorageClassUniform;
  case AddressSpace::ModuleScopePrivate:
    return spv::StorageClassPrivate;
  }
}

spv::StorageClass
SPIRVProducerPass::GetStorageClassForArgKind(clspv::ArgKind arg_kind) const {
  switch (arg_kind) {
  case clspv::ArgKind::Buffer:
    return spv::StorageClassStorageBuffer;
  case clspv::ArgKind::BufferUBO:
    return spv::StorageClassUniform;
  case clspv::ArgKind::Pod:
    return clspv::Option::PodArgsInUniformBuffer()
               ? spv::StorageClassUniform
               : spv::StorageClassStorageBuffer;
  case clspv::ArgKind::Local:
    return spv::StorageClassWorkgroup;
  case clspv::ArgKind::ReadOnlyImage:
  case clspv::ArgKind::WriteOnlyImage:
  case clspv::ArgKind::Sampler:
    return spv::StorageClassUniformConstant;
  default:
    llvm_unreachable("Unsupported storage class for argument kind");
  }
}

spv::BuiltIn SPIRVProducerPass::GetBuiltin(StringRef Name) const {
  return StringSwitch<spv::BuiltIn>(Name)
      .Case("__spirv_GlobalInvocationId", spv::BuiltInGlobalInvocationId)
      .Case("__spirv_LocalInvocationId", spv::BuiltInLocalInvocationId)
      .Case("__spirv_WorkgroupSize", spv::BuiltInWorkgroupSize)
      .Case("__spirv_NumWorkgroups", spv::BuiltInNumWorkgroups)
      .Case("__spirv_WorkgroupId", spv::BuiltInWorkgroupId)
      .Default(spv::BuiltInMax);
}

void SPIRVProducerPass::GenerateExtInstImport() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  uint32_t &ExtInstImportID = getOpExtInstImportID();

  //
  // Generate OpExtInstImport.
  //
  // Ops[0] ... Ops[n] = Name (Literal String)
  ExtInstImportID = nextID;
  SPIRVInstList.push_back(new SPIRVInstruction(spv::OpExtInstImport, nextID++,
                                               MkString("GLSL.std.450")));
}

void SPIRVProducerPass::GenerateSPIRVTypes(LLVMContext &Context,
                                           Module &module) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  ValueMapType &AllocatedVMap = getAllocatedValueMap();
  const auto &DL = module.getDataLayout();

  // Map for OpTypeRuntimeArray. If argument has pointer type, 2 spirv type
  // instructions are generated. They are OpTypePointer and OpTypeRuntimeArray.
  DenseMap<Type *, uint32_t> OpRuntimeTyMap;

  for (Type *Ty : getTypeList()) {
    // Update TypeMap with nextID for reference later.
    TypeMap[Ty] = nextID;

    switch (Ty->getTypeID()) {
    default: {
      Ty->print(errs());
      llvm_unreachable("Unsupported type???");
      break;
    }
    case Type::MetadataTyID:
    case Type::LabelTyID: {
      // Ignore these types.
      break;
    }
    case Type::PointerTyID: {
      PointerType *PTy = cast<PointerType>(Ty);
      unsigned AddrSpace = PTy->getAddressSpace();

      // For the purposes of our Vulkan SPIR-V type system, constant and global
      // are conflated.
      bool UseExistingOpTypePointer = false;
      if (AddressSpace::Constant == AddrSpace) {
        if (!clspv::Option::ConstantArgsInUniformBuffer()) {
          AddrSpace = AddressSpace::Global;
          // Check to see if we already created this type (for instance, if we
          // had a constant <type>* and a global <type>*, the type would be
          // created by one of these types, and shared by both).
          auto GlobalTy = PTy->getPointerElementType()->getPointerTo(AddrSpace);
          if (0 < TypeMap.count(GlobalTy)) {
            TypeMap[PTy] = TypeMap[GlobalTy];
            UseExistingOpTypePointer = true;
            break;
          }
        }
      } else if (AddressSpace::Global == AddrSpace) {
        if (!clspv::Option::ConstantArgsInUniformBuffer()) {
          AddrSpace = AddressSpace::Constant;

          // Check to see if we already created this type (for instance, if we
          // had a constant <type>* and a global <type>*, the type would be
          // created by one of these types, and shared by both).
          auto ConstantTy =
              PTy->getPointerElementType()->getPointerTo(AddrSpace);
          if (0 < TypeMap.count(ConstantTy)) {
            TypeMap[PTy] = TypeMap[ConstantTy];
            UseExistingOpTypePointer = true;
          }
        }
      }

      const bool HasArgUser = true;

      if (HasArgUser && !UseExistingOpTypePointer) {
        //
        // Generate OpTypePointer.
        //

        // OpTypePointer
        // Ops[0] = Storage Class
        // Ops[1] = Element Type ID
        SPIRVOperandList Ops;

        Ops << MkNum(GetStorageClass(AddrSpace))
            << MkId(lookupType(PTy->getElementType()));

        auto *Inst = new SPIRVInstruction(spv::OpTypePointer, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      }
      break;
    }
    case Type::StructTyID: {
      StructType *STy = cast<StructType>(Ty);

      // Handle sampler type.
      if (STy->isOpaque()) {
        if (STy->getName().equals("opencl.sampler_t")) {
          //
          // Generate OpTypeSampler
          //
          // Empty Ops.
          SPIRVOperandList Ops;

          auto *Inst = new SPIRVInstruction(spv::OpTypeSampler, nextID++, Ops);
          SPIRVInstList.push_back(Inst);
          break;
        } else if (STy->getName().equals("opencl.image2d_ro_t") ||
                   STy->getName().equals("opencl.image2d_wo_t") ||
                   STy->getName().equals("opencl.image3d_ro_t") ||
                   STy->getName().equals("opencl.image3d_wo_t")) {
          //
          // Generate OpTypeImage
          //
          // Ops[0] = Sampled Type ID
          // Ops[1] = Dim ID
          // Ops[2] = Depth (Literal Number)
          // Ops[3] = Arrayed (Literal Number)
          // Ops[4] = MS (Literal Number)
          // Ops[5] = Sampled (Literal Number)
          // Ops[6] = Image Format ID
          //
          SPIRVOperandList Ops;

          // TODO: Changed Sampled Type according to situations.
          uint32_t SampledTyID = lookupType(Type::getFloatTy(Context));
          Ops << MkId(SampledTyID);

          spv::Dim DimID = spv::Dim2D;
          if (STy->getName().equals("opencl.image3d_ro_t") ||
              STy->getName().equals("opencl.image3d_wo_t")) {
            DimID = spv::Dim3D;
          }
          Ops << MkNum(DimID);

          // TODO: Set up Depth.
          Ops << MkNum(0);

          // TODO: Set up Arrayed.
          Ops << MkNum(0);

          // TODO: Set up MS.
          Ops << MkNum(0);

          // TODO: Set up Sampled.
          //
          // From Spec
          //
          // 0 indicates this is only known at run time, not at compile time
          // 1 indicates will be used with sampler
          // 2 indicates will be used without a sampler (a storage image)
          uint32_t Sampled = 1;
          if (STy->getName().equals("opencl.image2d_wo_t") ||
              STy->getName().equals("opencl.image3d_wo_t")) {
            Sampled = 2;
          }
          Ops << MkNum(Sampled);

          // TODO: Set up Image Format.
          Ops << MkNum(spv::ImageFormatUnknown);

          auto *Inst = new SPIRVInstruction(spv::OpTypeImage, nextID++, Ops);
          SPIRVInstList.push_back(Inst);
          break;
        }
      }

      //
      // Generate OpTypeStruct
      //
      // Ops[0] ... Ops[n] = Member IDs
      SPIRVOperandList Ops;

      for (auto *EleTy : STy->elements()) {
        Ops << MkId(lookupType(EleTy));
      }

      uint32_t STyID = nextID;

      auto *Inst = new SPIRVInstruction(spv::OpTypeStruct, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      // Generate OpMemberDecorate.
      auto DecoInsertPoint =
          std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                       [](SPIRVInstruction *Inst) -> bool {
                         return Inst->getOpcode() != spv::OpDecorate &&
                                Inst->getOpcode() != spv::OpMemberDecorate &&
                                Inst->getOpcode() != spv::OpExtInstImport;
                       });

      const auto StructLayout = DL.getStructLayout(STy);
      // Search for the correct offsets if this type was remapped.
      std::vector<uint32_t> *offsets = nullptr;
      auto iter = RemappedUBOTypeOffsets.find(STy);
      if (iter != RemappedUBOTypeOffsets.end()) {
        offsets = &iter->second;
      }

      // #error TODO(dneto): Only do this if in TypesNeedingLayout.
      for (unsigned MemberIdx = 0; MemberIdx < STy->getNumElements();
           MemberIdx++) {
        // Ops[0] = Structure Type ID
        // Ops[1] = Member Index(Literal Number)
        // Ops[2] = Decoration (Offset)
        // Ops[3] = Byte Offset (Literal Number)
        Ops.clear();

        Ops << MkId(STyID) << MkNum(MemberIdx) << MkNum(spv::DecorationOffset);

        auto ByteOffset =
            static_cast<uint32_t>(StructLayout->getElementOffset(MemberIdx));
        if (offsets) {
          ByteOffset = (*offsets)[MemberIdx];
        }
        // const auto ByteOffset =
        //    uint32_t(StructLayout->getElementOffset(MemberIdx));
        Ops << MkNum(ByteOffset);

        auto *DecoInst = new SPIRVInstruction(spv::OpMemberDecorate, Ops);
        SPIRVInstList.insert(DecoInsertPoint, DecoInst);
      }

      // Generate OpDecorate.
      if (StructTypesNeedingBlock.idFor(STy)) {
        Ops.clear();
        // Use Block decorations with StorageBuffer storage class.
        Ops << MkId(STyID) << MkNum(spv::DecorationBlock);

        auto *DecoInst = new SPIRVInstruction(spv::OpDecorate, Ops);
        SPIRVInstList.insert(DecoInsertPoint, DecoInst);
      }
      break;
    }
    case Type::IntegerTyID: {
      unsigned BitWidth = Ty->getPrimitiveSizeInBits();

      if (BitWidth == 1) {
        auto *Inst = new SPIRVInstruction(spv::OpTypeBool, nextID++, {});
        SPIRVInstList.push_back(Inst);
      } else {
        if (!clspv::Option::Int8Support()) {
          // i8 is added to TypeMap as i32.
          // No matter what LLVM type is requested first, always alias the
          // second one's SPIR-V type to be the same as the one we generated
          // first.
          unsigned aliasToWidth = 0;
          if (BitWidth == 8) {
            aliasToWidth = 32;
            BitWidth = 32;
          } else if (BitWidth == 32) {
            aliasToWidth = 8;
          }
          if (aliasToWidth) {
            Type *otherType = Type::getIntNTy(Ty->getContext(), aliasToWidth);
            auto where = TypeMap.find(otherType);
            if (where == TypeMap.end()) {
              // Go ahead and make it, but also map the other type to it.
              TypeMap[otherType] = nextID;
            } else {
              // Alias this SPIR-V type the existing type.
              TypeMap[Ty] = where->second;
              break;
            }
          }
        }

        SPIRVOperandList Ops;
        Ops << MkNum(BitWidth) << MkNum(0 /* not signed */);

        SPIRVInstList.push_back(
            new SPIRVInstruction(spv::OpTypeInt, nextID++, Ops));
      }
      break;
    }
    case Type::HalfTyID:
    case Type::FloatTyID:
    case Type::DoubleTyID: {
      SPIRVOperand *WidthOp = new SPIRVOperand(
          SPIRVOperandType::LITERAL_INTEGER, Ty->getPrimitiveSizeInBits());

      SPIRVInstList.push_back(
          new SPIRVInstruction(spv::OpTypeFloat, nextID++, WidthOp));
      break;
    }
    case Type::ArrayTyID: {
      ArrayType *ArrTy = cast<ArrayType>(Ty);
      const uint64_t Length = ArrTy->getArrayNumElements();
      if (Length == 0) {
        // By convention, map it to a RuntimeArray.

        // Only generate the type once.
        // TODO(dneto): Can it ever be generated more than once?
        // Doesn't LLVM type uniqueness guarantee we'll only see this
        // once?
        Type *EleTy = ArrTy->getArrayElementType();
        if (OpRuntimeTyMap.count(EleTy) == 0) {
          uint32_t OpTypeRuntimeArrayID = nextID;
          OpRuntimeTyMap[Ty] = nextID;

          //
          // Generate OpTypeRuntimeArray.
          //

          // OpTypeRuntimeArray
          // Ops[0] = Element Type ID
          SPIRVOperandList Ops;
          Ops << MkId(lookupType(EleTy));

          SPIRVInstList.push_back(
              new SPIRVInstruction(spv::OpTypeRuntimeArray, nextID++, Ops));

          if (Hack_generate_runtime_array_stride_early) {
            // Generate OpDecorate.
            auto DecoInsertPoint = std::find_if(
                SPIRVInstList.begin(), SPIRVInstList.end(),
                [](SPIRVInstruction *Inst) -> bool {
                  return Inst->getOpcode() != spv::OpDecorate &&
                         Inst->getOpcode() != spv::OpMemberDecorate &&
                         Inst->getOpcode() != spv::OpExtInstImport;
                });

            // Ops[0] = Target ID
            // Ops[1] = Decoration (ArrayStride)
            // Ops[2] = Stride Number(Literal Number)
            Ops.clear();

            Ops << MkId(OpTypeRuntimeArrayID)
                << MkNum(spv::DecorationArrayStride)
                << MkNum(static_cast<uint32_t>(GetTypeAllocSize(EleTy, DL)));

            auto *DecoInst = new SPIRVInstruction(spv::OpDecorate, Ops);
            SPIRVInstList.insert(DecoInsertPoint, DecoInst);
          }
        }

      } else {

        //
        // Generate OpConstant and OpTypeArray.
        //

        //
        // Generate OpConstant for array length.
        //
        // Ops[0] = Result Type ID
        // Ops[1] .. Ops[n] = Values LiteralNumber
        SPIRVOperandList Ops;

        Type *LengthTy = Type::getInt32Ty(Context);
        uint32_t ResTyID = lookupType(LengthTy);
        Ops << MkId(ResTyID);

        assert(Length < UINT32_MAX);
        Ops << MkNum(static_cast<uint32_t>(Length));

        // Add constant for length to constant list.
        Constant *CstLength = ConstantInt::get(LengthTy, Length);
        AllocatedVMap[CstLength] = nextID;
        VMap[CstLength] = nextID;
        uint32_t LengthID = nextID;

        auto *CstInst = new SPIRVInstruction(spv::OpConstant, nextID++, Ops);
        SPIRVInstList.push_back(CstInst);

        // Remember to generate ArrayStride later
        getTypesNeedingArrayStride().insert(Ty);

        //
        // Generate OpTypeArray.
        //
        // Ops[0] = Element Type ID
        // Ops[1] = Array Length Constant ID
        Ops.clear();

        uint32_t EleTyID = lookupType(ArrTy->getElementType());
        Ops << MkId(EleTyID) << MkId(LengthID);

        // Update TypeMap with nextID.
        TypeMap[Ty] = nextID;

        auto *ArrayInst = new SPIRVInstruction(spv::OpTypeArray, nextID++, Ops);
        SPIRVInstList.push_back(ArrayInst);
      }
      break;
    }
    case Type::VectorTyID: {
      // <4 x i8> is changed to i32 if i8 is not generally supported.
      if (!clspv::Option::Int8Support() &&
          Ty->getVectorElementType() == Type::getInt8Ty(Context)) {
        if (Ty->getVectorNumElements() == 4) {
          TypeMap[Ty] = lookupType(Ty->getVectorElementType());
          break;
        } else {
          Ty->print(errs());
          llvm_unreachable("Support above i8 vector type");
        }
      }

      // Ops[0] = Component Type ID
      // Ops[1] = Component Count (Literal Number)
      SPIRVOperandList Ops;
      Ops << MkId(lookupType(Ty->getVectorElementType()))
          << MkNum(Ty->getVectorNumElements());

      SPIRVInstruction *inst =
          new SPIRVInstruction(spv::OpTypeVector, nextID++, Ops);
      SPIRVInstList.push_back(inst);
      break;
    }
    case Type::VoidTyID: {
      auto *Inst = new SPIRVInstruction(spv::OpTypeVoid, nextID++, {});
      SPIRVInstList.push_back(Inst);
      break;
    }
    case Type::FunctionTyID: {
      // Generate SPIRV instruction for function type.
      FunctionType *FTy = cast<FunctionType>(Ty);

      // Ops[0] = Return Type ID
      // Ops[1] ... Ops[n] = Parameter Type IDs
      SPIRVOperandList Ops;

      // Find SPIRV instruction for return type
      Ops << MkId(lookupType(FTy->getReturnType()));

      // Find SPIRV instructions for parameter types
      for (unsigned k = 0; k < FTy->getNumParams(); k++) {
        // Find SPIRV instruction for parameter type.
        auto ParamTy = FTy->getParamType(k);
        if (ParamTy->isPointerTy()) {
          auto PointeeTy = ParamTy->getPointerElementType();
          if (PointeeTy->isStructTy() &&
              dyn_cast<StructType>(PointeeTy)->isOpaque()) {
            ParamTy = PointeeTy;
          }
        }

        Ops << MkId(lookupType(ParamTy));
      }

      auto *Inst = new SPIRVInstruction(spv::OpTypeFunction, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }
    }
  }

  // Generate OpTypeSampledImage.
  TypeMapType &OpImageTypeMap = getImageTypeMap();
  for (auto &ImageType : OpImageTypeMap) {
    //
    // Generate OpTypeSampledImage.
    //
    // Ops[0] = Image Type ID
    //
    SPIRVOperandList Ops;

    Type *ImgTy = ImageType.first;
    Ops << MkId(TypeMap[ImgTy]);

    // Update OpImageTypeMap.
    ImageType.second = nextID;

    auto *Inst = new SPIRVInstruction(spv::OpTypeSampledImage, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
  }

  // Generate types for pointer-to-local arguments.
  for (auto spec_id = clspv::FirstLocalSpecId(); spec_id < max_local_spec_id_;
       ++spec_id) {
    LocalArgInfo &arg_info = LocalSpecIdInfoMap[spec_id];

    // Generate the spec constant.
    SPIRVOperandList Ops;
    Ops << MkId(lookupType(Type::getInt32Ty(Context))) << MkNum(1);
    SPIRVInstList.push_back(
        new SPIRVInstruction(spv::OpSpecConstant, arg_info.array_size_id, Ops));

    // Generate the array type.
    Ops.clear();
    // The element type must have been created.
    uint32_t elem_ty_id = lookupType(arg_info.elem_type);
    assert(elem_ty_id);
    Ops << MkId(elem_ty_id) << MkId(arg_info.array_size_id);

    SPIRVInstList.push_back(
        new SPIRVInstruction(spv::OpTypeArray, arg_info.array_type_id, Ops));

    Ops.clear();
    Ops << MkNum(spv::StorageClassWorkgroup) << MkId(arg_info.array_type_id);
    SPIRVInstList.push_back(new SPIRVInstruction(
        spv::OpTypePointer, arg_info.ptr_array_type_id, Ops));
  }
}

void SPIRVProducerPass::GenerateSPIRVConstants() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  ValueMapType &AllocatedVMap = getAllocatedValueMap();
  ValueList &CstList = getConstantList();
  const bool hack_undef = clspv::Option::HackUndef();

  for (uint32_t i = 0; i < CstList.size(); i++) {
    // UniqueVector ids are 1-based.
    Constant *Cst = cast<Constant>(CstList[i + 1]);

    // OpTypeArray's constant was already generated.
    if (AllocatedVMap.find_as(Cst) != AllocatedVMap.end()) {
      continue;
    }

    // Set ValueMap with nextID for reference later.
    VMap[Cst] = nextID;

    //
    // Generate OpConstant.
    //

    // Ops[0] = Result Type ID
    // Ops[1] .. Ops[n] = Values LiteralNumber
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(Cst->getType()));

    std::vector<uint32_t> LiteralNum;
    spv::Op Opcode = spv::OpNop;

    if (isa<UndefValue>(Cst)) {
      // Ops[0] = Result Type ID
      Opcode = spv::OpUndef;
      if (hack_undef && IsTypeNullable(Cst->getType())) {
        Opcode = spv::OpConstantNull;
      }
    } else if (const ConstantInt *CI = dyn_cast<ConstantInt>(Cst)) {
      unsigned BitWidth = CI->getBitWidth();
      if (BitWidth == 1) {
        // If the bitwidth of constant is 1, generate OpConstantTrue or
        // OpConstantFalse.
        if (CI->getZExtValue()) {
          // Ops[0] = Result Type ID
          Opcode = spv::OpConstantTrue;
        } else {
          // Ops[0] = Result Type ID
          Opcode = spv::OpConstantFalse;
        }
      } else {
        auto V = CI->getZExtValue();
        LiteralNum.push_back(V & 0xFFFFFFFF);

        if (BitWidth > 32) {
          LiteralNum.push_back(V >> 32);
        }

        Opcode = spv::OpConstant;

        Ops << MkInteger(LiteralNum);

        if (BitWidth == 32 && V == 0) {
          constant_i32_zero_id_ = nextID;
        }
      }
    } else if (const ConstantFP *CFP = dyn_cast<ConstantFP>(Cst)) {
      uint64_t FPVal = CFP->getValueAPF().bitcastToAPInt().getZExtValue();
      Type *CFPTy = CFP->getType();
      if (CFPTy->isFloatTy()) {
        LiteralNum.push_back(FPVal & 0xFFFFFFFF);
      } else if (CFPTy->isDoubleTy()) {
        LiteralNum.push_back(FPVal & 0xFFFFFFFF);
        LiteralNum.push_back(FPVal >> 32);
      } else {
        CFPTy->print(errs());
        llvm_unreachable("Implement this ConstantFP Type");
      }

      Opcode = spv::OpConstant;

      Ops << MkFloat(LiteralNum);
    } else if (isa<ConstantDataSequential>(Cst) &&
               cast<ConstantDataSequential>(Cst)->isString()) {
      Cst->print(errs());
      llvm_unreachable("Implement this Constant");

    } else if (const ConstantDataSequential *CDS =
                   dyn_cast<ConstantDataSequential>(Cst)) {
      // Let's convert <4 x i8> constant to int constant specially.
      // This case occurs when all the values are specified as constant
      // ints.
      Type *CstTy = Cst->getType();
      if (is4xi8vec(CstTy)) {
        LLVMContext &Context = CstTy->getContext();

        //
        // Generate OpConstant with OpTypeInt 32 0.
        //
        uint32_t IntValue = 0;
        for (unsigned k = 0; k < 4; k++) {
          const uint64_t Val = CDS->getElementAsInteger(k);
          IntValue = (IntValue << 8) | (Val & 0xffu);
        }

        Type *i32 = Type::getInt32Ty(Context);
        Constant *CstInt = ConstantInt::get(i32, IntValue);
        // If this constant is already registered on VMap, use it.
        if (VMap.count(CstInt)) {
          uint32_t CstID = VMap[CstInt];
          VMap[Cst] = CstID;
          continue;
        }

        Ops << MkNum(IntValue);

        auto *CstInst = new SPIRVInstruction(spv::OpConstant, nextID++, Ops);
        SPIRVInstList.push_back(CstInst);

        continue;
      }

      // A normal constant-data-sequential case.
      for (unsigned k = 0; k < CDS->getNumElements(); k++) {
        Constant *EleCst = CDS->getElementAsConstant(k);
        uint32_t EleCstID = VMap[EleCst];
        Ops << MkId(EleCstID);
      }

      Opcode = spv::OpConstantComposite;
    } else if (const ConstantAggregate *CA = dyn_cast<ConstantAggregate>(Cst)) {
      // Let's convert <4 x i8> constant to int constant specially.
      // This case occurs when at least one of the values is an undef.
      Type *CstTy = Cst->getType();
      if (is4xi8vec(CstTy)) {
        LLVMContext &Context = CstTy->getContext();

        //
        // Generate OpConstant with OpTypeInt 32 0.
        //
        uint32_t IntValue = 0;
        for (User::const_op_iterator I = Cst->op_begin(), E = Cst->op_end();
             I != E; ++I) {
          uint64_t Val = 0;
          const Value *CV = *I;
          if (auto *CI2 = dyn_cast<ConstantInt>(CV)) {
            Val = CI2->getZExtValue();
          }
          IntValue = (IntValue << 8) | (Val & 0xffu);
        }

        Type *i32 = Type::getInt32Ty(Context);
        Constant *CstInt = ConstantInt::get(i32, IntValue);
        // If this constant is already registered on VMap, use it.
        if (VMap.count(CstInt)) {
          uint32_t CstID = VMap[CstInt];
          VMap[Cst] = CstID;
          continue;
        }

        Ops << MkNum(IntValue);

        auto *CstInst = new SPIRVInstruction(spv::OpConstant, nextID++, Ops);
        SPIRVInstList.push_back(CstInst);

        continue;
      }

      // We use a constant composite in SPIR-V for our constant aggregate in
      // LLVM.
      Opcode = spv::OpConstantComposite;

      for (unsigned k = 0; k < CA->getNumOperands(); k++) {
        // Look up the ID of the element of this aggregate (which we will
        // previously have created a constant for).
        uint32_t ElementConstantID = VMap[CA->getAggregateElement(k)];

        // And add an operand to the composite we are constructing
        Ops << MkId(ElementConstantID);
      }
    } else if (Cst->isNullValue()) {
      Opcode = spv::OpConstantNull;
    } else {
      Cst->print(errs());
      llvm_unreachable("Unsupported Constant???");
    }

    if (Opcode == spv::OpConstantNull && Cst->getType()->isPointerTy()) {
      // Null pointer requires variable pointers.
      setVariablePointersCapabilities(Cst->getType()->getPointerAddressSpace());
    }

    auto *CstInst = new SPIRVInstruction(Opcode, nextID++, Ops);
    SPIRVInstList.push_back(CstInst);
  }
}

void SPIRVProducerPass::GenerateSamplers(Module &M) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();

  auto &sampler_map = getSamplerMap();
  SamplerMapIndexToIDMap.clear();
  DenseMap<unsigned, unsigned> SamplerLiteralToIDMap;
  DenseMap<unsigned, unsigned> SamplerLiteralToDescriptorSetMap;
  DenseMap<unsigned, unsigned> SamplerLiteralToBindingMap;

  // We might have samplers in the sampler map that are not used
  // in the translation unit.  We need to allocate variables
  // for them and bindings too.
  DenseSet<unsigned> used_bindings;

  auto *var_fn = M.getFunction(clspv::LiteralSamplerFunction());
  if (!var_fn)
    return;
  for (auto user : var_fn->users()) {
    // Populate SamplerLiteralToDescriptorSetMap and
    // SamplerLiteralToBindingMap.
    //
    // Look for calls like
    //   call %opencl.sampler_t addrspace(2)*
    //       @clspv.sampler.var.literal(
    //          i32 descriptor,
    //          i32 binding,
    //          i32 index-into-sampler-map)
    if (auto *call = dyn_cast<CallInst>(user)) {
      const size_t index_into_sampler_map = static_cast<size_t>(
          dyn_cast<ConstantInt>(call->getArgOperand(2))->getZExtValue());
      if (index_into_sampler_map >= sampler_map.size()) {
        errs() << "Out of bounds index to sampler map: "
               << index_into_sampler_map;
        llvm_unreachable("bad sampler init: out of bounds");
      }

      auto sampler_value = sampler_map[index_into_sampler_map].first;
      const auto descriptor_set = static_cast<unsigned>(
          dyn_cast<ConstantInt>(call->getArgOperand(0))->getZExtValue());
      const auto binding = static_cast<unsigned>(
          dyn_cast<ConstantInt>(call->getArgOperand(1))->getZExtValue());

      SamplerLiteralToDescriptorSetMap[sampler_value] = descriptor_set;
      SamplerLiteralToBindingMap[sampler_value] = binding;
      used_bindings.insert(binding);
    }
  }

  unsigned index = 0;
  for (auto SamplerLiteral : sampler_map) {
    // Generate OpVariable.
    //
    // GIDOps[0] : Result Type ID
    // GIDOps[1] : Storage Class
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(SamplerTy))
        << MkNum(spv::StorageClassUniformConstant);

    auto sampler_var_id = nextID++;
    auto *Inst = new SPIRVInstruction(spv::OpVariable, sampler_var_id, Ops);
    SPIRVInstList.push_back(Inst);

    SamplerMapIndexToIDMap[index] = sampler_var_id;
    SamplerLiteralToIDMap[SamplerLiteral.first] = sampler_var_id;

    // Find Insert Point for OpDecorate.
    auto DecoInsertPoint =
        std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                     [](SPIRVInstruction *Inst) -> bool {
                       return Inst->getOpcode() != spv::OpDecorate &&
                              Inst->getOpcode() != spv::OpMemberDecorate &&
                              Inst->getOpcode() != spv::OpExtInstImport;
                     });

    // Ops[0] = Target ID
    // Ops[1] = Decoration (DescriptorSet)
    // Ops[2] = LiteralNumber according to Decoration
    Ops.clear();

    unsigned descriptor_set;
    unsigned binding;
    if (SamplerLiteralToBindingMap.find(SamplerLiteral.first) ==
        SamplerLiteralToBindingMap.end()) {
      // This sampler is not actually used.  Find the next one.
      for (binding = 0; used_bindings.count(binding); binding++)
        ;
      descriptor_set = 0; // Literal samplers always use descriptor set 0.
      used_bindings.insert(binding);
    } else {
      descriptor_set = SamplerLiteralToDescriptorSetMap[SamplerLiteral.first];
      binding = SamplerLiteralToBindingMap[SamplerLiteral.first];
    }

    Ops << MkId(sampler_var_id) << MkNum(spv::DecorationDescriptorSet)
        << MkNum(descriptor_set);

    version0::DescriptorMapEntry::SamplerData sampler_data = {
        SamplerLiteral.first};
    descriptorMapEntries->emplace_back(std::move(sampler_data), descriptor_set,
                                       binding);

    auto *DescDecoInst = new SPIRVInstruction(spv::OpDecorate, Ops);
    SPIRVInstList.insert(DecoInsertPoint, DescDecoInst);

    // Ops[0] = Target ID
    // Ops[1] = Decoration (Binding)
    // Ops[2] = LiteralNumber according to Decoration
    Ops.clear();
    Ops << MkId(sampler_var_id) << MkNum(spv::DecorationBinding)
        << MkNum(binding);

    auto *BindDecoInst = new SPIRVInstruction(spv::OpDecorate, Ops);
    SPIRVInstList.insert(DecoInsertPoint, BindDecoInst);

    index++;
  }
}

void SPIRVProducerPass::GenerateResourceVars(Module &) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();

  // Generate variables.  Make one for each of resource var info object.
  for (auto *info : ModuleOrderedResourceVars) {
    Type *type = info->var_fn->getReturnType();
    // Remap the address space for opaque types.
    switch (info->arg_kind) {
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::ReadOnlyImage:
    case clspv::ArgKind::WriteOnlyImage:
      type = PointerType::get(type->getPointerElementType(),
                              clspv::AddressSpace::UniformConstant);
      break;
    default:
      break;
    }

    info->var_id = nextID++;

    const auto type_id = lookupType(type);
    const auto sc = GetStorageClassForArgKind(info->arg_kind);
    SPIRVOperandList Ops;
    Ops << MkId(type_id) << MkNum(sc);

    auto *Inst = new SPIRVInstruction(spv::OpVariable, info->var_id, Ops);
    SPIRVInstList.push_back(Inst);

    // Map calls to the variable-builtin-function.
    for (auto &U : info->var_fn->uses()) {
      if (auto *call = dyn_cast<CallInst>(U.getUser())) {
        const auto set = unsigned(
            dyn_cast<ConstantInt>(call->getOperand(0))->getZExtValue());
        const auto binding = unsigned(
            dyn_cast<ConstantInt>(call->getOperand(1))->getZExtValue());
        if (set == info->descriptor_set && binding == info->binding) {
          switch (info->arg_kind) {
          case clspv::ArgKind::Buffer:
          case clspv::ArgKind::BufferUBO:
          case clspv::ArgKind::Pod:
            // The call maps to the variable directly.
            VMap[call] = info->var_id;
            break;
          case clspv::ArgKind::Sampler:
          case clspv::ArgKind::ReadOnlyImage:
          case clspv::ArgKind::WriteOnlyImage:
            // The call maps to a load we generate later.
            ResourceVarDeferredLoadCalls[call] = info->var_id;
            break;
          default:
            llvm_unreachable("Unhandled arg kind");
          }
        }
      }
    }
  }

  // Generate associated decorations.

  // Find Insert Point for OpDecorate.
  auto DecoInsertPoint =
      std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                   [](SPIRVInstruction *Inst) -> bool {
                     return Inst->getOpcode() != spv::OpDecorate &&
                            Inst->getOpcode() != spv::OpMemberDecorate &&
                            Inst->getOpcode() != spv::OpExtInstImport;
                   });

  SPIRVOperandList Ops;
  for (auto *info : ModuleOrderedResourceVars) {
    // Decorate with DescriptorSet and Binding.
    Ops.clear();
    Ops << MkId(info->var_id) << MkNum(spv::DecorationDescriptorSet)
        << MkNum(info->descriptor_set);
    SPIRVInstList.insert(DecoInsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));

    Ops.clear();
    Ops << MkId(info->var_id) << MkNum(spv::DecorationBinding)
        << MkNum(info->binding);
    SPIRVInstList.insert(DecoInsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));

    if (info->coherent) {
      // Decorate with Coherent if required for the variable.
      Ops.clear();
      Ops << MkId(info->var_id) << MkNum(spv::DecorationCoherent);
      SPIRVInstList.insert(DecoInsertPoint,
                           new SPIRVInstruction(spv::OpDecorate, Ops));
    }

    // Generate NonWritable and NonReadable
    switch (info->arg_kind) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::BufferUBO:
      if (info->var_fn->getReturnType()->getPointerAddressSpace() ==
          clspv::AddressSpace::Constant) {
        Ops.clear();
        Ops << MkId(info->var_id) << MkNum(spv::DecorationNonWritable);
        SPIRVInstList.insert(DecoInsertPoint,
                             new SPIRVInstruction(spv::OpDecorate, Ops));
      }
      break;
    case clspv::ArgKind::WriteOnlyImage:
      Ops.clear();
      Ops << MkId(info->var_id) << MkNum(spv::DecorationNonReadable);
      SPIRVInstList.insert(DecoInsertPoint,
                           new SPIRVInstruction(spv::OpDecorate, Ops));
      break;
    default:
      break;
    }
  }
}

void SPIRVProducerPass::GenerateGlobalVar(GlobalVariable &GV) {
  Module &M = *GV.getParent();
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  std::vector<uint32_t> &BuiltinDimVec = getBuiltinDimVec();
  const DataLayout &DL = GV.getParent()->getDataLayout();

  const spv::BuiltIn BuiltinType = GetBuiltin(GV.getName());
  Type *Ty = GV.getType();
  PointerType *PTy = cast<PointerType>(Ty);

  uint32_t InitializerID = 0;

  // Workgroup size is handled differently (it goes into a constant)
  if (spv::BuiltInWorkgroupSize == BuiltinType) {
    std::vector<bool> HasMDVec;
    uint32_t PrevXDimCst = 0xFFFFFFFF;
    uint32_t PrevYDimCst = 0xFFFFFFFF;
    uint32_t PrevZDimCst = 0xFFFFFFFF;
    for (Function &Func : *GV.getParent()) {
      if (Func.isDeclaration()) {
        continue;
      }

      // We only need to check kernels.
      if (Func.getCallingConv() != CallingConv::SPIR_KERNEL) {
        continue;
      }

      if (const MDNode *MD =
              dyn_cast<Function>(&Func)->getMetadata("reqd_work_group_size")) {
        uint32_t CurXDimCst = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(0))->getZExtValue());
        uint32_t CurYDimCst = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(1))->getZExtValue());
        uint32_t CurZDimCst = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(2))->getZExtValue());

        if (PrevXDimCst == 0xFFFFFFFF && PrevYDimCst == 0xFFFFFFFF &&
            PrevZDimCst == 0xFFFFFFFF) {
          PrevXDimCst = CurXDimCst;
          PrevYDimCst = CurYDimCst;
          PrevZDimCst = CurZDimCst;
        } else if (CurXDimCst != PrevXDimCst || CurYDimCst != PrevYDimCst ||
                   CurZDimCst != PrevZDimCst) {
          llvm_unreachable(
              "reqd_work_group_size must be the same across all kernels");
        } else {
          continue;
        }

        //
        // Generate OpConstantComposite.
        //
        // Ops[0] : Result Type ID
        // Ops[1] : Constant size for x dimension.
        // Ops[2] : Constant size for y dimension.
        // Ops[3] : Constant size for z dimension.
        SPIRVOperandList Ops;

        uint32_t XDimCstID =
            VMap[mdconst::extract<ConstantInt>(MD->getOperand(0))];
        uint32_t YDimCstID =
            VMap[mdconst::extract<ConstantInt>(MD->getOperand(1))];
        uint32_t ZDimCstID =
            VMap[mdconst::extract<ConstantInt>(MD->getOperand(2))];

        InitializerID = nextID;

        Ops << MkId(lookupType(Ty->getPointerElementType())) << MkId(XDimCstID)
            << MkId(YDimCstID) << MkId(ZDimCstID);

        auto *Inst =
            new SPIRVInstruction(spv::OpConstantComposite, nextID++, Ops);
        SPIRVInstList.push_back(Inst);

        HasMDVec.push_back(true);
      } else {
        HasMDVec.push_back(false);
      }
    }

    // Check all kernels have same definitions for work_group_size.
    bool HasMD = false;
    if (!HasMDVec.empty()) {
      HasMD = HasMDVec[0];
      for (uint32_t i = 1; i < HasMDVec.size(); i++) {
        if (HasMD != HasMDVec[i]) {
          llvm_unreachable(
              "Kernels should have consistent work group size definition");
        }
      }
    }

    // If all kernels do not have metadata for reqd_work_group_size, generate
    // OpSpecConstants for x/y/z dimension.
    if (!HasMD) {
      //
      // Generate OpSpecConstants for x/y/z dimension.
      //
      // Ops[0] : Result Type ID
      // Ops[1] : Constant size for x/y/z dimension (Literal Number).
      uint32_t XDimCstID = 0;
      uint32_t YDimCstID = 0;
      uint32_t ZDimCstID = 0;

      SPIRVOperandList Ops;
      uint32_t result_type_id =
          lookupType(Ty->getPointerElementType()->getSequentialElementType());

      // X Dimension
      Ops << MkId(result_type_id) << MkNum(1);
      XDimCstID = nextID++;
      SPIRVInstList.push_back(
          new SPIRVInstruction(spv::OpSpecConstant, XDimCstID, Ops));

      // Y Dimension
      Ops.clear();
      Ops << MkId(result_type_id) << MkNum(1);
      YDimCstID = nextID++;
      SPIRVInstList.push_back(
          new SPIRVInstruction(spv::OpSpecConstant, YDimCstID, Ops));

      // Z Dimension
      Ops.clear();
      Ops << MkId(result_type_id) << MkNum(1);
      ZDimCstID = nextID++;
      SPIRVInstList.push_back(
          new SPIRVInstruction(spv::OpSpecConstant, ZDimCstID, Ops));

      BuiltinDimVec.push_back(XDimCstID);
      BuiltinDimVec.push_back(YDimCstID);
      BuiltinDimVec.push_back(ZDimCstID);

      //
      // Generate OpSpecConstantComposite.
      //
      // Ops[0] : Result Type ID
      // Ops[1] : Constant size for x dimension.
      // Ops[2] : Constant size for y dimension.
      // Ops[3] : Constant size for z dimension.
      InitializerID = nextID;

      Ops.clear();
      Ops << MkId(lookupType(Ty->getPointerElementType())) << MkId(XDimCstID)
          << MkId(YDimCstID) << MkId(ZDimCstID);

      auto *Inst =
          new SPIRVInstruction(spv::OpSpecConstantComposite, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
    }
  }

  VMap[&GV] = nextID;

  //
  // Generate OpVariable.
  //
  // GIDOps[0] : Result Type ID
  // GIDOps[1] : Storage Class
  SPIRVOperandList Ops;

  const auto AS = PTy->getAddressSpace();
  Ops << MkId(lookupType(Ty)) << MkNum(GetStorageClass(AS));

  if (GV.hasInitializer()) {
    InitializerID = VMap[GV.getInitializer()];
  }

  const bool module_scope_constant_external_init =
      (AS == AddressSpace::Constant) && GV.hasInitializer() &&
      clspv::Option::ModuleConstantsInStorageBuffer();

  if (0 != InitializerID) {
    if (!module_scope_constant_external_init) {
      // Emit the ID of the intiializer as part of the variable definition.
      Ops << MkId(InitializerID);
    }
  }
  const uint32_t var_id = nextID++;

  auto *Inst = new SPIRVInstruction(spv::OpVariable, var_id, Ops);
  SPIRVInstList.push_back(Inst);

  // If we have a builtin.
  if (spv::BuiltInMax != BuiltinType) {
    // Find Insert Point for OpDecorate.
    auto DecoInsertPoint =
        std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                     [](SPIRVInstruction *Inst) -> bool {
                       return Inst->getOpcode() != spv::OpDecorate &&
                              Inst->getOpcode() != spv::OpMemberDecorate &&
                              Inst->getOpcode() != spv::OpExtInstImport;
                     });
    //
    // Generate OpDecorate.
    //
    // DOps[0] = Target ID
    // DOps[1] = Decoration (Builtin)
    // DOps[2] = BuiltIn ID
    uint32_t ResultID;

    // WorkgroupSize is different, we decorate the constant composite that has
    // its value, rather than the variable that we use to access the value.
    if (spv::BuiltInWorkgroupSize == BuiltinType) {
      ResultID = InitializerID;
      // Save both the value and variable IDs for later.
      WorkgroupSizeValueID = InitializerID;
      WorkgroupSizeVarID = VMap[&GV];
    } else {
      ResultID = VMap[&GV];
    }

    SPIRVOperandList DOps;
    DOps << MkId(ResultID) << MkNum(spv::DecorationBuiltIn)
         << MkNum(BuiltinType);

    auto *DescDecoInst = new SPIRVInstruction(spv::OpDecorate, DOps);
    SPIRVInstList.insert(DecoInsertPoint, DescDecoInst);
  } else if (module_scope_constant_external_init) {
    // This module scope constant is initialized from a storage buffer with data
    // provided by the host at binding 0 of the next descriptor set.
    const uint32_t descriptor_set = TakeDescriptorIndex(&M);

    // Emit the intializer to the descriptor map file.
    // Use "kind,buffer" to indicate storage buffer. We might want to expand
    // that later to other types, like uniform buffer.
    std::string hexbytes;
    llvm::raw_string_ostream str(hexbytes);
    clspv::ConstantEmitter(DL, str).Emit(GV.getInitializer());
    version0::DescriptorMapEntry::ConstantData constant_data = {ArgKind::Buffer,
                                                                str.str()};
    descriptorMapEntries->emplace_back(std::move(constant_data), descriptor_set,
                                       0);

    // Find Insert Point for OpDecorate.
    auto DecoInsertPoint =
        std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                     [](SPIRVInstruction *Inst) -> bool {
                       return Inst->getOpcode() != spv::OpDecorate &&
                              Inst->getOpcode() != spv::OpMemberDecorate &&
                              Inst->getOpcode() != spv::OpExtInstImport;
                     });

    // OpDecorate %var Binding <binding>
    SPIRVOperandList DOps;
    DOps << MkId(var_id) << MkNum(spv::DecorationBinding) << MkNum(0);
    DecoInsertPoint = SPIRVInstList.insert(
        DecoInsertPoint, new SPIRVInstruction(spv::OpDecorate, DOps));

    // OpDecorate %var DescriptorSet <descriptor_set>
    DOps.clear();
    DOps << MkId(var_id) << MkNum(spv::DecorationDescriptorSet)
         << MkNum(descriptor_set);
    SPIRVInstList.insert(DecoInsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, DOps));
  }
}

void SPIRVProducerPass::GenerateWorkgroupVars() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  for (auto spec_id = clspv::FirstLocalSpecId(); spec_id < max_local_spec_id_;
       ++spec_id) {
    LocalArgInfo &info = LocalSpecIdInfoMap[spec_id];

    // Generate OpVariable.
    //
    // GIDOps[0] : Result Type ID
    // GIDOps[1] : Storage Class
    SPIRVOperandList Ops;
    Ops << MkId(info.ptr_array_type_id) << MkNum(spv::StorageClassWorkgroup);

    SPIRVInstList.push_back(
        new SPIRVInstruction(spv::OpVariable, info.variable_id, Ops));
  }
}

void SPIRVProducerPass::GenerateDescriptorMapInfo(const DataLayout &DL,
                                                  Function &F) {
  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
    return;
  }
  // Gather the list of resources that are used by this function's arguments.
  auto &resource_var_at_index = FunctionToResourceVarsMap[&F];

  // TODO(alan-baker): This should become unnecessary by fixing the rest of the
  // flow to generate pod_ubo arguments earlier.
  auto remap_arg_kind = [](StringRef argKind) {
    std::string kind =
        clspv::Option::PodArgsInUniformBuffer() && argKind.equals("pod")
            ? "pod_ubo"
            : argKind;
    return GetArgKindFromName(kind);
  };

  auto *fty = F.getType()->getPointerElementType();
  auto *func_ty = dyn_cast<FunctionType>(fty);

  // If we've clustered POD arguments, then argument details are in metadata.
  // If an argument maps to a resource variable, then get descriptor set and
  // binding from the resoure variable.  Other info comes from the metadata.
  const auto *arg_map = F.getMetadata("kernel_arg_map");
  if (arg_map) {
    for (const auto &arg : arg_map->operands()) {
      const MDNode *arg_node = dyn_cast<MDNode>(arg.get());
      assert(arg_node->getNumOperands() == 7);
      const auto name =
          dyn_cast<MDString>(arg_node->getOperand(0))->getString();
      const auto old_index =
          dyn_extract<ConstantInt>(arg_node->getOperand(1))->getZExtValue();
      // Remapped argument index
      const size_t new_index = static_cast<size_t>(
          dyn_extract<ConstantInt>(arg_node->getOperand(2))->getZExtValue());
      const auto offset =
          dyn_extract<ConstantInt>(arg_node->getOperand(3))->getZExtValue();
      const auto arg_size =
          dyn_extract<ConstantInt>(arg_node->getOperand(4))->getZExtValue();
      const auto argKind = remap_arg_kind(
          dyn_cast<MDString>(arg_node->getOperand(5))->getString());
      const auto spec_id =
          dyn_extract<ConstantInt>(arg_node->getOperand(6))->getSExtValue();

      uint32_t descriptor_set = 0;
      uint32_t binding = 0;
      version0::DescriptorMapEntry::KernelArgData kernel_data = {
          F.getName(), name, static_cast<uint32_t>(old_index), argKind,
          static_cast<uint32_t>(spec_id),
          // This will be set below for pointer-to-local args.
          0, static_cast<uint32_t>(offset), static_cast<uint32_t>(arg_size)};
      if (spec_id > 0) {
        kernel_data.local_element_size = static_cast<uint32_t>(GetTypeAllocSize(
            func_ty->getParamType(unsigned(new_index))->getPointerElementType(),
            DL));
      } else {
        auto *info = resource_var_at_index[new_index];
        assert(info);
        descriptor_set = info->descriptor_set;
        binding = info->binding;
      }
      descriptorMapEntries->emplace_back(std::move(kernel_data), descriptor_set,
                                         binding);
    }
  } else {
    // There is no argument map.
    // Take descriptor info from the resource variable calls.
    // Take argument name and size from the arguments list.

    SmallVector<Argument *, 4> arguments;
    for (auto &arg : F.args()) {
      arguments.push_back(&arg);
    }

    unsigned arg_index = 0;
    for (auto *info : resource_var_at_index) {
      if (info) {
        auto arg = arguments[arg_index];
        unsigned arg_size = 0;
        if (info->arg_kind == clspv::ArgKind::Pod) {
          arg_size = static_cast<uint32_t>(DL.getTypeStoreSize(arg->getType()));
        }

        // Local pointer arguments are unused in this case. Offset is always
        // zero.
        version0::DescriptorMapEntry::KernelArgData kernel_data = {
            F.getName(), arg->getName(),
            arg_index,   remap_arg_kind(clspv::GetArgKindName(info->arg_kind)),
            0,           0,
            0,           arg_size};
        descriptorMapEntries->emplace_back(std::move(kernel_data),
                                           info->descriptor_set, info->binding);
      }
      arg_index++;
    }
    // Generate mappings for pointer-to-local arguments.
    for (arg_index = 0; arg_index < arguments.size(); ++arg_index) {
      Argument *arg = arguments[arg_index];
      auto where = LocalArgSpecIds.find(arg);
      if (where != LocalArgSpecIds.end()) {
        auto &local_arg_info = LocalSpecIdInfoMap[where->second];
        // Pod arguments members are unused in this case.
        version0::DescriptorMapEntry::KernelArgData kernel_data = {
            F.getName(),
            arg->getName(),
            arg_index,
            ArgKind::Local,
            static_cast<uint32_t>(local_arg_info.spec_id),
            static_cast<uint32_t>(
                GetTypeAllocSize(local_arg_info.elem_type, DL)),
            0,
            0};
        // Pointer-to-local arguments do not utilize descriptor set and binding.
        descriptorMapEntries->emplace_back(std::move(kernel_data), 0, 0);
      }
    }
  }
}

void SPIRVProducerPass::GenerateFuncPrologue(Function &F) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  EntryPointVecType &EntryPoints = getEntryPointVec();
  auto &GlobalConstFuncTyMap = getGlobalConstFuncTypeMap();
  auto &GlobalConstArgSet = getGlobalConstArgSet();

  FunctionType *FTy = F.getFunctionType();

  //
  // Generate OPFunction.
  //

  // FOps[0] : Result Type ID
  // FOps[1] : Function Control
  // FOps[2] : Function Type ID
  SPIRVOperandList FOps;

  // Find SPIRV instruction for return type.
  FOps << MkId(lookupType(FTy->getReturnType()));

  // Check function attributes for SPIRV Function Control.
  uint32_t FuncControl = spv::FunctionControlMaskNone;
  if (F.hasFnAttribute(Attribute::AlwaysInline)) {
    FuncControl |= spv::FunctionControlInlineMask;
  }
  if (F.hasFnAttribute(Attribute::NoInline)) {
    FuncControl |= spv::FunctionControlDontInlineMask;
  }
  // TODO: Check llvm attribute for Function Control Pure.
  if (F.hasFnAttribute(Attribute::ReadOnly)) {
    FuncControl |= spv::FunctionControlPureMask;
  }
  // TODO: Check llvm attribute for Function Control Const.
  if (F.hasFnAttribute(Attribute::ReadNone)) {
    FuncControl |= spv::FunctionControlConstMask;
  }

  FOps << MkNum(FuncControl);

  uint32_t FTyID;
  if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
    SmallVector<Type *, 4> NewFuncParamTys;
    FunctionType *NewFTy =
        FunctionType::get(FTy->getReturnType(), NewFuncParamTys, false);
    FTyID = lookupType(NewFTy);
  } else {
    // Handle regular function with global constant parameters.
    if (GlobalConstFuncTyMap.count(FTy)) {
      FTyID = lookupType(GlobalConstFuncTyMap[FTy].first);
    } else {
      FTyID = lookupType(FTy);
    }
  }

  FOps << MkId(FTyID);

  if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
    EntryPoints.push_back(std::make_pair(&F, nextID));
  }

  VMap[&F] = nextID;

  if (clspv::Option::ShowIDs()) {
    errs() << "Function " << F.getName() << " is " << nextID << "\n";
  }
  // Generate SPIRV instruction for function.
  auto *FuncInst = new SPIRVInstruction(spv::OpFunction, nextID++, FOps);
  SPIRVInstList.push_back(FuncInst);

  //
  // Generate OpFunctionParameter for Normal function.
  //

  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {

    // Find Insert Point for OpDecorate.
    auto DecoInsertPoint =
        std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                     [](SPIRVInstruction *Inst) -> bool {
                       return Inst->getOpcode() != spv::OpDecorate &&
                              Inst->getOpcode() != spv::OpMemberDecorate &&
                              Inst->getOpcode() != spv::OpExtInstImport;
                     });

    // Iterate Argument for name instead of param type from function type.
    unsigned ArgIdx = 0;
    for (Argument &Arg : F.args()) {
      uint32_t param_id = nextID++;
      VMap[&Arg] = param_id;

      if (CalledWithCoherentResource(Arg)) {
        // If the arg is passed a coherent resource ever, then decorate this
        // parameter with Coherent too.
        SPIRVOperandList decoration_ops;
        decoration_ops << MkId(param_id) << MkNum(spv::DecorationCoherent);
        SPIRVInstList.insert(
            DecoInsertPoint,
            new SPIRVInstruction(spv::OpDecorate, decoration_ops));
      }

      // ParamOps[0] : Result Type ID
      SPIRVOperandList ParamOps;

      // Find SPIRV instruction for parameter type.
      uint32_t ParamTyID = lookupType(Arg.getType());
      if (PointerType *PTy = dyn_cast<PointerType>(Arg.getType())) {
        if (GlobalConstFuncTyMap.count(FTy)) {
          if (ArgIdx == GlobalConstFuncTyMap[FTy].second) {
            Type *EleTy = PTy->getPointerElementType();
            Type *ArgTy =
                PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);
            ParamTyID = lookupType(ArgTy);
            GlobalConstArgSet.insert(&Arg);
          }
        }
      }
      ParamOps << MkId(ParamTyID);

      // Generate SPIRV instruction for parameter.
      auto *ParamInst =
          new SPIRVInstruction(spv::OpFunctionParameter, param_id, ParamOps);
      SPIRVInstList.push_back(ParamInst);

      ArgIdx++;
    }
  }
}

void SPIRVProducerPass::GenerateModuleInfo(Module &module) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  EntryPointVecType &EntryPoints = getEntryPointVec();
  ValueMapType &VMap = getValueMap();
  ValueList &EntryPointInterfaces = getEntryPointInterfacesVec();
  uint32_t &ExtInstImportID = getOpExtInstImportID();
  std::vector<uint32_t> &BuiltinDimVec = getBuiltinDimVec();

  // Set up insert point.
  auto InsertPoint = SPIRVInstList.begin();

  //
  // Generate OpCapability
  //
  // TODO: Which llvm information is mapped to SPIRV Capapbility?

  // Ops[0] = Capability
  SPIRVOperandList Ops;

  auto *CapInst =
      new SPIRVInstruction(spv::OpCapability, {MkNum(spv::CapabilityShader)});
  SPIRVInstList.insert(InsertPoint, CapInst);

  for (Type *Ty : getTypeList()) {
    if (clspv::Option::Int8Support() && Ty->isIntegerTy(8)) {
      // Generate OpCapability for i8 type.
      SPIRVInstList.insert(InsertPoint,
                           new SPIRVInstruction(spv::OpCapability,
                                                {MkNum(spv::CapabilityInt8)}));
    } else if (Ty->isIntegerTy(16)) {
      // Generate OpCapability for i16 type.
      SPIRVInstList.insert(InsertPoint,
                           new SPIRVInstruction(spv::OpCapability,
                                                {MkNum(spv::CapabilityInt16)}));
    } else if (Ty->isIntegerTy(64)) {
      // Generate OpCapability for i64 type.
      SPIRVInstList.insert(InsertPoint,
                           new SPIRVInstruction(spv::OpCapability,
                                                {MkNum(spv::CapabilityInt64)}));
    } else if (Ty->isHalfTy()) {
      // Generate OpCapability for half type.
      SPIRVInstList.insert(
          InsertPoint, new SPIRVInstruction(spv::OpCapability,
                                            {MkNum(spv::CapabilityFloat16)}));
    } else if (Ty->isDoubleTy()) {
      // Generate OpCapability for double type.
      SPIRVInstList.insert(
          InsertPoint, new SPIRVInstruction(spv::OpCapability,
                                            {MkNum(spv::CapabilityFloat64)}));
    } else if (auto *STy = dyn_cast<StructType>(Ty)) {
      if (STy->isOpaque()) {
        if (STy->getName().equals("opencl.image2d_wo_t") ||
            STy->getName().equals("opencl.image3d_wo_t")) {
          // Generate OpCapability for write only image type.
          SPIRVInstList.insert(
              InsertPoint,
              new SPIRVInstruction(
                  spv::OpCapability,
                  {MkNum(spv::CapabilityStorageImageWriteWithoutFormat)}));
        }
      }
    }
  }

  { // OpCapability ImageQuery
    bool hasImageQuery = false;
    for (const char *imageQuery : {
             "_Z15get_image_width14ocl_image2d_ro",
             "_Z15get_image_width14ocl_image2d_wo",
             "_Z16get_image_height14ocl_image2d_ro",
             "_Z16get_image_height14ocl_image2d_wo",
         }) {
      if (module.getFunction(imageQuery)) {
        hasImageQuery = true;
        break;
      }
    }
    if (hasImageQuery) {
      auto *ImageQueryCapInst = new SPIRVInstruction(
          spv::OpCapability, {MkNum(spv::CapabilityImageQuery)});
      SPIRVInstList.insert(InsertPoint, ImageQueryCapInst);
    }
  }

  if (hasVariablePointers()) {
    //
    // Generate OpCapability.
    //
    // Ops[0] = Capability
    //
    Ops.clear();
    Ops << MkNum(spv::CapabilityVariablePointers);

    SPIRVInstList.insert(InsertPoint,
                         new SPIRVInstruction(spv::OpCapability, Ops));
  } else if (hasVariablePointersStorageBuffer()) {
    //
    // Generate OpCapability.
    //
    // Ops[0] = Capability
    //
    Ops.clear();
    Ops << MkNum(spv::CapabilityVariablePointersStorageBuffer);

    SPIRVInstList.insert(InsertPoint,
                         new SPIRVInstruction(spv::OpCapability, Ops));
  }

  // Always add the storage buffer extension
  {
    //
    // Generate OpExtension.
    //
    // Ops[0] = Name (Literal String)
    //
    auto *ExtensionInst = new SPIRVInstruction(
        spv::OpExtension, {MkString("SPV_KHR_storage_buffer_storage_class")});
    SPIRVInstList.insert(InsertPoint, ExtensionInst);
  }

  if (hasVariablePointers() || hasVariablePointersStorageBuffer()) {
    //
    // Generate OpExtension.
    //
    // Ops[0] = Name (Literal String)
    //
    auto *ExtensionInst = new SPIRVInstruction(
        spv::OpExtension, {MkString("SPV_KHR_variable_pointers")});
    SPIRVInstList.insert(InsertPoint, ExtensionInst);
  }

  if (ExtInstImportID) {
    ++InsertPoint;
  }

  //
  // Generate OpMemoryModel
  //
  // Memory model for Vulkan will always be GLSL450.

  // Ops[0] = Addressing Model
  // Ops[1] = Memory Model
  Ops.clear();
  Ops << MkNum(spv::AddressingModelLogical) << MkNum(spv::MemoryModelGLSL450);

  auto *MemModelInst = new SPIRVInstruction(spv::OpMemoryModel, Ops);
  SPIRVInstList.insert(InsertPoint, MemModelInst);

  //
  // Generate OpEntryPoint
  //
  for (auto EntryPoint : EntryPoints) {
    // Ops[0] = Execution Model
    // Ops[1] = EntryPoint ID
    // Ops[2] = Name (Literal String)
    // ...
    //
    // TODO: Do we need to consider Interface ID for forward references???
    Ops.clear();
    const StringRef &name = EntryPoint.first->getName();
    Ops << MkNum(spv::ExecutionModelGLCompute) << MkId(EntryPoint.second)
        << MkString(name);

    for (Value *Interface : EntryPointInterfaces) {
      Ops << MkId(VMap[Interface]);
    }

    auto *EntryPointInst = new SPIRVInstruction(spv::OpEntryPoint, Ops);
    SPIRVInstList.insert(InsertPoint, EntryPointInst);
  }

  for (auto EntryPoint : EntryPoints) {
    if (const MDNode *MD = dyn_cast<Function>(EntryPoint.first)
                               ->getMetadata("reqd_work_group_size")) {

      if (!BuiltinDimVec.empty()) {
        llvm_unreachable(
            "Kernels should have consistent work group size definition");
      }

      //
      // Generate OpExecutionMode
      //

      // Ops[0] = Entry Point ID
      // Ops[1] = Execution Mode
      // Ops[2] ... Ops[n] = Optional literals according to Execution Mode
      Ops.clear();
      Ops << MkId(EntryPoint.second) << MkNum(spv::ExecutionModeLocalSize);

      uint32_t XDim = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(0))->getZExtValue());
      uint32_t YDim = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(1))->getZExtValue());
      uint32_t ZDim = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(2))->getZExtValue());

      Ops << MkNum(XDim) << MkNum(YDim) << MkNum(ZDim);

      auto *ExecModeInst = new SPIRVInstruction(spv::OpExecutionMode, Ops);
      SPIRVInstList.insert(InsertPoint, ExecModeInst);
    }
  }

  //
  // Generate OpSource.
  //
  // Ops[0] = SourceLanguage ID
  // Ops[1] = Version (LiteralNum)
  //
  Ops.clear();
  if (clspv::Option::CPlusPlus()) {
    Ops << MkNum(spv::SourceLanguageOpenCL_CPP) << MkNum(100);
  } else {
    Ops << MkNum(spv::SourceLanguageOpenCL_C) << MkNum(120);
  }

  auto *OpenSourceInst = new SPIRVInstruction(spv::OpSource, Ops);
  SPIRVInstList.insert(InsertPoint, OpenSourceInst);

  if (!BuiltinDimVec.empty()) {
    //
    // Generate OpDecorates for x/y/z dimension.
    //
    // Ops[0] = Target ID
    // Ops[1] = Decoration (SpecId)
    // Ops[2] = Specialization Constant ID (Literal Number)

    // X Dimension
    Ops.clear();
    Ops << MkId(BuiltinDimVec[0]) << MkNum(spv::DecorationSpecId) << MkNum(0);
    SPIRVInstList.insert(InsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));

    // Y Dimension
    Ops.clear();
    Ops << MkId(BuiltinDimVec[1]) << MkNum(spv::DecorationSpecId) << MkNum(1);
    SPIRVInstList.insert(InsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));

    // Z Dimension
    Ops.clear();
    Ops << MkId(BuiltinDimVec[2]) << MkNum(spv::DecorationSpecId) << MkNum(2);
    SPIRVInstList.insert(InsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));
  }
}

void SPIRVProducerPass::GenerateEntryPointInitialStores() {
  // Work around a driver bug.  Initializers on Private variables might not
  // work. So the start of the kernel should store the initializer value to the
  // variables.  Yes, *every* entry point pays this cost if *any* entry point
  // uses this builtin.  At this point I judge this to be an acceptable tradeoff
  // of complexity vs. runtime, for a broken driver.
  // TODO(dneto): Remove this at some point once fixed drivers are widely
  // available.
  if (WorkgroupSizeVarID) {
    assert(WorkgroupSizeValueID);

    SPIRVOperandList Ops;
    Ops << MkId(WorkgroupSizeVarID) << MkId(WorkgroupSizeValueID);

    auto *Inst = new SPIRVInstruction(spv::OpStore, Ops);
    getSPIRVInstList().push_back(Inst);
  }
}

void SPIRVProducerPass::GenerateFuncBody(Function &F) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();

  const bool IsKernel = F.getCallingConv() == CallingConv::SPIR_KERNEL;

  for (BasicBlock &BB : F) {
    // Register BasicBlock to ValueMap.
    VMap[&BB] = nextID;

    //
    // Generate OpLabel for Basic Block.
    //
    SPIRVOperandList Ops;
    auto *Inst = new SPIRVInstruction(spv::OpLabel, nextID++, Ops);
    SPIRVInstList.push_back(Inst);

    // OpVariable instructions must come first.
    for (Instruction &I : BB) {
      if (auto *alloca = dyn_cast<AllocaInst>(&I)) {
        // Allocating a pointer requires variable pointers.
        if (alloca->getAllocatedType()->isPointerTy()) {
          setVariablePointersCapabilities(
              alloca->getAllocatedType()->getPointerAddressSpace());
        }
        GenerateInstruction(I);
      }
    }

    if (&BB == &F.getEntryBlock() && IsKernel) {
      if (clspv::Option::HackInitializers()) {
        GenerateEntryPointInitialStores();
      }
    }

    for (Instruction &I : BB) {
      if (!isa<AllocaInst>(I)) {
        GenerateInstruction(I);
      }
    }
  }
}

spv::Op SPIRVProducerPass::GetSPIRVCmpOpcode(CmpInst *I) {
  const std::map<CmpInst::Predicate, spv::Op> Map = {
      {CmpInst::ICMP_EQ, spv::OpIEqual},
      {CmpInst::ICMP_NE, spv::OpINotEqual},
      {CmpInst::ICMP_UGT, spv::OpUGreaterThan},
      {CmpInst::ICMP_UGE, spv::OpUGreaterThanEqual},
      {CmpInst::ICMP_ULT, spv::OpULessThan},
      {CmpInst::ICMP_ULE, spv::OpULessThanEqual},
      {CmpInst::ICMP_SGT, spv::OpSGreaterThan},
      {CmpInst::ICMP_SGE, spv::OpSGreaterThanEqual},
      {CmpInst::ICMP_SLT, spv::OpSLessThan},
      {CmpInst::ICMP_SLE, spv::OpSLessThanEqual},
      {CmpInst::FCMP_OEQ, spv::OpFOrdEqual},
      {CmpInst::FCMP_OGT, spv::OpFOrdGreaterThan},
      {CmpInst::FCMP_OGE, spv::OpFOrdGreaterThanEqual},
      {CmpInst::FCMP_OLT, spv::OpFOrdLessThan},
      {CmpInst::FCMP_OLE, spv::OpFOrdLessThanEqual},
      {CmpInst::FCMP_ONE, spv::OpFOrdNotEqual},
      {CmpInst::FCMP_UEQ, spv::OpFUnordEqual},
      {CmpInst::FCMP_UGT, spv::OpFUnordGreaterThan},
      {CmpInst::FCMP_UGE, spv::OpFUnordGreaterThanEqual},
      {CmpInst::FCMP_ULT, spv::OpFUnordLessThan},
      {CmpInst::FCMP_ULE, spv::OpFUnordLessThanEqual},
      {CmpInst::FCMP_UNE, spv::OpFUnordNotEqual}};

  assert(0 != Map.count(I->getPredicate()));

  return Map.at(I->getPredicate());
}

spv::Op SPIRVProducerPass::GetSPIRVCastOpcode(Instruction &I) {
  const std::map<unsigned, spv::Op> Map{
      {Instruction::Trunc, spv::OpUConvert},
      {Instruction::ZExt, spv::OpUConvert},
      {Instruction::SExt, spv::OpSConvert},
      {Instruction::FPToUI, spv::OpConvertFToU},
      {Instruction::FPToSI, spv::OpConvertFToS},
      {Instruction::UIToFP, spv::OpConvertUToF},
      {Instruction::SIToFP, spv::OpConvertSToF},
      {Instruction::FPTrunc, spv::OpFConvert},
      {Instruction::FPExt, spv::OpFConvert},
      {Instruction::BitCast, spv::OpBitcast}};

  assert(0 != Map.count(I.getOpcode()));

  return Map.at(I.getOpcode());
}

spv::Op SPIRVProducerPass::GetSPIRVBinaryOpcode(Instruction &I) {
  if (I.getType()->isIntOrIntVectorTy(1)) {
    switch (I.getOpcode()) {
    default:
      break;
    case Instruction::Or:
      return spv::OpLogicalOr;
    case Instruction::And:
      return spv::OpLogicalAnd;
    case Instruction::Xor:
      return spv::OpLogicalNotEqual;
    }
  }

  const std::map<unsigned, spv::Op> Map{
      {Instruction::Add, spv::OpIAdd},
      {Instruction::FAdd, spv::OpFAdd},
      {Instruction::Sub, spv::OpISub},
      {Instruction::FSub, spv::OpFSub},
      {Instruction::Mul, spv::OpIMul},
      {Instruction::FMul, spv::OpFMul},
      {Instruction::UDiv, spv::OpUDiv},
      {Instruction::SDiv, spv::OpSDiv},
      {Instruction::FDiv, spv::OpFDiv},
      {Instruction::URem, spv::OpUMod},
      {Instruction::SRem, spv::OpSRem},
      {Instruction::FRem, spv::OpFRem},
      {Instruction::Or, spv::OpBitwiseOr},
      {Instruction::Xor, spv::OpBitwiseXor},
      {Instruction::And, spv::OpBitwiseAnd},
      {Instruction::Shl, spv::OpShiftLeftLogical},
      {Instruction::LShr, spv::OpShiftRightLogical},
      {Instruction::AShr, spv::OpShiftRightArithmetic}};

  assert(0 != Map.count(I.getOpcode()));

  return Map.at(I.getOpcode());
}

void SPIRVProducerPass::GenerateInstruction(Instruction &I) {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  DeferredInstVecType &DeferredInsts = getDeferredInstVec();
  LLVMContext &Context = I.getParent()->getParent()->getParent()->getContext();

  // Register Instruction to ValueMap.
  if (0 == VMap[&I]) {
    VMap[&I] = nextID;
  }

  switch (I.getOpcode()) {
  default: {
    if (Instruction::isCast(I.getOpcode())) {
      //
      // Generate SPIRV instructions for cast operators.
      //

      auto Ty = I.getType();
      auto OpTy = I.getOperand(0)->getType();
      auto toI8 = Ty == Type::getInt8Ty(Context);
      auto fromI32 = OpTy == Type::getInt32Ty(Context);
      // Handle zext, sext and uitofp with i1 type specially.
      if ((I.getOpcode() == Instruction::ZExt ||
           I.getOpcode() == Instruction::SExt ||
           I.getOpcode() == Instruction::UIToFP) &&
          OpTy->isIntOrIntVectorTy(1)) {
        //
        // Generate OpSelect.
        //

        // Ops[0] = Result Type ID
        // Ops[1] = Condition ID
        // Ops[2] = True Constant ID
        // Ops[3] = False Constant ID
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType()));

        uint32_t CondID = VMap[I.getOperand(0)];
        Ops << MkId(CondID);

        uint32_t TrueID = 0;
        if (I.getOpcode() == Instruction::ZExt) {
          TrueID = VMap[ConstantInt::get(I.getType(), 1)];
        } else if (I.getOpcode() == Instruction::SExt) {
          TrueID = VMap[ConstantInt::getSigned(I.getType(), -1)];
        } else {
          TrueID = VMap[ConstantFP::get(Context, APFloat(1.0f))];
        }
        Ops << MkId(TrueID);

        uint32_t FalseID = 0;
        if (I.getOpcode() == Instruction::ZExt) {
          FalseID = VMap[Constant::getNullValue(I.getType())];
        } else if (I.getOpcode() == Instruction::SExt) {
          FalseID = VMap[Constant::getNullValue(I.getType())];
        } else {
          FalseID = VMap[ConstantFP::get(Context, APFloat(0.0f))];
        }
        Ops << MkId(FalseID);

        auto *Inst = new SPIRVInstruction(spv::OpSelect, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      } else if (!clspv::Option::Int8Support() &&
                 I.getOpcode() == Instruction::Trunc && fromI32 && toI8) {
        // The SPIR-V target type is a 32-bit int.  Keep only the bottom
        // 8 bits.
        // Before:
        //   %result = trunc i32 %a to i8
        // After
        //   %result = OpBitwiseAnd %uint %a %uint_255

        SPIRVOperandList Ops;

        Ops << MkId(lookupType(OpTy)) << MkId(VMap[I.getOperand(0)]);

        Type *UintTy = Type::getInt32Ty(Context);
        uint32_t MaskID = VMap[ConstantInt::get(UintTy, 255)];
        Ops << MkId(MaskID);

        auto *Inst = new SPIRVInstruction(spv::OpBitwiseAnd, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Source Value ID
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType())) << MkId(VMap[I.getOperand(0)]);

        auto *Inst = new SPIRVInstruction(GetSPIRVCastOpcode(I), nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      }
    } else if (isa<BinaryOperator>(I)) {
      //
      // Generate SPIRV instructions for binary operators.
      //

      // Handle xor with i1 type specially.
      if (I.getOpcode() == Instruction::Xor &&
          I.getType() == Type::getInt1Ty(Context) &&
          ((isa<ConstantInt>(I.getOperand(0)) &&
            !cast<ConstantInt>(I.getOperand(0))->isZero()) ||
           (isa<ConstantInt>(I.getOperand(1)) &&
            !cast<ConstantInt>(I.getOperand(1))->isZero()))) {
        //
        // Generate OpLogicalNot.
        //
        // Ops[0] = Result Type ID
        // Ops[1] = Operand
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType()));

        Value *CondV = I.getOperand(0);
        if (isa<Constant>(I.getOperand(0))) {
          CondV = I.getOperand(1);
        }
        Ops << MkId(VMap[CondV]);

        auto *Inst = new SPIRVInstruction(spv::OpLogicalNot, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Operand 0
        // Ops[2] = Operand 1
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType())) << MkId(VMap[I.getOperand(0)])
            << MkId(VMap[I.getOperand(1)]);

        auto *Inst =
            new SPIRVInstruction(GetSPIRVBinaryOpcode(I), nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      }
    } else {
      I.print(errs());
      llvm_unreachable("Unsupported instruction???");
    }
    break;
  }
  case Instruction::GetElementPtr: {
    auto &GlobalConstArgSet = getGlobalConstArgSet();

    //
    // Generate OpAccessChain.
    //
    GetElementPtrInst *GEP = cast<GetElementPtrInst>(&I);

    //
    // Generate OpAccessChain.
    //

    // Ops[0] = Result Type ID
    // Ops[1] = Base ID
    // Ops[2] ... Ops[n] = Indexes ID
    SPIRVOperandList Ops;

    PointerType *ResultType = cast<PointerType>(GEP->getType());
    if (GEP->getPointerAddressSpace() == AddressSpace::ModuleScopePrivate ||
        GlobalConstArgSet.count(GEP->getPointerOperand())) {
      // Use pointer type with private address space for global constant.
      Type *EleTy = I.getType()->getPointerElementType();
      ResultType = PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);
    }

    Ops << MkId(lookupType(ResultType));

    // Generate the base pointer.
    Ops << MkId(VMap[GEP->getPointerOperand()]);

    // TODO(dneto): Simplify the following?

    //
    // Follows below rules for gep.
    //
    // 1. If gep's first index is 0 generate OpAccessChain and ignore gep's
    //    first index.
    // 2. If gep's first index is not 0, generate OpPtrAccessChain and use gep's
    //    first index.
    // 3. If gep's first index is not constant, generate OpPtrAccessChain and
    //    use gep's first index.
    // 4. If it is not above case 1, 2 and 3, generate OpAccessChain and use
    //    gep's first index.
    //
    spv::Op Opcode = spv::OpAccessChain;
    unsigned offset = 0;
    if (ConstantInt *CstInt = dyn_cast<ConstantInt>(GEP->getOperand(1))) {
      if (CstInt->getZExtValue() == 0) {
        offset = 1;
      } else if (CstInt->getZExtValue() != 0) {
        Opcode = spv::OpPtrAccessChain;
      }
    } else {
      Opcode = spv::OpPtrAccessChain;
    }

    if (Opcode == spv::OpPtrAccessChain) {
      // Do we need to generate ArrayStride?  Check against the GEP result type
      // rather than the pointer type of the base because when indexing into
      // an OpenCL program-scope constant, we'll swap out the LLVM base pointer
      // for something else in the SPIR-V.
      // E.g. see test/PointerAccessChain/pointer_index_is_constant_1.cl
      auto address_space = ResultType->getAddressSpace();
      setVariablePointersCapabilities(address_space);
      switch (GetStorageClass(address_space)) {
      case spv::StorageClassStorageBuffer:
      case spv::StorageClassUniform:
        // Save the need to generate an ArrayStride decoration.  But defer
        // generation until later, so we only make one decoration.
        getTypesNeedingArrayStride().insert(ResultType);
        break;
      default:
        break;
      }
    }

    for (auto II = GEP->idx_begin() + offset; II != GEP->idx_end(); II++) {
      Ops << MkId(VMap[*II]);
    }

    auto *Inst = new SPIRVInstruction(Opcode, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::ExtractValue: {
    ExtractValueInst *EVI = cast<ExtractValueInst>(&I);
    // Ops[0] = Result Type ID
    // Ops[1] = Composite ID
    // Ops[2] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(I.getType()));

    uint32_t CompositeID = VMap[EVI->getAggregateOperand()];
    Ops << MkId(CompositeID);

    for (auto &Index : EVI->indices()) {
      Ops << MkNum(Index);
    }

    auto *Inst = new SPIRVInstruction(spv::OpCompositeExtract, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::InsertValue: {
    InsertValueInst *IVI = cast<InsertValueInst>(&I);
    // Ops[0] = Result Type ID
    // Ops[1] = Object ID
    // Ops[2] = Composite ID
    // Ops[3] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandList Ops;

    uint32_t ResTyID = lookupType(I.getType());
    Ops << MkId(ResTyID);

    uint32_t ObjectID = VMap[IVI->getInsertedValueOperand()];
    Ops << MkId(ObjectID);

    uint32_t CompositeID = VMap[IVI->getAggregateOperand()];
    Ops << MkId(CompositeID);

    for (auto &Index : IVI->indices()) {
      Ops << MkNum(Index);
    }

    auto *Inst = new SPIRVInstruction(spv::OpCompositeInsert, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::Select: {
    //
    // Generate OpSelect.
    //

    // Ops[0] = Result Type ID
    // Ops[1] = Condition ID
    // Ops[2] = True Constant ID
    // Ops[3] = False Constant ID
    SPIRVOperandList Ops;

    // Find SPIRV instruction for parameter type.
    auto Ty = I.getType();
    if (Ty->isPointerTy()) {
      auto PointeeTy = Ty->getPointerElementType();
      if (PointeeTy->isStructTy() &&
          dyn_cast<StructType>(PointeeTy)->isOpaque()) {
        Ty = PointeeTy;
      } else {
        // Selecting between pointers requires variable pointers.
        setVariablePointersCapabilities(Ty->getPointerAddressSpace());
        if (!hasVariablePointers() && !selectFromSameObject(&I)) {
          setVariablePointers(true);
        }
      }
    }

    Ops << MkId(lookupType(Ty)) << MkId(VMap[I.getOperand(0)])
        << MkId(VMap[I.getOperand(1)]) << MkId(VMap[I.getOperand(2)]);

    auto *Inst = new SPIRVInstruction(spv::OpSelect, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::ExtractElement: {
    // Handle <4 x i8> type manually.
    Type *CompositeTy = I.getOperand(0)->getType();
    if (is4xi8vec(CompositeTy)) {
      //
      // Generate OpShiftRightLogical and OpBitwiseAnd for extractelement with
      // <4 x i8>.
      //

      //
      // Generate OpShiftRightLogical
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Operand 0
      // Ops[2] = Operand 1
      //
      SPIRVOperandList Ops;

      Ops << MkId(lookupType(CompositeTy));

      uint32_t Op0ID = VMap[I.getOperand(0)];
      Ops << MkId(Op0ID);

      uint32_t Op1ID = 0;
      if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1))) {
        // Handle constant index.
        uint64_t Idx = CI->getZExtValue();
        Value *ShiftAmount =
            ConstantInt::get(Type::getInt32Ty(Context), Idx * 8);
        Op1ID = VMap[ShiftAmount];
      } else {
        // Handle variable index.
        SPIRVOperandList TmpOps;

        TmpOps << MkId(lookupType(Type::getInt32Ty(Context)))
               << MkId(VMap[I.getOperand(1)]);

        ConstantInt *Cst8 = ConstantInt::get(Type::getInt32Ty(Context), 8);
        TmpOps << MkId(VMap[Cst8]);

        Op1ID = nextID;

        auto *TmpInst = new SPIRVInstruction(spv::OpIMul, nextID++, TmpOps);
        SPIRVInstList.push_back(TmpInst);
      }
      Ops << MkId(Op1ID);

      uint32_t ShiftID = nextID;

      auto *Inst =
          new SPIRVInstruction(spv::OpShiftRightLogical, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      //
      // Generate OpBitwiseAnd
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Operand 0
      // Ops[2] = Operand 1
      //
      Ops.clear();

      Ops << MkId(lookupType(CompositeTy)) << MkId(ShiftID);

      Constant *CstFF = ConstantInt::get(Type::getInt32Ty(Context), 0xFF);
      Ops << MkId(VMap[CstFF]);

      // Reset mapping for this value to the result of the bitwise and.
      VMap[&I] = nextID;

      Inst = new SPIRVInstruction(spv::OpBitwiseAnd, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // Ops[0] = Result Type ID
    // Ops[1] = Composite ID
    // Ops[2] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(I.getType())) << MkId(VMap[I.getOperand(0)]);

    spv::Op Opcode = spv::OpCompositeExtract;
    if (const ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1))) {
      Ops << MkNum(static_cast<uint32_t>(CI->getZExtValue()));
    } else {
      Ops << MkId(VMap[I.getOperand(1)]);
      Opcode = spv::OpVectorExtractDynamic;
    }

    auto *Inst = new SPIRVInstruction(Opcode, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::InsertElement: {
    // Handle <4 x i8> type manually.
    Type *CompositeTy = I.getOperand(0)->getType();
    if (is4xi8vec(CompositeTy)) {
      Constant *CstFF = ConstantInt::get(Type::getInt32Ty(Context), 0xFF);
      uint32_t CstFFID = VMap[CstFF];

      uint32_t ShiftAmountID = 0;
      if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2))) {
        // Handle constant index.
        uint64_t Idx = CI->getZExtValue();
        Value *ShiftAmount =
            ConstantInt::get(Type::getInt32Ty(Context), Idx * 8);
        ShiftAmountID = VMap[ShiftAmount];
      } else {
        // Handle variable index.
        SPIRVOperandList TmpOps;

        TmpOps << MkId(lookupType(Type::getInt32Ty(Context)))
               << MkId(VMap[I.getOperand(2)]);

        ConstantInt *Cst8 = ConstantInt::get(Type::getInt32Ty(Context), 8);
        TmpOps << MkId(VMap[Cst8]);

        ShiftAmountID = nextID;

        auto *TmpInst = new SPIRVInstruction(spv::OpIMul, nextID++, TmpOps);
        SPIRVInstList.push_back(TmpInst);
      }

      //
      // Generate mask operations.
      //

      // ShiftLeft mask according to index of insertelement.
      SPIRVOperandList Ops;

      const uint32_t ResTyID = lookupType(CompositeTy);
      Ops << MkId(ResTyID) << MkId(CstFFID) << MkId(ShiftAmountID);

      uint32_t MaskID = nextID;

      auto *Inst = new SPIRVInstruction(spv::OpShiftLeftLogical, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      // Inverse mask.
      Ops.clear();
      Ops << MkId(ResTyID) << MkId(MaskID);

      uint32_t InvMaskID = nextID;

      Inst = new SPIRVInstruction(spv::OpNot, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      // Apply mask.
      Ops.clear();
      Ops << MkId(ResTyID) << MkId(VMap[I.getOperand(0)]) << MkId(InvMaskID);

      uint32_t OrgValID = nextID;

      Inst = new SPIRVInstruction(spv::OpBitwiseAnd, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      // Create correct value according to index of insertelement.
      Ops.clear();
      Ops << MkId(ResTyID) << MkId(VMap[I.getOperand(1)])
          << MkId(ShiftAmountID);

      uint32_t InsertValID = nextID;

      Inst = new SPIRVInstruction(spv::OpShiftLeftLogical, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      // Insert value to original value.
      Ops.clear();
      Ops << MkId(ResTyID) << MkId(OrgValID) << MkId(InsertValID);

      VMap[&I] = nextID;

      Inst = new SPIRVInstruction(spv::OpBitwiseOr, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      break;
    }

    SPIRVOperandList Ops;

    // Ops[0] = Result Type ID
    Ops << MkId(lookupType(I.getType()));

    spv::Op Opcode = spv::OpCompositeInsert;
    if (const ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2))) {
      const auto value = CI->getZExtValue();
      assert(value <= UINT32_MAX);
      // Ops[1] = Object ID
      // Ops[2] = Composite ID
      // Ops[3] ... Ops[n] = Indexes (Literal Number)
      Ops << MkId(VMap[I.getOperand(1)]) << MkId(VMap[I.getOperand(0)])
          << MkNum(static_cast<uint32_t>(value));
    } else {
      // Ops[1] = Composite ID
      // Ops[2] = Object ID
      // Ops[3] ... Ops[n] = Indexes (Literal Number)
      Ops << MkId(VMap[I.getOperand(0)]) << MkId(VMap[I.getOperand(1)])
          << MkId(VMap[I.getOperand(2)]);
      Opcode = spv::OpVectorInsertDynamic;
    }

    auto *Inst = new SPIRVInstruction(Opcode, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::ShuffleVector: {
    // Ops[0] = Result Type ID
    // Ops[1] = Vector 1 ID
    // Ops[2] = Vector 2 ID
    // Ops[3] ... Ops[n] = Components (Literal Number)
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(I.getType())) << MkId(VMap[I.getOperand(0)])
        << MkId(VMap[I.getOperand(1)]);

    uint64_t NumElements = 0;
    if (Constant *Cst = dyn_cast<Constant>(I.getOperand(2))) {
      NumElements = cast<VectorType>(Cst->getType())->getNumElements();

      if (Cst->isNullValue()) {
        for (unsigned i = 0; i < NumElements; i++) {
          Ops << MkNum(0);
        }
      } else if (const ConstantDataSequential *CDS =
                     dyn_cast<ConstantDataSequential>(Cst)) {
        for (unsigned i = 0; i < CDS->getNumElements(); i++) {
          std::vector<uint32_t> LiteralNum;
          const auto value = CDS->getElementAsInteger(i);
          assert(value <= UINT32_MAX);
          Ops << MkNum(static_cast<uint32_t>(value));
        }
      } else if (const ConstantVector *CV = dyn_cast<ConstantVector>(Cst)) {
        for (unsigned i = 0; i < CV->getNumOperands(); i++) {
          auto Op = CV->getOperand(i);

          uint32_t literal = 0;

          if (auto CI = dyn_cast<ConstantInt>(Op)) {
            literal = static_cast<uint32_t>(CI->getZExtValue());
          } else if (auto UI = dyn_cast<UndefValue>(Op)) {
            literal = 0xFFFFFFFFu;
          } else {
            Op->print(errs());
            llvm_unreachable("Unsupported element in ConstantVector!");
          }

          Ops << MkNum(literal);
        }
      } else {
        Cst->print(errs());
        llvm_unreachable("Unsupported constant mask in ShuffleVector!");
      }
    }

    auto *Inst = new SPIRVInstruction(spv::OpVectorShuffle, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::ICmp:
  case Instruction::FCmp: {
    CmpInst *CmpI = cast<CmpInst>(&I);

    // Pointer equality is invalid.
    Type *ArgTy = CmpI->getOperand(0)->getType();
    if (isa<PointerType>(ArgTy)) {
      CmpI->print(errs());
      std::string name = I.getParent()->getParent()->getName();
      errs()
          << "\nPointer equality test is not supported by SPIR-V for Vulkan, "
          << "in function " << name << "\n";
      llvm_unreachable("Pointer equality check is invalid");
      break;
    }

    // Ops[0] = Result Type ID
    // Ops[1] = Operand 1 ID
    // Ops[2] = Operand 2 ID
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(CmpI->getType())) << MkId(VMap[CmpI->getOperand(0)])
        << MkId(VMap[CmpI->getOperand(1)]);

    spv::Op Opcode = GetSPIRVCmpOpcode(CmpI);
    auto *Inst = new SPIRVInstruction(Opcode, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::Br: {
    // Branch instrucion is deferred because it needs label's ID. Record slot's
    // location on SPIRVInstructionList.
    DeferredInsts.push_back(
        std::make_tuple(&I, --SPIRVInstList.end(), 0 /* No id */));
    break;
  }
  case Instruction::Switch: {
    I.print(errs());
    llvm_unreachable("Unsupported instruction???");
    break;
  }
  case Instruction::IndirectBr: {
    I.print(errs());
    llvm_unreachable("Unsupported instruction???");
    break;
  }
  case Instruction::PHI: {
    // Branch instrucion is deferred because it needs label's ID. Record slot's
    // location on SPIRVInstructionList.
    DeferredInsts.push_back(
        std::make_tuple(&I, --SPIRVInstList.end(), nextID++));
    break;
  }
  case Instruction::Alloca: {
    //
    // Generate OpVariable.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Storage Class
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(I.getType())) << MkNum(spv::StorageClassFunction);

    auto *Inst = new SPIRVInstruction(spv::OpVariable, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::Load: {
    LoadInst *LD = cast<LoadInst>(&I);
    //
    // Generate OpLoad.
    //

    if (LD->getType()->isPointerTy()) {
      // Loading a pointer requires variable pointers.
      setVariablePointersCapabilities(LD->getType()->getPointerAddressSpace());
    }

    uint32_t ResTyID = lookupType(LD->getType());
    uint32_t PointerID = VMap[LD->getPointerOperand()];

    // This is a hack to work around what looks like a driver bug.
    // When we're loading from the special variable holding the WorkgroupSize
    // builtin value, use an OpBitWiseAnd of the value's ID rather than
    // generating a load.
    // TODO(dneto): Remove this awful hack once drivers are fixed.
    if (PointerID == WorkgroupSizeVarID) {
      // Generate a bitwise-and of the original value with itself.
      // We should have been able to get away with just an OpCopyObject,
      // but we need something more complex to get past certain driver bugs.
      // This is ridiculous, but necessary.
      // TODO(dneto): Revisit this once drivers fix their bugs.

      SPIRVOperandList Ops;
      Ops << MkId(ResTyID) << MkId(WorkgroupSizeValueID)
          << MkId(WorkgroupSizeValueID);

      auto *Inst = new SPIRVInstruction(spv::OpBitwiseAnd, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // This is the normal path.  Generate a load.

    // Ops[0] = Result Type ID
    // Ops[1] = Pointer ID
    // Ops[2] ... Ops[n] = Optional Memory Access
    //
    // TODO: Do we need to implement Optional Memory Access???

    SPIRVOperandList Ops;
    Ops << MkId(ResTyID) << MkId(PointerID);

    auto *Inst = new SPIRVInstruction(spv::OpLoad, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::Store: {
    StoreInst *ST = cast<StoreInst>(&I);
    //
    // Generate OpStore.
    //

    if (ST->getValueOperand()->getType()->isPointerTy()) {
      // Storing a pointer requires variable pointers.
      setVariablePointersCapabilities(
          ST->getValueOperand()->getType()->getPointerAddressSpace());
    }

    // Ops[0] = Pointer ID
    // Ops[1] = Object ID
    // Ops[2] ... Ops[n] = Optional Memory Access (later???)
    //
    // TODO: Do we need to implement Optional Memory Access???
    SPIRVOperandList Ops;
    Ops << MkId(VMap[ST->getPointerOperand()])
        << MkId(VMap[ST->getValueOperand()]);

    auto *Inst = new SPIRVInstruction(spv::OpStore, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::AtomicCmpXchg: {
    I.print(errs());
    llvm_unreachable("Unsupported instruction???");
    break;
  }
  case Instruction::AtomicRMW: {
    AtomicRMWInst *AtomicRMW = dyn_cast<AtomicRMWInst>(&I);

    spv::Op opcode;

    switch (AtomicRMW->getOperation()) {
    default:
      I.print(errs());
      llvm_unreachable("Unsupported instruction???");
    case llvm::AtomicRMWInst::Add:
      opcode = spv::OpAtomicIAdd;
      break;
    case llvm::AtomicRMWInst::Sub:
      opcode = spv::OpAtomicISub;
      break;
    case llvm::AtomicRMWInst::Xchg:
      opcode = spv::OpAtomicExchange;
      break;
    case llvm::AtomicRMWInst::Min:
      opcode = spv::OpAtomicSMin;
      break;
    case llvm::AtomicRMWInst::Max:
      opcode = spv::OpAtomicSMax;
      break;
    case llvm::AtomicRMWInst::UMin:
      opcode = spv::OpAtomicUMin;
      break;
    case llvm::AtomicRMWInst::UMax:
      opcode = spv::OpAtomicUMax;
      break;
    case llvm::AtomicRMWInst::And:
      opcode = spv::OpAtomicAnd;
      break;
    case llvm::AtomicRMWInst::Or:
      opcode = spv::OpAtomicOr;
      break;
    case llvm::AtomicRMWInst::Xor:
      opcode = spv::OpAtomicXor;
      break;
    }

    //
    // Generate OpAtomic*.
    //
    SPIRVOperandList Ops;

    Ops << MkId(lookupType(I.getType()))
        << MkId(VMap[AtomicRMW->getPointerOperand()]);

    auto IntTy = Type::getInt32Ty(I.getContext());
    const auto ConstantScopeDevice = ConstantInt::get(IntTy, spv::ScopeDevice);
    Ops << MkId(VMap[ConstantScopeDevice]);

    const auto ConstantMemorySemantics = ConstantInt::get(
        IntTy, spv::MemorySemanticsUniformMemoryMask |
                   spv::MemorySemanticsSequentiallyConsistentMask);
    Ops << MkId(VMap[ConstantMemorySemantics]);

    Ops << MkId(VMap[AtomicRMW->getValOperand()]);

    VMap[&I] = nextID;

    auto *Inst = new SPIRVInstruction(opcode, nextID++, Ops);
    SPIRVInstList.push_back(Inst);
    break;
  }
  case Instruction::Fence: {
    I.print(errs());
    llvm_unreachable("Unsupported instruction???");
    break;
  }
  case Instruction::Call: {
    CallInst *Call = dyn_cast<CallInst>(&I);
    Function *Callee = Call->getCalledFunction();

    if (Callee->getName().startswith(clspv::ResourceAccessorFunction())) {
      if (ResourceVarDeferredLoadCalls.count(Call) && Call->hasNUsesOrMore(1)) {
        // Generate an OpLoad
        SPIRVOperandList Ops;
        const auto load_id = nextID++;

        Ops << MkId(lookupType(Call->getType()->getPointerElementType()))
            << MkId(ResourceVarDeferredLoadCalls[Call]);

        auto *Inst = new SPIRVInstruction(spv::OpLoad, load_id, Ops);
        SPIRVInstList.push_back(Inst);
        VMap[Call] = load_id;
        break;

      } else {
        // This maps to an OpVariable we've already generated.
        // No code is generated for the call.
      }
      break;
    } else if (Callee->getName().startswith(
                   clspv::WorkgroupAccessorFunction())) {
      // Don't codegen an instruction here, but instead map this call directly
      // to the workgroup variable id.
      int spec_id = static_cast<int>(
          cast<ConstantInt>(Call->getOperand(0))->getSExtValue());
      const auto &info = LocalSpecIdInfoMap[spec_id];
      VMap[Call] = info.variable_id;
      break;
    }

    // Sampler initializers become a load of the corresponding sampler.

    if (Callee->getName().equals(clspv::LiteralSamplerFunction())) {
      // Map this to a load from the variable.
      const auto index_into_sampler_map =
          dyn_cast<ConstantInt>(Call->getArgOperand(2))->getZExtValue();

      // Generate an OpLoad
      SPIRVOperandList Ops;
      const auto load_id = nextID++;

      Ops << MkId(lookupType(SamplerTy->getPointerElementType()))
          << MkId(SamplerMapIndexToIDMap[static_cast<unsigned>(
                 index_into_sampler_map)]);

      auto *Inst = new SPIRVInstruction(spv::OpLoad, load_id, Ops);
      SPIRVInstList.push_back(Inst);
      VMap[Call] = load_id;
      break;
    }

    // Handle SPIR-V intrinsics
    spv::Op opcode =
        StringSwitch<spv::Op>(Callee->getName())
            .Case("spirv.atomic_inc", spv::OpAtomicIIncrement)
            .Case("spirv.atomic_dec", spv::OpAtomicIDecrement)
            .Case("spirv.atomic_compare_exchange", spv::OpAtomicCompareExchange)
            .Case("spirv.atomic_xor", spv::OpAtomicXor)
            .Case("__spirv_control_barrier", spv::OpControlBarrier)
            .Case("__spirv_memory_barrier", spv::OpMemoryBarrier)
            .StartsWith("spirv.store_null", spv::OpStore)
            .StartsWith("__spirv_isinf", spv::OpIsInf)
            .StartsWith("__spirv_isnan", spv::OpIsNan)
            .StartsWith("__spirv_allDv", spv::OpAll)
            .StartsWith("__spirv_anyDv", spv::OpAny)
            .Default(spv::OpNop);

    // If the switch above didn't have an entry maybe the intrinsic
    // is using the name mangling logic.
    bool usesMangler = false;
    if (opcode == spv::OpNop) {
      if (Callee->getName().startswith(clspv::SPIRVOpIntrinsicFunction())) {
        auto OpCst = cast<ConstantInt>(Call->getOperand(0));
        opcode = static_cast<spv::Op>(OpCst->getZExtValue());
        usesMangler = true;
      }
    }

    if (opcode != spv::OpNop) {

      SPIRVOperandList Ops;

      if (!I.getType()->isVoidTy()) {
        Ops << MkId(lookupType(I.getType()));
      }

      unsigned firstOperand = usesMangler ? 1 : 0;
      for (unsigned i = firstOperand; i < Call->getNumArgOperands(); i++) {
        Ops << MkId(VMap[Call->getArgOperand(i)]);
      }

      if (!I.getType()->isVoidTy()) {
        VMap[&I] = nextID;
      }

      SPIRVInstruction *Inst;
      if (!I.getType()->isVoidTy()) {
        Inst = new SPIRVInstruction(opcode, nextID++, Ops);
      } else {
        Inst = new SPIRVInstruction(opcode, Ops);
      }
      SPIRVInstList.push_back(Inst);
      break;
    }

    if (Callee->getName().startswith("_Z3dot")) {
      // If the argument is a vector type, generate OpDot
      if (Call->getArgOperand(0)->getType()->isVectorTy()) {
        //
        // Generate OpDot.
        //
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType()));

        for (unsigned i = 0; i < Call->getNumArgOperands(); i++) {
          Ops << MkId(VMap[Call->getArgOperand(i)]);
        }

        VMap[&I] = nextID;

        auto *Inst = new SPIRVInstruction(spv::OpDot, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      } else {
        //
        // Generate OpFMul.
        //
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(I.getType()));

        for (unsigned i = 0; i < Call->getNumArgOperands(); i++) {
          Ops << MkId(VMap[Call->getArgOperand(i)]);
        }

        VMap[&I] = nextID;

        auto *Inst = new SPIRVInstruction(spv::OpFMul, nextID++, Ops);
        SPIRVInstList.push_back(Inst);
      }
      break;
    }

    if (Callee->getName().startswith("_Z4fmod")) {
      // OpenCL fmod(x,y) is x - y * trunc(x/y)
      // The sign for a non-zero result is taken from x.
      // (Try an example.)
      // So translate to OpFRem

      SPIRVOperandList Ops;

      Ops << MkId(lookupType(I.getType()));

      for (unsigned i = 0; i < Call->getNumArgOperands(); i++) {
        Ops << MkId(VMap[Call->getArgOperand(i)]);
      }

      VMap[&I] = nextID;

      auto *Inst = new SPIRVInstruction(spv::OpFRem, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // spirv.copy_memory.* intrinsics become OpMemoryMemory's.
    if (Callee->getName().startswith("spirv.copy_memory")) {
      //
      // Generate OpCopyMemory.
      //

      // Ops[0] = Dst ID
      // Ops[1] = Src ID
      // Ops[2] = Memory Access
      // Ops[3] = Alignment

      auto IsVolatile =
          dyn_cast<ConstantInt>(Call->getArgOperand(3))->getZExtValue() != 0;

      auto VolatileMemoryAccess = (IsVolatile) ? spv::MemoryAccessVolatileMask
                                               : spv::MemoryAccessMaskNone;

      auto MemoryAccess = VolatileMemoryAccess | spv::MemoryAccessAlignedMask;

      auto Alignment =
          dyn_cast<ConstantInt>(Call->getArgOperand(2))->getZExtValue();

      SPIRVOperandList Ops;
      Ops << MkId(VMap[Call->getArgOperand(0)])
          << MkId(VMap[Call->getArgOperand(1)]) << MkNum(MemoryAccess)
          << MkNum(static_cast<uint32_t>(Alignment));

      auto *Inst = new SPIRVInstruction(spv::OpCopyMemory, Ops);

      SPIRVInstList.push_back(Inst);

      break;
    }

    // read_image is converted to OpSampledImage and OpImageSampleExplicitLod.
    // Additionally, OpTypeSampledImage is generated.
    if (Callee->getName().equals(
            "_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f") ||
        Callee->getName().equals(
            "_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f")) {
      //
      // Generate OpSampledImage.
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Image ID
      // Ops[2] = Sampler ID
      //
      SPIRVOperandList Ops;

      Value *Image = Call->getArgOperand(0);
      Value *Sampler = Call->getArgOperand(1);
      Value *Coordinate = Call->getArgOperand(2);

      TypeMapType &OpImageTypeMap = getImageTypeMap();
      Type *ImageTy = Image->getType()->getPointerElementType();
      uint32_t ImageTyID = OpImageTypeMap[ImageTy];
      uint32_t ImageID = VMap[Image];
      uint32_t SamplerID = VMap[Sampler];

      Ops << MkId(ImageTyID) << MkId(ImageID) << MkId(SamplerID);

      uint32_t SampledImageID = nextID;

      auto *Inst = new SPIRVInstruction(spv::OpSampledImage, nextID++, Ops);
      SPIRVInstList.push_back(Inst);

      //
      // Generate OpImageSampleExplicitLod.
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Sampled Image ID
      // Ops[2] = Coordinate ID
      // Ops[3] = Image Operands Type ID
      // Ops[4] ... Ops[n] = Operands ID
      //
      Ops.clear();

      Ops << MkId(lookupType(Call->getType())) << MkId(SampledImageID)
          << MkId(VMap[Coordinate]) << MkNum(spv::ImageOperandsLodMask);

      Constant *CstFP0 = ConstantFP::get(Context, APFloat(0.0f));
      Ops << MkId(VMap[CstFP0]);

      VMap[&I] = nextID;

      Inst = new SPIRVInstruction(spv::OpImageSampleExplicitLod, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // write_imagef is mapped to OpImageWrite.
    if (Callee->getName().equals(
            "_Z12write_imagef14ocl_image2d_woDv2_iDv4_f") ||
        Callee->getName().equals(
            "_Z12write_imagef14ocl_image3d_woDv4_iDv4_f")) {
      //
      // Generate OpImageWrite.
      //
      // Ops[0] = Image ID
      // Ops[1] = Coordinate ID
      // Ops[2] = Texel ID
      // Ops[3] = (Optional) Image Operands Type (Literal Number)
      // Ops[4] ... Ops[n] = (Optional) Operands ID
      //
      SPIRVOperandList Ops;

      Value *Image = Call->getArgOperand(0);
      Value *Coordinate = Call->getArgOperand(1);
      Value *Texel = Call->getArgOperand(2);

      uint32_t ImageID = VMap[Image];
      uint32_t CoordinateID = VMap[Coordinate];
      uint32_t TexelID = VMap[Texel];
      Ops << MkId(ImageID) << MkId(CoordinateID) << MkId(TexelID);

      auto *Inst = new SPIRVInstruction(spv::OpImageWrite, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // get_image_width is mapped to OpImageQuerySize
    if (Callee->getName().equals("_Z15get_image_width14ocl_image2d_ro") ||
        Callee->getName().equals("_Z15get_image_width14ocl_image2d_wo") ||
        Callee->getName().equals("_Z16get_image_height14ocl_image2d_ro") ||
        Callee->getName().equals("_Z16get_image_height14ocl_image2d_wo")) {
      //
      // Generate OpImageQuerySize, then pull out the right component.
      // Assume 2D image for now.
      //
      // Ops[0] = Image ID
      //
      // %sizes = OpImageQuerySizes %uint2 %im
      // %result = OpCompositeExtract %uint %sizes 0-or-1
      SPIRVOperandList Ops;

      // Implement:
      //     %sizes = OpImageQuerySizes %uint2 %im
      uint32_t SizesTypeID =
          TypeMap[VectorType::get(Type::getInt32Ty(Context), 2)];
      Value *Image = Call->getArgOperand(0);
      uint32_t ImageID = VMap[Image];
      Ops << MkId(SizesTypeID) << MkId(ImageID);

      uint32_t SizesID = nextID++;
      auto *QueryInst =
          new SPIRVInstruction(spv::OpImageQuerySize, SizesID, Ops);
      SPIRVInstList.push_back(QueryInst);

      // Reset value map entry since we generated an intermediate instruction.
      VMap[&I] = nextID;

      // Implement:
      //     %result = OpCompositeExtract %uint %sizes 0-or-1
      Ops.clear();
      Ops << MkId(TypeMap[I.getType()]) << MkId(SizesID);

      uint32_t component = Callee->getName().contains("height") ? 1 : 0;
      Ops << MkNum(component);

      auto *Inst = new SPIRVInstruction(spv::OpCompositeExtract, nextID++, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }

    // Call instrucion is deferred because it needs function's ID. Record
    // slot's location on SPIRVInstructionList.
    DeferredInsts.push_back(
        std::make_tuple(&I, --SPIRVInstList.end(), nextID++));

    // Check whether the implementation of this call uses an extended
    // instruction plus one more value-producing instruction.  If so, then
    // reserve the id for the extra value-producing slot.
    glsl::ExtInst EInst = getIndirectExtInstEnum(Callee->getName());
    if (EInst != kGlslExtInstBad) {
      // Reserve a spot for the extra value.
      // Increase nextID.
      VMap[&I] = nextID;
      nextID++;
    }
    break;
  }
  case Instruction::Ret: {
    unsigned NumOps = I.getNumOperands();
    if (NumOps == 0) {
      //
      // Generate OpReturn.
      //
      SPIRVInstList.push_back(new SPIRVInstruction(spv::OpReturn, {}));
    } else {
      //
      // Generate OpReturnValue.
      //

      // Ops[0] = Return Value ID
      SPIRVOperandList Ops;

      Ops << MkId(VMap[I.getOperand(0)]);

      auto *Inst = new SPIRVInstruction(spv::OpReturnValue, Ops);
      SPIRVInstList.push_back(Inst);
      break;
    }
    break;
  }
  }
}

void SPIRVProducerPass::GenerateFuncEpilogue() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();

  //
  // Generate OpFunctionEnd
  //

  auto *Inst = new SPIRVInstruction(spv::OpFunctionEnd, {});
  SPIRVInstList.push_back(Inst);
}

bool SPIRVProducerPass::is4xi8vec(Type *Ty) const {
  // Don't specialize <4 x i8> if i8 is generally supported.
  if (clspv::Option::Int8Support())
    return false;

  LLVMContext &Context = Ty->getContext();
  if (Ty->isVectorTy()) {
    if (Ty->getVectorElementType() == Type::getInt8Ty(Context) &&
        Ty->getVectorNumElements() == 4) {
      return true;
    }
  }

  return false;
}

uint32_t SPIRVProducerPass::GetI32Zero() {
  if (0 == constant_i32_zero_id_) {
    llvm_unreachable("Requesting a 32-bit integer constant but it is not "
                     "defined in the SPIR-V module");
  }
  return constant_i32_zero_id_;
}

void SPIRVProducerPass::HandleDeferredInstruction() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();
  ValueMapType &VMap = getValueMap();
  DeferredInstVecType &DeferredInsts = getDeferredInstVec();

  for (auto DeferredInst = DeferredInsts.rbegin();
       DeferredInst != DeferredInsts.rend(); ++DeferredInst) {
    Value *Inst = std::get<0>(*DeferredInst);
    SPIRVInstructionList::iterator InsertPoint = ++std::get<1>(*DeferredInst);
    if (InsertPoint != SPIRVInstList.end()) {
      while ((*InsertPoint)->getOpcode() == spv::OpPhi) {
        ++InsertPoint;
      }
    }

    if (BranchInst *Br = dyn_cast<BranchInst>(Inst)) {
      // Check whether basic block, which has this branch instruction, is loop
      // header or not. If it is loop header, generate OpLoopMerge and
      // OpBranchConditional.
      Function *Func = Br->getParent()->getParent();
      DominatorTree &DT =
          getAnalysis<DominatorTreeWrapperPass>(*Func).getDomTree();
      const LoopInfo &LI =
          getAnalysis<LoopInfoWrapperPass>(*Func).getLoopInfo();

      BasicBlock *BrBB = Br->getParent();
      Loop *L = LI.getLoopFor(BrBB);
      if (LI.isLoopHeader(BrBB)) {
        Value *ContinueBB = nullptr;
        Value *MergeBB = nullptr;

        MergeBB = L->getExitBlock();
        if (!MergeBB) {
          // StructurizeCFG pass converts CFG into triangle shape and the cfg
          // has regions with single entry/exit. As a result, loop should not
          // have multiple exits.
          llvm_unreachable("Loop has multiple exits???");
        }

        if (L->isLoopLatch(BrBB)) {
          ContinueBB = BrBB;
        } else {
          // From SPIR-V spec 2.11, Continue Target must dominate that back-edge
          // block.
          BasicBlock *Header = L->getHeader();
          BasicBlock *Latch = L->getLoopLatch();
          for (BasicBlock *BB : L->blocks()) {
            if (BB == Header) {
              continue;
            }

            // Check whether block dominates block with back-edge.
            if (DT.dominates(BB, Latch)) {
              ContinueBB = BB;
            }
          }

          if (!ContinueBB) {
            llvm_unreachable("Wrong continue block from loop");
          }
        }

        //
        // Generate OpLoopMerge.
        //
        // Ops[0] = Merge Block ID
        // Ops[1] = Continue Target ID
        // Ops[2] = Selection Control
        SPIRVOperandList Ops;

        // StructurizeCFG pass already manipulated CFG. Just use false block of
        // branch instruction as merge block.
        uint32_t MergeBBID = VMap[MergeBB];
        uint32_t ContinueBBID = VMap[ContinueBB];
        Ops << MkId(MergeBBID) << MkId(ContinueBBID)
            << MkNum(spv::SelectionControlMaskNone);

        auto *MergeInst = new SPIRVInstruction(spv::OpLoopMerge, Ops);
        SPIRVInstList.insert(InsertPoint, MergeInst);

      } else if (Br->isConditional()) {
        // Generate a selection merge unless this is a back-edge block.
        bool HasBackedge = false;
        while (L && !HasBackedge) {
          if (L->isLoopLatch(BrBB)) {
            HasBackedge = true;
          }
          L = L->getParentLoop();
        }
        if (!HasBackedge) {
          //
          // Generate OpSelectionMerge.
          //
          // Ops[0] = Merge Block ID
          // Ops[1] = Selection Control
          SPIRVOperandList Ops;

          // StructurizeCFG pass already manipulated CFG. Just use false block
          // of branch instruction as merge block.
          uint32_t MergeBBID = VMap[Br->getSuccessor(1)];
          Ops << MkId(MergeBBID) << MkNum(spv::SelectionControlMaskNone);

          auto *MergeInst = new SPIRVInstruction(spv::OpSelectionMerge, Ops);
          SPIRVInstList.insert(InsertPoint, MergeInst);
        }
      }

      if (Br->isConditional()) {
        //
        // Generate OpBranchConditional.
        //
        // Ops[0] = Condition ID
        // Ops[1] = True Label ID
        // Ops[2] = False Label ID
        // Ops[3] ... Ops[n] = Branch weights (Literal Number)
        SPIRVOperandList Ops;

        uint32_t CondID = VMap[Br->getCondition()];
        uint32_t TrueBBID = VMap[Br->getSuccessor(0)];
        uint32_t FalseBBID = VMap[Br->getSuccessor(1)];

        Ops << MkId(CondID) << MkId(TrueBBID) << MkId(FalseBBID);

        auto *BrInst = new SPIRVInstruction(spv::OpBranchConditional, Ops);
        SPIRVInstList.insert(InsertPoint, BrInst);
      } else {
        //
        // Generate OpBranch.
        //
        // Ops[0] = Target Label ID
        SPIRVOperandList Ops;

        uint32_t TargetID = VMap[Br->getSuccessor(0)];
        Ops << MkId(TargetID);

        SPIRVInstList.insert(InsertPoint,
                             new SPIRVInstruction(spv::OpBranch, Ops));
      }
    } else if (PHINode *PHI = dyn_cast<PHINode>(Inst)) {
      if (PHI->getType()->isPointerTy()) {
        // OpPhi on pointers requires variable pointers.
        setVariablePointersCapabilities(
            PHI->getType()->getPointerAddressSpace());
        if (!hasVariablePointers() && !selectFromSameObject(PHI)) {
          setVariablePointers(true);
        }
      }

      //
      // Generate OpPhi.
      //
      // Ops[0] = Result Type ID
      // Ops[1] ... Ops[n] = (Variable ID, Parent ID) pairs
      SPIRVOperandList Ops;

      Ops << MkId(lookupType(PHI->getType()));

      for (unsigned i = 0; i < PHI->getNumIncomingValues(); i++) {
        uint32_t VarID = VMap[PHI->getIncomingValue(i)];
        uint32_t ParentID = VMap[PHI->getIncomingBlock(i)];
        Ops << MkId(VarID) << MkId(ParentID);
      }

      SPIRVInstList.insert(
          InsertPoint,
          new SPIRVInstruction(spv::OpPhi, std::get<2>(*DeferredInst), Ops));
    } else if (CallInst *Call = dyn_cast<CallInst>(Inst)) {
      Function *Callee = Call->getCalledFunction();
      auto callee_name = Callee->getName();
      glsl::ExtInst EInst = getDirectOrIndirectExtInstEnum(callee_name);

      if (EInst) {
        uint32_t &ExtInstImportID = getOpExtInstImportID();

        //
        // Generate OpExtInst.
        //

        // Ops[0] = Result Type ID
        // Ops[1] = Set ID (OpExtInstImport ID)
        // Ops[2] = Instruction Number (Literal Number)
        // Ops[3] ... Ops[n] = Operand 1, ... , Operand n
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(Call->getType())) << MkId(ExtInstImportID)
            << MkNum(EInst);

        FunctionType *CalleeFTy = cast<FunctionType>(Call->getFunctionType());
        for (unsigned i = 0; i < CalleeFTy->getNumParams(); i++) {
          Ops << MkId(VMap[Call->getOperand(i)]);
        }

        auto *ExtInst = new SPIRVInstruction(spv::OpExtInst,
                                             std::get<2>(*DeferredInst), Ops);
        SPIRVInstList.insert(InsertPoint, ExtInst);

        const auto IndirectExtInst = getIndirectExtInstEnum(callee_name);
        if (IndirectExtInst != kGlslExtInstBad) {
          // Generate one more instruction that uses the result of the extended
          // instruction.  Its result id is one more than the id of the
          // extended instruction.
          LLVMContext &Context =
              Call->getParent()->getParent()->getParent()->getContext();

          auto generate_extra_inst = [this, &Context, &Call, &DeferredInst,
                                      &VMap, &SPIRVInstList, &InsertPoint](
                                         spv::Op opcode, Constant *constant) {
            //
            // Generate instruction like:
            //   result = opcode constant <extinst-result>
            //
            // Ops[0] = Result Type ID
            // Ops[1] = Operand 0 ;; the constant, suitably splatted
            // Ops[2] = Operand 1 ;; the result of the extended instruction
            SPIRVOperandList Ops;

            Type *resultTy = Call->getType();
            Ops << MkId(lookupType(resultTy));

            if (auto *vectorTy = dyn_cast<VectorType>(resultTy)) {
              constant = ConstantVector::getSplat(
                  static_cast<unsigned>(vectorTy->getNumElements()), constant);
            }
            Ops << MkId(VMap[constant]) << MkId(std::get<2>(*DeferredInst));

            SPIRVInstList.insert(
                InsertPoint, new SPIRVInstruction(
                                 opcode, std::get<2>(*DeferredInst) + 1, Ops));
          };

          switch (IndirectExtInst) {
          case glsl::ExtInstFindUMsb: // Implementing clz
            generate_extra_inst(
                spv::OpISub, ConstantInt::get(Type::getInt32Ty(Context), 31));
            break;
          case glsl::ExtInstAcos:  // Implementing acospi
          case glsl::ExtInstAsin:  // Implementing asinpi
          case glsl::ExtInstAtan:  // Implementing atanpi
          case glsl::ExtInstAtan2: // Implementing atan2pi
            generate_extra_inst(
                spv::OpFMul,
                ConstantFP::get(Type::getFloatTy(Context), kOneOverPi));
            break;

          default:
            assert(false && "internally inconsistent");
          }
        }

      } else if (callee_name.startswith("_Z8popcount")) {
        //
        // Generate OpBitCount
        //
        // Ops[0] = Result Type ID
        // Ops[1] = Base ID
        SPIRVOperandList Ops;
        Ops << MkId(lookupType(Call->getType()))
            << MkId(VMap[Call->getOperand(0)]);

        SPIRVInstList.insert(
            InsertPoint, new SPIRVInstruction(spv::OpBitCount,
                                              std::get<2>(*DeferredInst), Ops));

      } else if (callee_name.startswith(kCompositeConstructFunctionPrefix)) {

        // Generate an OpCompositeConstruct
        SPIRVOperandList Ops;

        // The result type.
        Ops << MkId(lookupType(Call->getType()));

        for (Use &use : Call->arg_operands()) {
          Ops << MkId(VMap[use.get()]);
        }

        SPIRVInstList.insert(
            InsertPoint, new SPIRVInstruction(spv::OpCompositeConstruct,
                                              std::get<2>(*DeferredInst), Ops));

      } else if (callee_name.startswith(clspv::ResourceAccessorFunction())) {

        // We have already mapped the call's result value to an ID.
        // Don't generate any code now.

      } else if (callee_name.startswith(clspv::WorkgroupAccessorFunction())) {

        // We have already mapped the call's result value to an ID.
        // Don't generate any code now.

      } else {
        if (Call->getType()->isPointerTy()) {
          // Functions returning pointers require variable pointers.
          setVariablePointersCapabilities(
              Call->getType()->getPointerAddressSpace());
        }

        //
        // Generate OpFunctionCall.
        //

        // Ops[0] = Result Type ID
        // Ops[1] = Callee Function ID
        // Ops[2] ... Ops[n] = Argument 0, ... , Argument n
        SPIRVOperandList Ops;

        Ops << MkId(lookupType(Call->getType()));

        uint32_t CalleeID = VMap[Callee];
        if (CalleeID == 0) {
          errs() << "Can't translate function call.  Missing builtin? "
                 << callee_name << " in: " << *Call << "\n";
          // TODO(dneto): Can we error out?  Enabling this llvm_unreachable
          // causes an infinite loop.  Instead, go ahead and generate
          // the bad function call.  A validator will catch the 0-Id.
          // llvm_unreachable("Can't translate function call");
        }

        Ops << MkId(CalleeID);

        FunctionType *CalleeFTy = cast<FunctionType>(Call->getFunctionType());
        for (unsigned i = 0; i < CalleeFTy->getNumParams(); i++) {
          auto *operand = Call->getOperand(i);
          if (operand->getType()->isPointerTy()) {
            auto sc =
                GetStorageClass(operand->getType()->getPointerAddressSpace());
            if (sc == spv::StorageClassStorageBuffer) {
              // Passing SSBO by reference requires variable pointers storage
              // buffer.
              setVariablePointersStorageBuffer(true);
            } else if (sc == spv::StorageClassWorkgroup) {
              // Workgroup references require variable pointers if they are not
              // memory object declarations.
              if (auto *operand_call = dyn_cast<CallInst>(operand)) {
                // Workgroup accessor represents a variable reference.
                if (!operand_call->getCalledFunction()->getName().startswith(
                        clspv::WorkgroupAccessorFunction()))
                  setVariablePointers(true);
              } else {
                // Arguments are function parameters.
                if (!isa<Argument>(operand))
                  setVariablePointers(true);
              }
            }
          }
          Ops << MkId(VMap[operand]);
        }

        auto *CallInst = new SPIRVInstruction(spv::OpFunctionCall,
                                              std::get<2>(*DeferredInst), Ops);
        SPIRVInstList.insert(InsertPoint, CallInst);
      }
    }
  }
}

void SPIRVProducerPass::HandleDeferredDecorations(const DataLayout &DL) {
  if (getTypesNeedingArrayStride().empty() && LocalArgSpecIds.empty()) {
    return;
  }

  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();

  // Find an iterator pointing just past the last decoration.
  bool seen_decorations = false;
  auto DecoInsertPoint =
      std::find_if(SPIRVInstList.begin(), SPIRVInstList.end(),
                   [&seen_decorations](SPIRVInstruction *Inst) -> bool {
                     const bool is_decoration =
                         Inst->getOpcode() == spv::OpDecorate ||
                         Inst->getOpcode() == spv::OpMemberDecorate;
                     if (is_decoration) {
                       seen_decorations = true;
                       return false;
                     } else {
                       return seen_decorations;
                     }
                   });

  // Insert ArrayStride decorations on pointer types, due to OpPtrAccessChain
  // instructions we generated earlier.
  for (auto *type : getTypesNeedingArrayStride()) {
    Type *elemTy = nullptr;
    if (auto *ptrTy = dyn_cast<PointerType>(type)) {
      elemTy = ptrTy->getElementType();
    } else if (auto *arrayTy = dyn_cast<ArrayType>(type)) {
      elemTy = arrayTy->getArrayElementType();
    } else if (auto *seqTy = dyn_cast<SequentialType>(type)) {
      elemTy = seqTy->getSequentialElementType();
    } else {
      errs() << "Unhandled strided type " << *type << "\n";
      llvm_unreachable("Unhandled strided type");
    }

    // Ops[0] = Target ID
    // Ops[1] = Decoration (ArrayStride)
    // Ops[2] = Stride number (Literal Number)
    SPIRVOperandList Ops;

    // Same as DL.getIndexedOffsetInType( elemTy, { 1 } );
    const uint32_t stride = static_cast<uint32_t>(GetTypeAllocSize(elemTy, DL));

    Ops << MkId(lookupType(type)) << MkNum(spv::DecorationArrayStride)
        << MkNum(stride);

    auto *DecoInst = new SPIRVInstruction(spv::OpDecorate, Ops);
    SPIRVInstList.insert(DecoInsertPoint, DecoInst);
  }

  // Emit SpecId decorations targeting the array size value.
  for (auto spec_id = clspv::FirstLocalSpecId(); spec_id < max_local_spec_id_;
       ++spec_id) {
    LocalArgInfo &arg_info = LocalSpecIdInfoMap[spec_id];
    SPIRVOperandList Ops;
    Ops << MkId(arg_info.array_size_id) << MkNum(spv::DecorationSpecId)
        << MkNum(arg_info.spec_id);
    SPIRVInstList.insert(DecoInsertPoint,
                         new SPIRVInstruction(spv::OpDecorate, Ops));
  }
}

glsl::ExtInst SPIRVProducerPass::getExtInstEnum(StringRef Name) {
  return StringSwitch<glsl::ExtInst>(Name)
      .Case("_Z3absc", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv2_c", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv3_c", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv4_c", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3abss", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv2_s", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv3_s", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv4_s", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absi", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv2_i", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv3_i", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv4_i", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absl", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv2_l", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv3_l", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z3absDv4_l", glsl::ExtInst::ExtInstSAbs)
      .Case("_Z5clampccc", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv2_cS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv3_cS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv4_cS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clamphhh", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv2_hS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv3_hS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv4_hS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampsss", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv2_sS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv3_sS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv4_sS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampttt", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv2_tS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv3_tS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv4_tS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampiii", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv2_iS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv3_iS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv4_iS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampjjj", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv2_jS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv3_jS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv4_jS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clamplll", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv2_lS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv3_lS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampDv4_lS_S_", glsl::ExtInst::ExtInstSClamp)
      .Case("_Z5clampmmm", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv2_mS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv3_mS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampDv4_mS_S_", glsl::ExtInst::ExtInstUClamp)
      .Case("_Z5clampfff", glsl::ExtInst::ExtInstFClamp)
      .Case("_Z5clampDv2_fS_S_", glsl::ExtInst::ExtInstFClamp)
      .Case("_Z5clampDv3_fS_S_", glsl::ExtInst::ExtInstFClamp)
      .Case("_Z5clampDv4_fS_S_", glsl::ExtInst::ExtInstFClamp)
      .Case("_Z3maxcc", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv2_cS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv3_cS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv4_cS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxhh", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv2_hS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv3_hS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv4_hS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxss", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv2_sS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv3_sS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv4_sS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxtt", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv2_tS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv3_tS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv4_tS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxii", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv2_iS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv3_iS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv4_iS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxjj", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv2_jS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv3_jS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv4_jS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxll", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv2_lS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv3_lS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxDv4_lS_", glsl::ExtInst::ExtInstSMax)
      .Case("_Z3maxmm", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv2_mS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv3_mS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxDv4_mS_", glsl::ExtInst::ExtInstUMax)
      .Case("_Z3maxff", glsl::ExtInst::ExtInstFMax)
      .Case("_Z3maxDv2_fS_", glsl::ExtInst::ExtInstFMax)
      .Case("_Z3maxDv3_fS_", glsl::ExtInst::ExtInstFMax)
      .Case("_Z3maxDv4_fS_", glsl::ExtInst::ExtInstFMax)
      .StartsWith("_Z4fmax", glsl::ExtInst::ExtInstFMax)
      .Case("_Z3mincc", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv2_cS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv3_cS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv4_cS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minhh", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv2_hS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv3_hS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv4_hS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minss", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv2_sS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv3_sS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv4_sS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3mintt", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv2_tS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv3_tS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv4_tS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minii", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv2_iS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv3_iS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv4_iS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minjj", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv2_jS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv3_jS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv4_jS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minll", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv2_lS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv3_lS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minDv4_lS_", glsl::ExtInst::ExtInstSMin)
      .Case("_Z3minmm", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv2_mS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv3_mS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minDv4_mS_", glsl::ExtInst::ExtInstUMin)
      .Case("_Z3minff", glsl::ExtInst::ExtInstFMin)
      .Case("_Z3minDv2_fS_", glsl::ExtInst::ExtInstFMin)
      .Case("_Z3minDv3_fS_", glsl::ExtInst::ExtInstFMin)
      .Case("_Z3minDv4_fS_", glsl::ExtInst::ExtInstFMin)
      .StartsWith("_Z4fmin", glsl::ExtInst::ExtInstFMin)
      .StartsWith("_Z7degrees", glsl::ExtInst::ExtInstDegrees)
      .StartsWith("_Z7radians", glsl::ExtInst::ExtInstRadians)
      .StartsWith("_Z3mix", glsl::ExtInst::ExtInstFMix)
      .StartsWith("_Z4acos", glsl::ExtInst::ExtInstAcos)
      .StartsWith("_Z5acosh", glsl::ExtInst::ExtInstAcosh)
      .StartsWith("_Z4asin", glsl::ExtInst::ExtInstAsin)
      .StartsWith("_Z5asinh", glsl::ExtInst::ExtInstAsinh)
      .StartsWith("_Z4atan", glsl::ExtInst::ExtInstAtan)
      .StartsWith("_Z5atan2", glsl::ExtInst::ExtInstAtan2)
      .StartsWith("_Z5atanh", glsl::ExtInst::ExtInstAtanh)
      .StartsWith("_Z4ceil", glsl::ExtInst::ExtInstCeil)
      .StartsWith("_Z3sin", glsl::ExtInst::ExtInstSin)
      .StartsWith("_Z4sinh", glsl::ExtInst::ExtInstSinh)
      .StartsWith("_Z8half_sin", glsl::ExtInst::ExtInstSin)
      .StartsWith("_Z10native_sin", glsl::ExtInst::ExtInstSin)
      .StartsWith("_Z3cos", glsl::ExtInst::ExtInstCos)
      .StartsWith("_Z4cosh", glsl::ExtInst::ExtInstCosh)
      .StartsWith("_Z8half_cos", glsl::ExtInst::ExtInstCos)
      .StartsWith("_Z10native_cos", glsl::ExtInst::ExtInstCos)
      .StartsWith("_Z3tan", glsl::ExtInst::ExtInstTan)
      .StartsWith("_Z4tanh", glsl::ExtInst::ExtInstTanh)
      .StartsWith("_Z8half_tan", glsl::ExtInst::ExtInstTan)
      .StartsWith("_Z10native_tan", glsl::ExtInst::ExtInstTan)
      .StartsWith("_Z3exp", glsl::ExtInst::ExtInstExp)
      .StartsWith("_Z8half_exp", glsl::ExtInst::ExtInstExp)
      .StartsWith("_Z10native_exp", glsl::ExtInst::ExtInstExp)
      .StartsWith("_Z4exp2", glsl::ExtInst::ExtInstExp2)
      .StartsWith("_Z9half_exp2", glsl::ExtInst::ExtInstExp2)
      .StartsWith("_Z11native_exp2", glsl::ExtInst::ExtInstExp2)
      .StartsWith("_Z3log", glsl::ExtInst::ExtInstLog)
      .StartsWith("_Z8half_log", glsl::ExtInst::ExtInstLog)
      .StartsWith("_Z10native_log", glsl::ExtInst::ExtInstLog)
      .StartsWith("_Z4log2", glsl::ExtInst::ExtInstLog2)
      .StartsWith("_Z9half_log2", glsl::ExtInst::ExtInstLog2)
      .StartsWith("_Z11native_log2", glsl::ExtInst::ExtInstLog2)
      .StartsWith("_Z4fabs", glsl::ExtInst::ExtInstFAbs)
      .StartsWith("_Z3fma", glsl::ExtInst::ExtInstFma)
      .StartsWith("_Z5floor", glsl::ExtInst::ExtInstFloor)
      .StartsWith("_Z5ldexp", glsl::ExtInst::ExtInstLdexp)
      .StartsWith("_Z3pow", glsl::ExtInst::ExtInstPow)
      .StartsWith("_Z4powr", glsl::ExtInst::ExtInstPow)
      .StartsWith("_Z9half_powr", glsl::ExtInst::ExtInstPow)
      .StartsWith("_Z11native_powr", glsl::ExtInst::ExtInstPow)
      .StartsWith("_Z5round", glsl::ExtInst::ExtInstRound)
      .StartsWith("_Z4sqrt", glsl::ExtInst::ExtInstSqrt)
      .StartsWith("_Z9half_sqrt", glsl::ExtInst::ExtInstSqrt)
      .StartsWith("_Z11native_sqrt", glsl::ExtInst::ExtInstSqrt)
      .StartsWith("_Z5rsqrt", glsl::ExtInst::ExtInstInverseSqrt)
      .StartsWith("_Z10half_rsqrt", glsl::ExtInst::ExtInstInverseSqrt)
      .StartsWith("_Z12native_rsqrt", glsl::ExtInst::ExtInstInverseSqrt)
      .StartsWith("_Z5trunc", glsl::ExtInst::ExtInstTrunc)
      .StartsWith("_Z5frexp", glsl::ExtInst::ExtInstFrexp)
      .StartsWith("_Z4sign", glsl::ExtInst::ExtInstFSign)
      .StartsWith("_Z6length", glsl::ExtInst::ExtInstLength)
      .StartsWith("_Z11fast_length", glsl::ExtInst::ExtInstLength)
      .StartsWith("_Z8distance", glsl::ExtInst::ExtInstDistance)
      .StartsWith("_Z13fast_distance", glsl::ExtInst::ExtInstDistance)
      .StartsWith("_Z4step", glsl::ExtInst::ExtInstStep)
      .StartsWith("_Z10smoothstep", glsl::ExtInst::ExtInstSmoothStep)
      .Case("_Z5crossDv3_fS_", glsl::ExtInst::ExtInstCross)
      .StartsWith("_Z9normalize", glsl::ExtInst::ExtInstNormalize)
      .StartsWith("_Z14fast_normalize", glsl::ExtInst::ExtInstNormalize)
      .StartsWith("llvm.fmuladd.", glsl::ExtInst::ExtInstFma)
      .Case("spirv.unpack.v2f16", glsl::ExtInst::ExtInstUnpackHalf2x16)
      .Case("spirv.pack.v2f16", glsl::ExtInst::ExtInstPackHalf2x16)
      .Case("clspv.fract.f", glsl::ExtInst::ExtInstFract)
      .Case("clspv.fract.v2f", glsl::ExtInst::ExtInstFract)
      .Case("clspv.fract.v3f", glsl::ExtInst::ExtInstFract)
      .Case("clspv.fract.v4f", glsl::ExtInst::ExtInstFract)
      .Default(kGlslExtInstBad);
}

glsl::ExtInst SPIRVProducerPass::getIndirectExtInstEnum(StringRef Name) {
  // Check indirect cases.
  return StringSwitch<glsl::ExtInst>(Name)
      .StartsWith("_Z3clz", glsl::ExtInst::ExtInstFindUMsb)
      // Use exact match on float arg because these need a multiply
      // of a constant of the right floating point type.
      .Case("_Z6acospif", glsl::ExtInst::ExtInstAcos)
      .Case("_Z6acospiDv2_f", glsl::ExtInst::ExtInstAcos)
      .Case("_Z6acospiDv3_f", glsl::ExtInst::ExtInstAcos)
      .Case("_Z6acospiDv4_f", glsl::ExtInst::ExtInstAcos)
      .Case("_Z6asinpif", glsl::ExtInst::ExtInstAsin)
      .Case("_Z6asinpiDv2_f", glsl::ExtInst::ExtInstAsin)
      .Case("_Z6asinpiDv3_f", glsl::ExtInst::ExtInstAsin)
      .Case("_Z6asinpiDv4_f", glsl::ExtInst::ExtInstAsin)
      .Case("_Z6atanpif", glsl::ExtInst::ExtInstAtan)
      .Case("_Z6atanpiDv2_f", glsl::ExtInst::ExtInstAtan)
      .Case("_Z6atanpiDv3_f", glsl::ExtInst::ExtInstAtan)
      .Case("_Z6atanpiDv4_f", glsl::ExtInst::ExtInstAtan)
      .Case("_Z7atan2piff", glsl::ExtInst::ExtInstAtan2)
      .Case("_Z7atan2piDv2_fS_", glsl::ExtInst::ExtInstAtan2)
      .Case("_Z7atan2piDv3_fS_", glsl::ExtInst::ExtInstAtan2)
      .Case("_Z7atan2piDv4_fS_", glsl::ExtInst::ExtInstAtan2)
      .Default(kGlslExtInstBad);
}

glsl::ExtInst
SPIRVProducerPass::getDirectOrIndirectExtInstEnum(StringRef Name) {
  auto direct = getExtInstEnum(Name);
  if (direct != kGlslExtInstBad)
    return direct;
  return getIndirectExtInstEnum(Name);
}

void SPIRVProducerPass::WriteOneWord(uint32_t Word) {
  binaryOut->write(reinterpret_cast<const char *>(&Word), sizeof(uint32_t));
}

void SPIRVProducerPass::WriteResultID(SPIRVInstruction *Inst) {
  WriteOneWord(Inst->getResultID());
}

void SPIRVProducerPass::WriteWordCountAndOpcode(SPIRVInstruction *Inst) {
  // High 16 bit : Word Count
  // Low 16 bit  : Opcode
  uint32_t Word = Inst->getOpcode();
  const uint32_t count = Inst->getWordCount();
  if (count > 65535) {
    errs() << "Word count limit of 65535 exceeded: " << count << "\n";
    llvm_unreachable("Word count too high");
  }
  Word |= Inst->getWordCount() << 16;
  WriteOneWord(Word);
}

void SPIRVProducerPass::WriteOperand(SPIRVOperand *Op) {
  SPIRVOperandType OpTy = Op->getType();
  switch (OpTy) {
  default: {
    llvm_unreachable("Unsupported SPIRV Operand Type???");
    break;
  }
  case SPIRVOperandType::NUMBERID: {
    WriteOneWord(Op->getNumID());
    break;
  }
  case SPIRVOperandType::LITERAL_STRING: {
    std::string Str = Op->getLiteralStr();
    const char *Data = Str.c_str();
    size_t WordSize = Str.size() / 4;
    for (unsigned Idx = 0; Idx < WordSize; Idx++) {
      WriteOneWord(*reinterpret_cast<const uint32_t *>(&Data[4 * Idx]));
    }

    uint32_t Remainder = Str.size() % 4;
    uint32_t LastWord = 0;
    if (Remainder) {
      for (unsigned Idx = 0; Idx < Remainder; Idx++) {
        LastWord |= Data[4 * WordSize + Idx] << 8 * Idx;
      }
    }

    WriteOneWord(LastWord);
    break;
  }
  case SPIRVOperandType::LITERAL_INTEGER:
  case SPIRVOperandType::LITERAL_FLOAT: {
    auto LiteralNum = Op->getLiteralNum();
    // TODO: Handle LiteranNum carefully.
    for (auto Word : LiteralNum) {
      WriteOneWord(Word);
    }
    break;
  }
  }
}

void SPIRVProducerPass::WriteSPIRVBinary() {
  SPIRVInstructionList &SPIRVInstList = getSPIRVInstList();

  for (auto Inst : SPIRVInstList) {
    SPIRVOperandList Ops{Inst->getOperands()};
    spv::Op Opcode = static_cast<spv::Op>(Inst->getOpcode());

    switch (Opcode) {
    default: {
      errs() << "Unsupported SPIR-V instruction opcode " << int(Opcode) << "\n";
      llvm_unreachable("Unsupported SPIRV instruction");
      break;
    }
    case spv::OpCapability:
    case spv::OpExtension:
    case spv::OpMemoryModel:
    case spv::OpEntryPoint:
    case spv::OpExecutionMode:
    case spv::OpSource:
    case spv::OpDecorate:
    case spv::OpMemberDecorate:
    case spv::OpBranch:
    case spv::OpBranchConditional:
    case spv::OpSelectionMerge:
    case spv::OpLoopMerge:
    case spv::OpStore:
    case spv::OpImageWrite:
    case spv::OpReturnValue:
    case spv::OpControlBarrier:
    case spv::OpMemoryBarrier:
    case spv::OpReturn:
    case spv::OpFunctionEnd:
    case spv::OpCopyMemory: {
      WriteWordCountAndOpcode(Inst);
      for (uint32_t i = 0; i < Ops.size(); i++) {
        WriteOperand(Ops[i]);
      }
      break;
    }
    case spv::OpTypeBool:
    case spv::OpTypeVoid:
    case spv::OpTypeSampler:
    case spv::OpLabel:
    case spv::OpExtInstImport:
    case spv::OpTypePointer:
    case spv::OpTypeRuntimeArray:
    case spv::OpTypeStruct:
    case spv::OpTypeImage:
    case spv::OpTypeSampledImage:
    case spv::OpTypeInt:
    case spv::OpTypeFloat:
    case spv::OpTypeArray:
    case spv::OpTypeVector:
    case spv::OpTypeFunction: {
      WriteWordCountAndOpcode(Inst);
      WriteResultID(Inst);
      for (uint32_t i = 0; i < Ops.size(); i++) {
        WriteOperand(Ops[i]);
      }
      break;
    }
    case spv::OpFunction:
    case spv::OpFunctionParameter:
    case spv::OpAccessChain:
    case spv::OpPtrAccessChain:
    case spv::OpInBoundsAccessChain:
    case spv::OpUConvert:
    case spv::OpSConvert:
    case spv::OpConvertFToU:
    case spv::OpConvertFToS:
    case spv::OpConvertUToF:
    case spv::OpConvertSToF:
    case spv::OpFConvert:
    case spv::OpConvertPtrToU:
    case spv::OpConvertUToPtr:
    case spv::OpBitcast:
    case spv::OpIAdd:
    case spv::OpFAdd:
    case spv::OpISub:
    case spv::OpFSub:
    case spv::OpIMul:
    case spv::OpFMul:
    case spv::OpUDiv:
    case spv::OpSDiv:
    case spv::OpFDiv:
    case spv::OpUMod:
    case spv::OpSRem:
    case spv::OpFRem:
    case spv::OpUMulExtended:
    case spv::OpSMulExtended:
    case spv::OpBitwiseOr:
    case spv::OpBitwiseXor:
    case spv::OpBitwiseAnd:
    case spv::OpNot:
    case spv::OpShiftLeftLogical:
    case spv::OpShiftRightLogical:
    case spv::OpShiftRightArithmetic:
    case spv::OpBitCount:
    case spv::OpCompositeConstruct:
    case spv::OpCompositeExtract:
    case spv::OpVectorExtractDynamic:
    case spv::OpCompositeInsert:
    case spv::OpCopyObject:
    case spv::OpVectorInsertDynamic:
    case spv::OpVectorShuffle:
    case spv::OpIEqual:
    case spv::OpINotEqual:
    case spv::OpUGreaterThan:
    case spv::OpUGreaterThanEqual:
    case spv::OpULessThan:
    case spv::OpULessThanEqual:
    case spv::OpSGreaterThan:
    case spv::OpSGreaterThanEqual:
    case spv::OpSLessThan:
    case spv::OpSLessThanEqual:
    case spv::OpFOrdEqual:
    case spv::OpFOrdGreaterThan:
    case spv::OpFOrdGreaterThanEqual:
    case spv::OpFOrdLessThan:
    case spv::OpFOrdLessThanEqual:
    case spv::OpFOrdNotEqual:
    case spv::OpFUnordEqual:
    case spv::OpFUnordGreaterThan:
    case spv::OpFUnordGreaterThanEqual:
    case spv::OpFUnordLessThan:
    case spv::OpFUnordLessThanEqual:
    case spv::OpFUnordNotEqual:
    case spv::OpExtInst:
    case spv::OpIsInf:
    case spv::OpIsNan:
    case spv::OpAny:
    case spv::OpAll:
    case spv::OpUndef:
    case spv::OpConstantNull:
    case spv::OpLogicalOr:
    case spv::OpLogicalAnd:
    case spv::OpLogicalNot:
    case spv::OpLogicalNotEqual:
    case spv::OpConstantComposite:
    case spv::OpSpecConstantComposite:
    case spv::OpConstantTrue:
    case spv::OpConstantFalse:
    case spv::OpConstant:
    case spv::OpSpecConstant:
    case spv::OpVariable:
    case spv::OpFunctionCall:
    case spv::OpSampledImage:
    case spv::OpImageSampleExplicitLod:
    case spv::OpImageQuerySize:
    case spv::OpSelect:
    case spv::OpPhi:
    case spv::OpLoad:
    case spv::OpAtomicIAdd:
    case spv::OpAtomicISub:
    case spv::OpAtomicExchange:
    case spv::OpAtomicIIncrement:
    case spv::OpAtomicIDecrement:
    case spv::OpAtomicCompareExchange:
    case spv::OpAtomicUMin:
    case spv::OpAtomicSMin:
    case spv::OpAtomicUMax:
    case spv::OpAtomicSMax:
    case spv::OpAtomicAnd:
    case spv::OpAtomicOr:
    case spv::OpAtomicXor:
    case spv::OpDot: {
      WriteWordCountAndOpcode(Inst);
      WriteOperand(Ops[0]);
      WriteResultID(Inst);
      for (uint32_t i = 1; i < Ops.size(); i++) {
        WriteOperand(Ops[i]);
      }
      break;
    }
    }
  }
}

bool SPIRVProducerPass::IsTypeNullable(const Type *type) const {
  switch (type->getTypeID()) {
  case Type::HalfTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID:
  case Type::IntegerTyID:
  case Type::VectorTyID:
    return true;
  case Type::PointerTyID: {
    const PointerType *pointer_type = cast<PointerType>(type);
    if (pointer_type->getPointerAddressSpace() !=
        AddressSpace::UniformConstant) {
      auto pointee_type = pointer_type->getPointerElementType();
      if (pointee_type->isStructTy() &&
          cast<StructType>(pointee_type)->isOpaque()) {
        // Images and samplers are not nullable.
        return false;
      }
    }
    return true;
  }
  case Type::ArrayTyID:
    return IsTypeNullable(cast<CompositeType>(type)->getTypeAtIndex(0u));
  case Type::StructTyID: {
    const StructType *struct_type = cast<StructType>(type);
    // Images and samplers are not nullable.
    if (struct_type->isOpaque())
      return false;
    for (const auto element : struct_type->elements()) {
      if (!IsTypeNullable(element))
        return false;
    }
    return true;
  }
  default:
    return false;
  }
}

void SPIRVProducerPass::PopulateUBOTypeMaps(Module &module) {
  if (auto *offsets_md =
          module.getNamedMetadata(clspv::RemappedTypeOffsetMetadataName())) {
    // Metdata is stored as key-value pair operands. The first element of each
    // operand is the type and the second is a vector of offsets.
    for (const auto *operand : offsets_md->operands()) {
      const auto *pair = cast<MDTuple>(operand);
      auto *type =
          cast<ConstantAsMetadata>(pair->getOperand(0))->getValue()->getType();
      const auto *offset_vector = cast<MDTuple>(pair->getOperand(1));
      std::vector<uint32_t> offsets;
      for (const Metadata *offset_md : offset_vector->operands()) {
        const auto *constant_md = cast<ConstantAsMetadata>(offset_md);
        offsets.push_back(static_cast<uint32_t>(
            cast<ConstantInt>(constant_md->getValue())->getZExtValue()));
      }
      RemappedUBOTypeOffsets.insert(std::make_pair(type, offsets));
    }
  }

  if (auto *sizes_md =
          module.getNamedMetadata(clspv::RemappedTypeSizesMetadataName())) {
    // Metadata is stored as key-value pair operands. The first element of each
    // operand is the type and the second is a triple of sizes: type size in
    // bits, store size and alloc size.
    for (const auto *operand : sizes_md->operands()) {
      const auto *pair = cast<MDTuple>(operand);
      auto *type =
          cast<ConstantAsMetadata>(pair->getOperand(0))->getValue()->getType();
      const auto *size_triple = cast<MDTuple>(pair->getOperand(1));
      uint64_t type_size_in_bits =
          cast<ConstantInt>(
              cast<ConstantAsMetadata>(size_triple->getOperand(0))->getValue())
              ->getZExtValue();
      uint64_t type_store_size =
          cast<ConstantInt>(
              cast<ConstantAsMetadata>(size_triple->getOperand(1))->getValue())
              ->getZExtValue();
      uint64_t type_alloc_size =
          cast<ConstantInt>(
              cast<ConstantAsMetadata>(size_triple->getOperand(2))->getValue())
              ->getZExtValue();
      RemappedUBOTypeSizes.insert(std::make_pair(
          type, std::make_tuple(type_size_in_bits, type_store_size,
                                type_alloc_size)));
    }
  }
}

uint64_t SPIRVProducerPass::GetTypeSizeInBits(Type *type,
                                              const DataLayout &DL) {
  auto iter = RemappedUBOTypeSizes.find(type);
  if (iter != RemappedUBOTypeSizes.end()) {
    return std::get<0>(iter->second);
  }

  return DL.getTypeSizeInBits(type);
}

uint64_t SPIRVProducerPass::GetTypeStoreSize(Type *type, const DataLayout &DL) {
  auto iter = RemappedUBOTypeSizes.find(type);
  if (iter != RemappedUBOTypeSizes.end()) {
    return std::get<1>(iter->second);
  }

  return DL.getTypeStoreSize(type);
}

uint64_t SPIRVProducerPass::GetTypeAllocSize(Type *type, const DataLayout &DL) {
  auto iter = RemappedUBOTypeSizes.find(type);
  if (iter != RemappedUBOTypeSizes.end()) {
    return std::get<2>(iter->second);
  }

  return DL.getTypeAllocSize(type);
}

void SPIRVProducerPass::setVariablePointersCapabilities(
    unsigned address_space) {
  if (GetStorageClass(address_space) == spv::StorageClassStorageBuffer) {
    setVariablePointersStorageBuffer(true);
  } else {
    setVariablePointers(true);
  }
}

Value *SPIRVProducerPass::GetBasePointer(Value *v) {
  if (auto *gep = dyn_cast<GetElementPtrInst>(v)) {
    return GetBasePointer(gep->getPointerOperand());
  }

  // Conservatively return |v|.
  return v;
}

bool SPIRVProducerPass::sameResource(Value *lhs, Value *rhs) const {
  if (auto *lhs_call = dyn_cast<CallInst>(lhs)) {
    if (auto *rhs_call = dyn_cast<CallInst>(rhs)) {
      if (lhs_call->getCalledFunction()->getName().startswith(
              clspv::ResourceAccessorFunction()) &&
          rhs_call->getCalledFunction()->getName().startswith(
              clspv::ResourceAccessorFunction())) {
        // For resource accessors, match descriptor set and binding.
        if (lhs_call->getOperand(0) == rhs_call->getOperand(0) &&
            lhs_call->getOperand(1) == rhs_call->getOperand(1))
          return true;
      } else if (lhs_call->getCalledFunction()->getName().startswith(
                     clspv::WorkgroupAccessorFunction()) &&
                 rhs_call->getCalledFunction()->getName().startswith(
                     clspv::WorkgroupAccessorFunction())) {
        // For workgroup resources, match spec id.
        if (lhs_call->getOperand(0) == rhs_call->getOperand(0))
          return true;
      }
    }
  }

  return false;
}

bool SPIRVProducerPass::selectFromSameObject(Instruction *inst) {
  assert(inst->getType()->isPointerTy());
  assert(GetStorageClass(inst->getType()->getPointerAddressSpace()) ==
         spv::StorageClassStorageBuffer);
  const bool hack_undef = clspv::Option::HackUndef();
  if (auto *select = dyn_cast<SelectInst>(inst)) {
    auto *true_base = GetBasePointer(select->getTrueValue());
    auto *false_base = GetBasePointer(select->getFalseValue());

    if (true_base == false_base)
      return true;

    // If either the true or false operand is a null, then we satisfy the same
    // object constraint.
    if (auto *true_cst = dyn_cast<Constant>(true_base)) {
      if (true_cst->isNullValue() || (hack_undef && isa<UndefValue>(true_base)))
        return true;
    }

    if (auto *false_cst = dyn_cast<Constant>(false_base)) {
      if (false_cst->isNullValue() ||
          (hack_undef && isa<UndefValue>(false_base)))
        return true;
    }

    if (sameResource(true_base, false_base))
      return true;
  } else if (auto *phi = dyn_cast<PHINode>(inst)) {
    Value *value = nullptr;
    bool ok = true;
    for (unsigned i = 0; ok && i != phi->getNumIncomingValues(); ++i) {
      auto *base = GetBasePointer(phi->getIncomingValue(i));
      // Null values satisfy the constraint of selecting of selecting from the
      // same object.
      if (!value) {
        if (auto *cst = dyn_cast<Constant>(base)) {
          if (!cst->isNullValue() && !(hack_undef && isa<UndefValue>(base)))
            value = base;
        } else {
          value = base;
        }
      } else if (base != value) {
        if (auto *base_cst = dyn_cast<Constant>(base)) {
          if (base_cst->isNullValue() || (hack_undef && isa<UndefValue>(base)))
            continue;
        }

        if (sameResource(value, base))
          continue;

        // Values don't represent the same base.
        ok = false;
      }
    }

    return ok;
  }

  // Conservatively return false.
  return false;
}

bool SPIRVProducerPass::CalledWithCoherentResource(Argument &Arg) {
  if (!Arg.getType()->isPointerTy() ||
      Arg.getType()->getPointerAddressSpace() != clspv::AddressSpace::Global) {
    // Only SSBOs need to be annotated as coherent.
    return false;
  }

  DenseSet<Value *> visited;
  std::vector<Value *> stack;
  for (auto *U : Arg.getParent()->users()) {
    if (auto *call = dyn_cast<CallInst>(U)) {
      stack.push_back(call->getOperand(Arg.getArgNo()));
    }
  }

  while (!stack.empty()) {
    Value *v = stack.back();
    stack.pop_back();

    if (!visited.insert(v).second)
      continue;

    auto *resource_call = dyn_cast<CallInst>(v);
    if (resource_call &&
        resource_call->getCalledFunction()->getName().startswith(
            clspv::ResourceAccessorFunction())) {
      // If this is a resource accessor function, check if the coherent operand
      // is set.
      const auto coherent =
          unsigned(dyn_cast<ConstantInt>(resource_call->getArgOperand(5))
                       ->getZExtValue());
      if (coherent == 1)
        return true;
    } else if (auto *arg = dyn_cast<Argument>(v)) {
      // If this is a function argument, trace through its callers.
      for (auto U : arg->getParent()->users()) {
        if (auto *call = dyn_cast<CallInst>(U)) {
          stack.push_back(call->getOperand(arg->getArgNo()));
        }
      }
    } else if (auto *user = dyn_cast<User>(v)) {
      // If this is a user, traverse all operands that could lead to resource
      // variables.
      for (unsigned i = 0; i != user->getNumOperands(); ++i) {
        Value *operand = user->getOperand(i);
        if (operand->getType()->isPointerTy() &&
            operand->getType()->getPointerAddressSpace() ==
                clspv::AddressSpace::Global) {
          stack.push_back(operand);
        }
      }
    }
  }

  // No coherent resource variables encountered.
  return false;
}
