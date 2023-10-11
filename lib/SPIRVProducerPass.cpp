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
#include <unordered_map>
#include <unordered_set>
#include <utility>

#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/UniqueVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Pass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Cloning.h"

// enable spv::HasResultAndType
#define SPV_ENABLE_UTILITY_CODE
#include "spirv/unified1/spirv.hpp"

#include "clspv/AddressSpace.h"
#include "clspv/Option.h"
#include "clspv/PushConstant.h"
#include "clspv/SpecConstant.h"
#include "clspv/spirv_c_strings.hpp"
#include "clspv/spirv_glsl.hpp"
#include "clspv/spirv_reflection.hpp"

#include "ArgKind.h"
#include "Builtins.h"
#include "ComputeStructuredOrder.h"
#include "ConstantEmitter.h"
#include "Constants.h"
#include "DescriptorCounter.h"
#include "Layout.h"
#include "NormalizeGlobalVariable.h"
#include "Passes.h"
#include "SpecConstant.h"
#include "Types.h"

#if defined(_MSC_VER)
#pragma warning(pop)
#endif

using namespace llvm;
using namespace clspv;
using namespace clspv::Builtins;
using namespace clspv::Option;
using namespace mdconst;

namespace {

cl::opt<std::string> TestOutFile("producer-out-file", cl::init("test.spv"),
                                 cl::ReallyHidden,
                                 cl::desc("SPIRVProducer testing output file"));

cl::opt<bool> ShowResourceVars("show-rv", cl::init(false), cl::Hidden,
                               cl::desc("Show resource variable creation"));

cl::opt<bool>
    ShowProducerIR("show-producer-ir", cl::init(false), cl::ReallyHidden,
                   cl::desc("Dump the IR at the start of SPIRVProducer"));

cl::opt<bool>
    NameBasicBlocks("name-basic-blocks", cl::init(false), cl::ReallyHidden,
                    cl::desc("Name SPIR-V basic blocks based on LLVM names"));

// These hacks exist to help transition code generation algorithms
// without making huge noise in detailed test output.
const bool Hack_generate_runtime_array_stride_early = true;

// The value of 1/pi.  This value is from MSDN
// https://msdn.microsoft.com/en-us/library/4hwaceh6.aspx
const double kOneOverPi = 0.318309886183790671538;

// SPIRV Module Sections (per 2.4 of the SPIR-V spec)
// These are used to collect SPIRVInstructions by type on-the-fly.
enum SPIRVSection {
  kCapabilities,
  kExtensions,
  kImports,
  kMemoryModel,
  kEntryPoints,
  kExecutionModes,

  kDebug,
  kNames,
  kAnnotations,

  kTypes,
  kConstants = kTypes,
  kGlobalVariables,

  kFunctions,

  // This is not a section of the SPIR-V spec and should always immediately
  // precede kSectionCount. It is a convenient place for the embedded
  // reflection data.
  kReflection,
  kSectionCount
};

class SPIRVID {
  uint32_t id;

public:
  SPIRVID(uint32_t _id = 0) : id(_id) {}
  uint32_t get() const { return id; }
  bool isValid() const { return id != 0; }
  bool operator==(const SPIRVID &that) const { return id == that.id; }
  bool operator<(const SPIRVID &that) const { return id < that.id; }
};

enum SPIRVOperandType { NUMBERID, LITERAL_WORD, LITERAL_DWORD, LITERAL_STRING };

struct SPIRVOperand {
  SPIRVOperand(SPIRVOperandType Ty, uint32_t Num) : Type(Ty) {
    LiteralNum[0] = Num;
  }
  SPIRVOperand(SPIRVOperandType Ty, const char *Str)
      : Type(Ty), LiteralStr(Str) {}
  SPIRVOperand(SPIRVOperandType Ty, StringRef Str)
      : Type(Ty), LiteralStr(Str) {}
  explicit SPIRVOperand(ArrayRef<uint32_t> NumVec) {
    auto sz = NumVec.size();
    assert(sz >= 1 && sz <= 2);
    Type = sz == 1 ? LITERAL_WORD : LITERAL_DWORD;
    LiteralNum[0] = NumVec[0];
    if (sz == 2) {
      LiteralNum[1] = NumVec[1];
    }
  }

  SPIRVOperandType getType() const { return Type; }
  uint32_t getNumID() const { return LiteralNum[0]; }
  std::string getLiteralStr() const { return LiteralStr; }
  const uint32_t *getLiteralNum() const { return LiteralNum; }

  uint32_t GetNumWords() const {
    switch (Type) {
    case NUMBERID:
    case LITERAL_WORD:
      return 1;
    case LITERAL_DWORD:
      return 2;
    case LITERAL_STRING:
      // Account for the terminating null character.
      return uint32_t((LiteralStr.size() + 4) / 4);
    }
    llvm_unreachable("Unhandled case in SPIRVOperand::GetNumWords()");
  }

private:
  SPIRVOperandType Type;
  std::string LiteralStr;
  uint32_t LiteralNum[2];
};

typedef SmallVector<SPIRVOperand, 4> SPIRVOperandVec;

namespace {

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, const SPIRVID &v) {
  list.emplace_back(NUMBERID, v.get());
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, uint32_t num) {
  list.emplace_back(LITERAL_WORD, num);
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, int32_t num) {
  list.emplace_back(LITERAL_WORD, static_cast<uint32_t>(num));
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list,
                            const std::vector<uint32_t> &num_vec) {
  list.emplace_back(num_vec);
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, StringRef str) {
  list.emplace_back(LITERAL_STRING, str);
  return list;
}

} // namespace

struct SPIRVInstruction {
  // Primary constructor must have Opcode, initializes WordCount based on ResID.
  SPIRVInstruction(spv::Op Opc, SPIRVID ResID = 0)
      : Opcode(static_cast<uint16_t>(Opc)) {
    setResult(ResID);
  }

  // Creates an instruction with an opcode and no result ID, and with the given
  // operands.  This calls primary constructor to initialize Opcode, WordCount.
  // Takes ownership of the operands and clears |Ops|.
  SPIRVInstruction(spv::Op Opc, SPIRVOperandVec &Ops) : SPIRVInstruction(Opc) {
    setOperands(Ops);
  }
  // Creates an instruction with an opcode and no result ID, and with the given
  // operands.  This calls primary constructor to initialize Opcode, WordCount.
  // Takes ownership of the operands and clears |Ops|.
  SPIRVInstruction(spv::Op Opc, SPIRVID ResID, SPIRVOperandVec &Ops)
      : SPIRVInstruction(Opc, ResID) {
    setOperands(Ops);
  }

  uint32_t getWordCount() const { return WordCount; }
  uint16_t getOpcode() const { return Opcode; }
  SPIRVID getResultID() const { return ResultID; }
  const SPIRVOperandVec &getOperands() const { return Operands; }

private:
  void setResult(SPIRVID ResID = 0) {
    WordCount = 1 + (ResID.isValid() ? 1 : 0);
    ResultID = ResID;
  }

  void setOperands(SPIRVOperandVec &Ops) {
    assert(Operands.empty());
    Operands = std::move(Ops);
    for (auto &opd : Operands) {
      WordCount += uint16_t(opd.GetNumWords());
    }
  }

private:
  uint32_t WordCount; // Check the 16-bit bound at code generation time.
  uint16_t Opcode;
  SPIRVID ResultID;
  SPIRVOperandVec Operands;
};

struct SPIRVProducerPassImpl {

  // Struct to handle generation of ArrayStride decorations.
  struct StrideType {
    uint32_t stride;
    SPIRVID id;

    StrideType(uint32_t stride, SPIRVID id) : stride(stride), id(id) {}

    bool operator<(const StrideType &x) const {
      if (stride < x.stride)
        return true;
      if (x.stride < stride)
        return false;
      return id.get() < x.id.get();
    }
  };

  typedef DenseMap<Type *, SPIRVID> TypeMapType;
  typedef DenseMap<Type *, SmallVector<SPIRVID, 2>> LayoutTypeMapType;
  typedef UniqueVector<Type *> TypeList;
  typedef UniqueVector<StrideType> StrideTypeList;
  typedef DenseMap<Value *, SPIRVID> ValueMapType;
  typedef DenseMap<DIFile *, SPIRVID> DIFileMap;
  typedef DenseMap<BasicBlock *, std::pair<uint32_t, uint32_t>> BBDILocMap;
  typedef std::list<SPIRVID> SPIRVIDListType;
  typedef std::vector<std::pair<Value *, SPIRVID>> EntryPointVecType;
  typedef std::set<uint32_t> CapabilitySetType;
  typedef std::list<SPIRVInstruction> SPIRVInstructionList;
  typedef std::map<spv::BuiltIn, SPIRVID> BuiltinConstantMapType;
  // A vector of pairs, each of which is:
  // - the LLVM instruction that we will later generate SPIR-V code for
  // - the SPIR-V instruction placeholder that will be replaced
  typedef std::vector<std::pair<Value *, SPIRVInstruction *>>
      DeferredInstVecType;
  typedef DenseMap<FunctionType *, std::pair<FunctionType *, uint32_t>>
      GlobalConstFuncMapType;

  SPIRVProducerPassImpl(raw_pwrite_stream *out, bool outputCInitList,
                        ModuleAnalysisManager &MAM)
      : module(nullptr), MAM(&MAM), out(out),
        binaryTempOut(binaryTempUnderlyingVector), binaryOut(out),
        outputCInitList(outputCInitList), patchBoundOffset(0), nextID(1),
        OpExtInstImportID(0), HasVariablePointersStorageBuffer(false),
        HasVariablePointers(false), HasNonUniformPointers(false),
        HasConvertToF(false), SamplerPointerTy(nullptr), SamplerDataTy(nullptr),
        WorkgroupSizeValueID(0), WorkgroupSizeVarID(0),
        TestOutput(out == nullptr) {
    addCapability(spv::CapabilityShader);
    if (clspv::Option::PhysicalStorageBuffers())
      addCapability(spv::CapabilityPhysicalStorageBufferAddresses);
    Ptr = this;
  }

  SPIRVProducerPassImpl()
      : module(nullptr), out(nullptr),
        binaryTempOut(binaryTempUnderlyingVector), binaryOut(nullptr),
        outputCInitList(false), patchBoundOffset(0), nextID(1),
        OpExtInstImportID(0), HasVariablePointersStorageBuffer(false),
        HasVariablePointers(false), HasNonUniformPointers(false),
        HasConvertToF(false), SamplerPointerTy(nullptr), SamplerDataTy(nullptr),
        WorkgroupSizeValueID(0), WorkgroupSizeVarID(0), TestOutput(true) {
    if (clspv::Option::PhysicalStorageBuffers())
      addCapability(spv::CapabilityPhysicalStorageBufferAddresses);
    addCapability(spv::CapabilityShader);
    Ptr = this;
  }

  bool runOnModule(Module &module);

  // output the SPIR-V header block
  void outputHeader();

  // patch the SPIR-V header block
  void patchHeader();

  CapabilitySetType &getCapabilitySet() { return CapabilitySet; }
  TypeMapType &getImageTypeMap() { return ImageTypeMap; }
  ValueMapType &getValueMap() { return ValueMap; }
  DIFileMap &getDebugDIFileMap() { return DebugDIFileMap; }
  BBDILocMap &getBBDILocMap() { return DebugBBDILocMap; }
  SPIRVInstructionList &getSPIRVInstList(SPIRVSection Section) {
    return SPIRVSections[Section];
  };
  EntryPointVecType &getEntryPointVec() { return EntryPointVec; }
  DeferredInstVecType &getDeferredInstVec() { return DeferredInstVec; }
  SPIRVIDListType &getEntryPointInterfacesList() {
    return EntryPointInterfacesList;
  }
  SPIRVID getOpExtInstImportID();
  std::vector<SPIRVID> &getBuiltinDimVec() { return BuiltinDimensionVec; }

  bool hasVariablePointersStorageBuffer() {
    return HasVariablePointersStorageBuffer;
  }
  void setVariablePointersStorageBuffer() {
    if (!HasVariablePointersStorageBuffer) {
      addCapability(spv::CapabilityVariablePointersStorageBuffer);
      HasVariablePointersStorageBuffer = true;
    }
  }
  bool hasVariablePointers() { return HasVariablePointers; }
  void setVariablePointers() {
    if (!HasVariablePointers) {
      addCapability(spv::CapabilityVariablePointers);
      HasVariablePointers = true;
    }
  }
  bool hasNonUniformPointers() { return HasNonUniformPointers; }
  void setNonUniformPointers() {
    if (!HasNonUniformPointers) {
      addCapability(spv::CapabilityShaderNonUniform);
      HasNonUniformPointers = true;
    }
  }
  bool hasConvertToF() { return HasConvertToF; }
  void setConvertToF() {
    if (!HasConvertToF &&
        (ExecutionModeRoundingModeRTE(RoundingModeRTE::fp16) ||
         ExecutionModeRoundingModeRTE(RoundingModeRTE::fp32) ||
         ExecutionModeRoundingModeRTE(RoundingModeRTE::fp64))) {
      addCapability(spv::CapabilityRoundingModeRTE);
      HasConvertToF = true;
    }
  }
  GlobalConstFuncMapType &getGlobalConstFuncTypeMap() {
    return GlobalConstFuncTypeMap;
  }
  SmallPtrSet<Value *, 16> &getGlobalConstArgSet() {
    return GlobalConstArgumentSet;
  }
  StrideTypeList &getTypesNeedingArrayStride() { return TypesNeedingArrayStride; }

  void ReadFunctionAttributes();

  void GenerateLLVMIRInfo();
  // Populate GlobalConstFuncTypeMap. Also, if module-scope __constant will
  // *not* be converted to a storage buffer, replace each such global variable
  // with one in the storage class expecgted by SPIR-V.
  void FindGlobalConstVars();
  // Populate ResourceVarInfoList, FunctionToResourceVarsMap, and
  // ModuleOrderedResourceVars.
  void FindResourceVars();
  void FindTypesForSamplerMap();
  void FindTypesForResourceVars();

  // Lookup or create pointer type.
  //
  // Returns the SPIRVID of the pointer type.
  SPIRVID getSPIRVPointerType(Type *PtrTy, Type *DataTy);

  // Lookup or create function type.
  //
  // Returns the SPIRVID of the function type.
  // Defers to getSPIRVType if the function type doesn't use opaque pointer
  // types.
  SPIRVID getSPIRVFunctionType(FunctionType *FTy, Type *RetTy,
                               ArrayRef<Type *> ParamTys);

  // Returns the canonical type of |type|.
  //
  // By default, clspv maps both __constant and __global address space pointers
  // to StorageBuffer storage class. In order to prevent duplicate types from
  // being generated, clspv uses the canonical type as a representative.
  Type *CanonicalType(Type *type);

  // Lookup or create Types, Constants.
  // Returns SPIRVID once it has been created.
  SPIRVID getSPIRVType(Type *Ty, bool needs_layout);
  SPIRVID getSPIRVType(Type *Ty);
  SPIRVID getSPIRVConstant(Constant *Cst);
  SPIRVID getSPIRVInt32Constant(uint32_t CstVal);
  SPIRVID getSPIRVInt64Constant(uint64_t CstVal);
  // Lookup SPIRVID of llvm::Value, may create Constant.
  SPIRVID getSPIRVValue(Value *V);

  bool PointerRequiresLayout(unsigned aspace);

  SPIRVID getSPIRVBuiltin(spv::BuiltIn BID, spv::Capability Cap);

  void GenerateModuleInfo();
  void GenerateGlobalVar(GlobalVariable &GV);
  void GenerateWorkgroupVars();
  // Generate reflection instructions for resource variables associated with
  // arguments to F.
  void GenerateSamplers();
  // Generate OpVariables for %clspv.resource.var.* calls.
  void GenerateResourceVars();
  void GenerateFuncPrologue(Function &F);
  void GenerateFuncBody(Function &F);
  void GenerateEntryPointInitialStores();
  spv::Op GetSPIRVCmpOpcode(CmpInst *CmpI);
  spv::Op GetSPIRVPointerCmpOpcode(CmpInst *CmpI);
  spv::Op GetSPIRVCastOpcode(Instruction &I);
  spv::Op GetSPIRVBinaryOpcode(Instruction &I);
  SPIRVID GenerateClspvInstruction(CallInst *Call,
                                   const FunctionInfo &FuncInfo);
  SPIRVID GenerateImageInstruction(CallInst *Call,
                                   const FunctionInfo &FuncInfo);
  SPIRVID GenerateSubgroupInstruction(CallInst *Call,
                                      const FunctionInfo &FuncInfo);
  SPIRVID GenerateInstructionFromCall(CallInst *Call);
  SPIRVID GenerateShuffle2FromCall(Type *Ty, Value *SrcA, Value *SrcB,
                                   Value *Mask);
  SPIRVID GeneratePopcount(Type *Ty, Value *BaseValue, LLVMContext &Context);
  void GenerateInstruction(Instruction &I);
  void GenerateFuncEpilogue();
  void HandleDeferredInstruction();
  void HandleDeferredDecorations();
  bool is4xi8vec(Type *Ty) const;
  spv::StorageClass GetStorageBufferClass() const;
  spv::StorageClass GetStorageClass(unsigned AddrSpace) const;
  spv::StorageClass GetStorageClassForArgKind(clspv::ArgKind arg_kind) const;
  spv::BuiltIn GetBuiltin(StringRef globalVarName) const;
  void WriteOneWord(uint32_t Word);
  void WriteResultID(const SPIRVInstruction &Inst);
  void WriteWordCountAndOpcode(const SPIRVInstruction &Inst);
  void WriteOperand(const SPIRVOperand &Op);
  void WriteSPIRVBinary();
  void WriteSPIRVBinary(SPIRVInstructionList &SPIRVInstList);

  // Returns true if |type| is compatible with OpConstantNull.
  bool IsTypeNullable(const Type *type) const;

  // Populate UBO remapped type maps.
  void PopulateUBOTypeMaps();

  // Populate the merge and continue block maps.
  void PopulateStructuredCFGMaps();

  // Wrapped methods of DataLayout accessors. If |type| was remapped for UBOs,
  // uses the internal map, otherwise it falls back on the data layout.
  uint64_t GetTypeSizeInBits(Type *type, const DataLayout &DL);
  uint64_t GetTypeAllocSize(Type *type, const DataLayout &DL);
  uint32_t GetExplicitLayoutStructMemberOffset(StructType *type,
                                               unsigned member,
                                               const DataLayout &DL);

  // Returns the base pointer of |v|.
  Value *GetBasePointer(Value *v);

  // Add Capability if not already (e.g. CapabilityGroupNonUniformBroadcast)
  void addCapability(uint32_t c) { CapabilitySet.emplace(c); }

  // Sets |HasVariablePointersStorageBuffer| or |HasVariablePointers| base on
  // |address_space|.
  void setVariablePointersCapabilities(unsigned address_space);

  // Returns true if |lhs| and |rhs| represent the same resource or workgroup
  // variable.
  bool sameResource(Value *lhs, Value *rhs) const;

  // Returns true if |inst| is phi or select that selects from the same
  // structure (or null).
  bool selectFromSameObject(Instruction *inst);

  bool isPointerUniform(Value *ptr);

  // Returns true if |Arg| is called with a coherent resource.
  bool CalledWithCoherentResource(Argument &Arg);

  bool NeedDecorationNoContraction(spv::Op op) {
    spv::Op list[] = {spv::OpFMul, spv::OpFDiv, spv::OpFNegate,
                      spv::OpFAdd, spv::OpFSub, spv::OpFRem};
    for (auto opf : list) {
      if (op == opf)
        return true;
    }
    return false;
  }

  //
  // Primary interface for adding SPIRVInstructions to a SPIRVSection.
  template <enum SPIRVSection TSection = kFunctions>
  SPIRVID addSPIRVInst(spv::Op Opcode, SPIRVOperandVec &Operands) {
    bool has_result, has_result_type;
    spv::HasResultAndType(Opcode, &has_result, &has_result_type);
    SPIRVID RID = has_result ? incrNextID() : 0;
    SPIRVSections[TSection].emplace_back(Opcode, RID, Operands);

    if (NeedDecorationNoContraction(Opcode) && !Option::UnsafeMath()) {
      SPIRVOperandVec Ops;
      Ops << RID << spv::DecorationNoContraction;
      addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
    }
    return RID;
  }
  template <enum SPIRVSection TSection = kFunctions>
  SPIRVID addSPIRVInst(spv::Op Op) {
    SPIRVOperandVec Ops;
    return addSPIRVInst<TSection>(Op, Ops);
  }
  template <enum SPIRVSection TSection = kFunctions>
  SPIRVID addSPIRVInst(spv::Op Op, uint32_t V) {
    SPIRVOperandVec Ops;
    Ops.emplace_back(LITERAL_WORD, V);
    return addSPIRVInst<TSection>(Op, Ops);
  }
  template <enum SPIRVSection TSection = kFunctions>
  SPIRVID addSPIRVInst(spv::Op Op, const char *V) {
    SPIRVOperandVec Ops;
    Ops.emplace_back(LITERAL_STRING, V);
    return addSPIRVInst<TSection>(Op, Ops);
  }

  //
  // Add placeholder for llvm::Value that references future values.
  // Must have result ID just in case final SPIRVInstruction requires.
  SPIRVID addSPIRVPlaceholder(Value *I) {
    SPIRVID RID = incrNextID();
    SPIRVOperandVec Ops;
    SPIRVSections[kFunctions].emplace_back(spv::OpExtInst, RID, Ops);
    DeferredInstVec.push_back({I, &SPIRVSections[kFunctions].back()});
    return RID;
  }
  // Replace placeholder with actual SPIRVInstruction on the final pass
  // (HandleDeferredInstruction).
  SPIRVID replaceSPIRVInst(SPIRVInstruction *I, spv::Op Opcode,
                           SPIRVOperandVec &Operands) {
    bool has_result, has_result_type;
    spv::HasResultAndType(Opcode, &has_result, &has_result_type);
    SPIRVID RID = has_result ? I->getResultID() : 0;
    *I = SPIRVInstruction(Opcode, RID, Operands);
    return RID;
  }

  //
  // Add global variable and capture entry point interface
  SPIRVID addSPIRVGlobalVariable(const SPIRVID &TypeID, spv::StorageClass SC,
                                 const SPIRVID &InitID = SPIRVID(),
                                 bool add_interface = false);

  SPIRVID getReflectionImport();
  void GenerateReflection();
  void GenerateKernelReflection();
  void GeneratePrintfReflection();
  void GeneratePushConstantReflection();
  void GenerateSpecConstantReflection();
  void AddArgumentReflection(const Function &F, SPIRVID kernel_decl,
                             const std::string &name, clspv::ArgKind arg_kind,
                             uint32_t ordinal, uint32_t descriptor_set,
                             uint32_t binding, uint32_t offset, uint32_t size,
                             uint32_t spec_id, uint32_t elem_size);

private:
  Module *module;

  // Set of Capabilities required
  CapabilitySetType CapabilitySet;

  // Map from clspv::BuiltinType to SPIRV Global Variable
  BuiltinConstantMapType BuiltinConstantMap;

  ModuleAnalysisManager *MAM;
  raw_pwrite_stream *out;

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
  const bool outputCInitList; // If true, output look like {0x7023, ... , 5}
  uint64_t patchBoundOffset;
  uint32_t nextID;

  SPIRVID incrNextID() { return nextID++; }

  // ID for OpTypeInt 32 1.
  SPIRVID int32ID;
  // ID for OpTypeVector %int 4.
  SPIRVID v4int32ID;

  DenseMap<Value *, Type *> InferredTypeCache;
  std::unordered_map<unsigned, LayoutTypeMapType> PointerTypeMap;
  TypeMapType FunctionTypeMap;

  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  LayoutTypeMapType TypeMap;
  // Maps an LLVM image type to its SPIR-V ID.
  TypeMapType ImageTypeMap;
  // A unique-vector of LLVM types that map to a SPIR-V type.
  TypeList Types;
  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  ValueMapType ValueMap;
  DIFileMap DebugDIFileMap;
  BBDILocMap DebugBBDILocMap;
  SPIRVInstructionList SPIRVSections[kSectionCount];

  EntryPointVecType EntryPointVec;
  DeferredInstVecType DeferredInstVec;
  SPIRVIDListType EntryPointInterfacesList;
  SPIRVID OpExtInstImportID;
  std::vector<SPIRVID> BuiltinDimensionVec;
  bool HasVariablePointersStorageBuffer;
  bool HasVariablePointers;
  std::set<Value *> NonUniformPointers;
  bool HasNonUniformPointers;
  bool HasConvertToF;
  Type *SamplerPointerTy;
  Type *SamplerDataTy;
  DenseMap<unsigned, SPIRVID> SamplerLiteralToIDMap;

  // If a function F has a pointer-to-__constant parameter, then this variable
  // will map F's type to (G, index of the parameter), where in a first phase
  // G is F's type.
  // TODO(dneto): This doesn't seem general enough?  A function might have
  // more than one such parameter.
  GlobalConstFuncMapType GlobalConstFuncTypeMap;
  SmallPtrSet<Value *, 16> GlobalConstArgumentSet;
  // An ordered set of pointer types of Base arguments to OpPtrAccessChain,
  // or array types, and which point into transparent memory (StorageBuffer
  // storage class).  These will require an ArrayStride decoration.
  // See SPV_KHR_variable_pointers rev 13.
  StrideTypeList TypesNeedingArrayStride;

  // This is truly ugly, but works around what look like driver bugs.
  // For get_local_size, an earlier part of the flow has created a module-scope
  // variable in Private address space to hold the value for the workgroup
  // size.  Its intializer is a uint3 value marked as builtin WorkgroupSize.
  // When this is present, save the IDs of the initializer value and variable
  // in these two variables.  We only ever do a vector load from it, and
  // when we see one of those, substitute just the value of the intializer.
  // This mimics what Glslang does, and that's what drivers are used to.
  // TODO(dneto): Remove this once drivers are fixed.
  SPIRVID WorkgroupSizeValueID;
  SPIRVID WorkgroupSizeVarID;

  bool TestOutput;

  // Bookkeeping for mapping kernel arguments to resource variables.
  struct ResourceVarInfo {
    ResourceVarInfo(int index_arg, unsigned set_arg, unsigned binding_arg,
                    Function *fn, clspv::ArgKind arg_kind_arg, int coherent_arg,
                    Type *type)
        : index(index_arg), descriptor_set(set_arg), binding(binding_arg),
          var_fn(fn), arg_kind(arg_kind_arg), coherent(coherent_arg),
          data_type(type),
          addr_space(type->isPointerTy() ? type->getPointerAddressSpace() : 0) {
    }
    const int index; // Index into ResourceVarInfoList
    const unsigned descriptor_set;
    const unsigned binding;
    Function *const var_fn; // The @clspv.resource.var.* function.
    const clspv::ArgKind arg_kind;
    const int coherent;
    Type *data_type;
    const unsigned addr_space; // The LLVM address space
    // The SPIR-V ID of the OpVariable.  Not populated at construction time.
    SPIRVID var_id;
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
  DenseMap<CallInst *, SPIRVID> ResourceVarDeferredLoadCalls;

  // An ordered list of the kernel arguments of type pointer-to-local.
  using LocalArgList = SmallVector<Argument *, 8>;
  LocalArgList LocalArgs;
  // Information about a pointer-to-local argument.
  struct LocalArgInfo {
    // The SPIR-V ID of the array variable.
    SPIRVID variable_id;
    // The element type of the
    Type *elem_type;
    // The ID of the array type.
    SPIRVID array_size_id;
    // The ID of the array type.
    SPIRVID array_type_id;
    // The ID of the pointer to the array type.
    SPIRVID ptr_array_type_id;
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

  // Maps basic block to its merge block.
  DenseMap<BasicBlock *, BasicBlock *> MergeBlocks;
  // Maps basic block to its continue block.
  DenseMap<BasicBlock *, BasicBlock *> ContinueBlocks;

  SPIRVID ReflectionID;
  DenseMap<Function *, SPIRVID> KernelDeclarations;

  StringMap<std::string> functionAttrStrings;

public:
  static SPIRVProducerPassImpl *Ptr;
};

} // namespace

SPIRVProducerPassImpl *SPIRVProducerPassImpl::Ptr = nullptr;

namespace {

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, Type *t) {
  list.emplace_back(NUMBERID,
                    SPIRVProducerPassImpl::Ptr->getSPIRVType(t).get());
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, Value *v) {
  list.emplace_back(NUMBERID,
                    SPIRVProducerPassImpl::Ptr->getSPIRVValue(v).get());
  return list;
}

} // namespace

void SPIRVProducerPassImpl::ReadFunctionAttributes() {
  auto md_node =
      module->getNamedMetadata(clspv::EntryPointAttributesMetadataName());
  if (md_node) {
    for (auto *operand : md_node->operands()) {
      auto key = cast<MDString>(operand->getOperand(0).get())->getString();
      auto value = cast<MDString>(operand->getOperand(1).get())->getString();
      functionAttrStrings[key] = value;
    }
  }
}

PreservedAnalyses SPIRVProducerPass::run(Module &M,
                                         ModuleAnalysisManager &MAM) {
  // We do not wish to deal with any constexpr
  for (auto &F : M.functions()) {
    BitcastUtils::RemoveCstExprFromFunction(&F);
  }
  SPIRVProducerPassImpl impl(out, outputCInitList, MAM);
  impl.runOnModule(M);
  PreservedAnalyses PA;
  return PA;
}

bool SPIRVProducerPassImpl::runOnModule(Module &M) {

  // TODO(sjw): Need to reset all data members for each Module, or better
  // yet create a new SPIRVProducer for every module.. For now only
  // allow 1 call.
  assert(module == nullptr);
  module = &M;
  if (ShowProducerIR) {
    llvm::outs() << *module << "\n";
  }

  SmallVector<char, 10000> *binary = nullptr;
  if (TestOutput) {
    binary = new SmallVector<char, 10000>();
    out = new raw_svector_ostream(*binary);
  }

  binaryOut = outputCInitList ? &binaryTempOut : out;

  NonUniformPointers.clear();

  ReadFunctionAttributes();
  PopulateUBOTypeMaps();
  PopulateStructuredCFGMaps();

  // SPIR-V always begins with its header information
  outputHeader();

  // Gather information from the LLVM IR that we require.
  GenerateLLVMIRInfo();

  // Collect information on global variables too.
  for (GlobalVariable &GV : module->globals()) {
    // If the GV is one of our special __spirv_* variables, remove the
    // initializer as it was only placed there to force LLVM to not throw the
    // value away.
    if (GV.getName().startswith("__spirv_") ||
        GV.getAddressSpace() == clspv::AddressSpace::PushConstant) {
      GV.setInitializer(nullptr);
    }
  }

  // Generate literal samplers if necessary.
  GenerateSamplers();

  // Generate SPIRV variables.
  for (GlobalVariable &GV : module->globals()) {
    GenerateGlobalVar(GV);
  }
  GenerateResourceVars();
  GenerateWorkgroupVars();

  // Generate SPIRV instructions for each function.
  for (Function &F : *module) {
    if (F.isDeclaration()) {
      continue;
    }

    // Generate Function Prologue.
    GenerateFuncPrologue(F);

    // Generate SPIRV instructions for function body.
    GenerateFuncBody(F);

    // Generate Function Epilogue.
    GenerateFuncEpilogue();
  }

  HandleDeferredInstruction();
  HandleDeferredDecorations();

  // Generate SPIRV module information.
  GenerateModuleInfo();

  // Generate embedded reflection information.
  GenerateReflection();

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
    *out << os.str();
  }

  if (TestOutput) {
    std::error_code error;
    raw_fd_ostream test_output(TestOutFile, error, llvm::sys::fs::FA_Write);
    test_output << static_cast<raw_svector_ostream *>(out)->str();
    delete out;
    delete binary;
  }

  return false;
}

void SPIRVProducerPassImpl::outputHeader() {
  binaryOut->write(reinterpret_cast<const char *>(&spv::MagicNumber),
                   sizeof(spv::MagicNumber));
  uint32_t minor = 0;
  switch (SpvVersion()) {
  case SPIRVVersion::SPIRV_1_0:
    minor = 0;
    break;
  case SPIRVVersion::SPIRV_1_3:
    minor = 3;
    break;
  case SPIRVVersion::SPIRV_1_4:
    minor = 4;
    break;
  case SPIRVVersion::SPIRV_1_5:
    minor = 5;
    break;
  case SPIRVVersion::SPIRV_1_6:
    minor = 6;
    break;
  default:
    llvm_unreachable("unhandled spir-v version");
    break;
  }
  uint32_t version = (1 << 16) | (minor << 8);
  binaryOut->write(reinterpret_cast<const char *>(&version), sizeof(version));

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

void SPIRVProducerPassImpl::patchHeader() {
  // for a binary we just write the value of nextID over bound
  binaryOut->pwrite(reinterpret_cast<char *>(&nextID), sizeof(nextID),
                    patchBoundOffset);
}

void SPIRVProducerPassImpl::GenerateLLVMIRInfo() {
  // This function generates LLVM IR for function such as global variable for
  // argument, constant and pointer type for argument access. These information
  // is artificial one because we need Vulkan SPIR-V output. This function is
  // executed ahead of FindType and FindConstant.

  FindGlobalConstVars();

  FindResourceVars();

  FindTypesForSamplerMap();
  FindTypesForResourceVars();
}

void SPIRVProducerPassImpl::FindGlobalConstVars() {
  clspv::NormalizeGlobalVariables(*module);
  const DataLayout &DL = module->getDataLayout();

  SmallVector<GlobalVariable *, 8> GVList;
  SmallVector<GlobalVariable *, 8> DeadGVList;
  for (GlobalVariable &GV : module->globals()) {
    if (GV.getType()->getAddressSpace() == AddressSpace::Constant) {
      if (GV.use_empty() &&
          GV.getName() != clspv::ClusteredConstantsVariableName()) {
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
    if (!GVList.empty()) {
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
      Type *NewGVTy = GV->getValueType();
      GlobalVariable *NewGV = new GlobalVariable(
          *module, NewGVTy, false, GV->getLinkage(), GV->getInitializer(), "",
          nullptr, GV->getThreadLocalMode(), AddressSpace::ModuleScopePrivate);
      NewGV->takeName(GV);

      const SmallVector<User *, 8> GVUsers(GV->user_begin(), GV->user_end());
      SmallVector<User *, 8> CandidateUsers;

      auto record_called_function_type_as_user =
          [&GlobalConstFuncTyMap](Value *gv, CallInst *call) {
            // Find argument index.
            unsigned index = 0;
            for (unsigned i = 0; i < call->arg_size(); i++) {
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

void SPIRVProducerPassImpl::FindResourceVars() {
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
  // the same clspv.resource.var.X function is seen with disintct
  // (set,binding) values.
  const bool always_distinct_sets =
      clspv::Option::DistinctKernelDescriptorSets();
  for (Function &F : *module) {
    // Rely on the fact the resource var functions have a stable ordering
    // in the module.
    if (Builtins::Lookup(&F) == Builtins::kClspvResource) {
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
          const auto set =
              unsigned(dyn_cast<ConstantInt>(
                           call->getArgOperand(
                               clspv::ClspvOperand::kResourceDescriptorSet))
                           ->getZExtValue());
          const auto binding = unsigned(
              dyn_cast<ConstantInt>(
                  call->getArgOperand(clspv::ClspvOperand::kResourceBinding))
                  ->getZExtValue());
          const auto arg_kind = clspv::ArgKind(
              dyn_cast<ConstantInt>(
                  call->getArgOperand(clspv::ClspvOperand::kResourceArgKind))
                  ->getZExtValue());
          const auto arg_index = unsigned(
              dyn_cast<ConstantInt>(
                  call->getArgOperand(clspv::ClspvOperand::kResourceArgIndex))
                  ->getZExtValue());
          const auto coherent = unsigned(
              dyn_cast<ConstantInt>(
                  call->getArgOperand(clspv::ClspvOperand::kResourceCoherent))
                  ->getZExtValue());
          const auto data_type =
              call->getArgOperand(clspv::ClspvOperand::kResourceDataType)
                  ->getType();

          // Find or make the resource var info for this combination.
          ResourceVarInfo *rv = nullptr;
          if (always_distinct_sets) {
            // Make a new resource var any time we see a different
            // (set,binding) pair.
            SetAndBinding key{set, binding};
            auto where = set_and_binding_map.find(key);
            if (where == set_and_binding_map.end()) {
              rv = new ResourceVarInfo(
                  static_cast<int>(ResourceVarInfoList.size()), set, binding,
                  &F, arg_kind, coherent, data_type);
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
              rv = new ResourceVarInfo(
                  static_cast<int>(ResourceVarInfoList.size()), set, binding,
                  &F, arg_kind, coherent, data_type);
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
  for (Function &F : *module) {
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
             << " (" << *(info->data_type) << ")"
             << "\n";
    }
  }
}

void SPIRVProducerPassImpl::FindTypesForSamplerMap() {
  // If we are using a sampler map, find the type of the sampler.
  if (auto *F = module->getFunction(clspv::LiteralSamplerFunction())) {
    SamplerDataTy = F->getArg(ClspvOperand::kSamplerDataType)->getType();
    SamplerPointerTy =
        PointerType::get(module->getContext(), AddressSpace::UniformConstant);
  }
}

void SPIRVProducerPassImpl::FindTypesForResourceVars() {
  // Record types so they are generated.
  TypesNeedingLayout.reset();
  StructTypesNeedingBlock.reset();

  for (const auto *info : ModuleOrderedResourceVars) {
    Type *type = info->var_fn->getReturnType();

    switch (info->arg_kind) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::BufferUBO:
      if (auto *sty = dyn_cast<StructType>(info->data_type)) {
        StructTypesNeedingBlock.insert(sty);
      } else {
        errs() << *type << "\n";
        llvm_unreachable("Buffer arguments must map to structures!");
      }
      break;
    case clspv::ArgKind::Pod:
    case clspv::ArgKind::PodUBO:
    case clspv::ArgKind::PodPushConstant:
      if (auto *sty = dyn_cast<StructType>(info->data_type)) {
        StructTypesNeedingBlock.insert(sty);
      } else {
        errs() << *type << "\n";
        llvm_unreachable("POD arguments must map to structures!");
      }
      break;
    case clspv::ArgKind::SampledImage:
    case clspv::ArgKind::StorageImage:
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::StorageTexelBuffer:
    case clspv::ArgKind::UniformTexelBuffer:
      break;
    default:
      break;
    }
  }

  // If module constants are clustered in a storage buffer then that struct
  // needs layout decorations.
  if (clspv::Option::ModuleConstantsInStorageBuffer()) {
    for (GlobalVariable &GV : module->globals()) {
      PointerType *PTy = cast<PointerType>(GV.getType());
      const auto AS = PTy->getAddressSpace();
      const bool module_scope_constant_external_init =
          (AS == AddressSpace::Constant) && GV.hasInitializer();
      const spv::BuiltIn BuiltinType = GetBuiltin(GV.getName());
      if (module_scope_constant_external_init &&
          spv::BuiltInMax == BuiltinType) {
        StructTypesNeedingBlock.insert(
            cast<StructType>(GV.getValueType()));
      }
    }
  }

  for (const GlobalVariable &GV : module->globals()) {
    if (GV.getAddressSpace() == clspv::AddressSpace::PushConstant) {
      auto Ty = GV.getValueType();
      assert(Ty->isStructTy() && "Push constants have to be structures.");
      auto STy = cast<StructType>(Ty);
      StructTypesNeedingBlock.insert(STy);
    } else if (GV.getName() == clspv::PrintfBufferVariableName()) {
      auto Ty = GV.getValueType();
      auto STy = cast<StructType>(Ty);
      StructTypesNeedingBlock.insert(STy);
    }
  }

  // Traverse the arrays and structures underneath each Block, and
  // mark them as needing layout.
  std::vector<Type *> work_list(StructTypesNeedingBlock.begin(),
                                StructTypesNeedingBlock.end());

  // Physical storage buffer types need layout, but the types can't be found via
  // resource variables. Traverse the module to find the necessary types.
  if (clspv::Option::PhysicalStorageBuffers()) {
    for (auto &F : *module) {
      for (auto &BB : F) {
        for (auto &I : BB) {
          if (isa<IntToPtrInst>(&I) &&
              GetStorageClass(I.getType()->getPointerAddressSpace()) ==
                  spv::StorageClassPhysicalStorageBuffer) {
            auto *inferred_ty =
                clspv::InferType(&I, module->getContext(), &InferredTypeCache);
            if (inferred_ty)
              work_list.push_back(inferred_ty);
          }
        }
      }
    }
  }
  while (!work_list.empty()) {
    Type *type = work_list.back();
    work_list.pop_back();
    TypesNeedingLayout.insert(type);
    switch (type->getTypeID()) {
    case Type::ArrayTyID: {
      auto ele_ty = type->getArrayElementType();
      work_list.push_back(ele_ty);
      if (!Hack_generate_runtime_array_stride_early) {
        // Remember this array type for deferred decoration.
        auto needs_layout = SpvVersion() >= SPIRVVersion::SPIRV_1_4;
        getTypesNeedingArrayStride().insert(
            StrideType(GetTypeAllocSize(ele_ty, module->getDataLayout()),
                       getSPIRVType(type, needs_layout)));
      }
      break;
    }
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

void SPIRVProducerPassImpl::GenerateWorkgroupVars() {
  // Find the local variable resource calls.
  // Clspv only shares spec ids if the data types match so we only need to find
  // one call per spec id.
  DenseMap<int, CallInst *> local_vars;
  int max_spec_id = 0;
  for (auto &F : *module) {
    for (auto &BB : F) {
      for (auto &I : BB) {
        if (auto *call = dyn_cast<CallInst>(&I)) {
          if (Builtins::Lookup(call->getCalledFunction()) ==
              Builtins::kClspvLocal) {
            int spec_id = static_cast<int>(
                cast<ConstantInt>(
                    call->getOperand(ClspvOperand::kWorkgroupSpecId))
                    ->getSExtValue());
            if (!local_vars.count(spec_id)) {
              local_vars[spec_id] = call;
              max_spec_id = std::max(max_spec_id, spec_id);
            }
          }
        }
      }
    }
  }

  // Generate the variables in order of spec id.
  for (int spec_id = 0; spec_id <= max_spec_id; ++spec_id) {
    if (!local_vars.count(spec_id)) {
      continue;
    }

    auto *call = local_vars[spec_id];
    auto *ArrayTy =
        call->getArgOperand(ClspvOperand::kWorkgroupDataType)->getType();
    auto *ElemTy = cast<ArrayType>(ArrayTy)->getElementType();

    // Generate the spec constant.
    SPIRVOperandVec Ops;
    Ops << Type::getInt32Ty(module->getContext()) << 1;
    SPIRVID ArraySizeID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    // Generate the array type.
    Ops.clear();
    // The element type must have been created.
    Ops << ElemTy << ArraySizeID;

    SPIRVID ArrayTypeID = addSPIRVInst<kTypes>(spv::OpTypeArray, Ops);

    Ops.clear();
    Ops << spv::StorageClassWorkgroup << ArrayTypeID;
    SPIRVID PtrArrayTypeID = addSPIRVInst<kTypes>(spv::OpTypePointer, Ops);

    // Generate OpVariable.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Storage Class
    SPIRVID VariableID =
        addSPIRVGlobalVariable(PtrArrayTypeID, spv::StorageClassWorkgroup);

    Ops.clear();
    Ops << ArraySizeID << spv::DecorationSpecId << spec_id;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    LocalArgInfo info{VariableID,  ElemTy,         ArraySizeID,
                      ArrayTypeID, PtrArrayTypeID, spec_id};
    LocalSpecIdInfoMap[spec_id] = info;
  }

  // Record the spec ids for each kernel argument. The arguments can be found in
  // the metadata.
  NamedMDNode *nmd = module->getNamedMetadata(clspv::LocalSpecIdMetadataName());
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

    LocalArgSpecIds[arg] = spec_id;
  }
}

spv::StorageClass SPIRVProducerPassImpl::GetStorageBufferClass() const {
  return clspv::Option::PhysicalStorageBuffers()
             ? spv::StorageClassPhysicalStorageBuffer
             : spv::StorageClassStorageBuffer;
}

spv::StorageClass
SPIRVProducerPassImpl::GetStorageClass(unsigned AddrSpace) const {
  switch (AddrSpace) {
  default:
    llvm_unreachable("Unsupported OpenCL address space");
  case AddressSpace::Private:
    return spv::StorageClassFunction;
  case AddressSpace::Global:
    return GetStorageBufferClass();
  case AddressSpace::Constant:
    return clspv::Option::ConstantArgsInUniformBuffer()
               ? spv::StorageClassUniform
               : GetStorageBufferClass();
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
  case AddressSpace::PushConstant:
    return spv::StorageClassPushConstant;
  }
}

spv::StorageClass SPIRVProducerPassImpl::GetStorageClassForArgKind(
    clspv::ArgKind arg_kind) const {
  switch (arg_kind) {
  case clspv::ArgKind::Buffer:
    return spv::StorageClassStorageBuffer;
  case clspv::ArgKind::BufferUBO:
    return spv::StorageClassUniform;
  case clspv::ArgKind::Pod:
    return spv::StorageClassStorageBuffer;
  case clspv::ArgKind::PodUBO:
    return spv::StorageClassUniform;
  case clspv::ArgKind::PodPushConstant:
    return spv::StorageClassPushConstant;
  case clspv::ArgKind::Local:
    return spv::StorageClassWorkgroup;
  case clspv::ArgKind::SampledImage:
  case clspv::ArgKind::StorageImage:
  case clspv::ArgKind::Sampler:
  case clspv::ArgKind::StorageTexelBuffer:
  case clspv::ArgKind::UniformTexelBuffer:
    return spv::StorageClassUniformConstant;
  default:
    llvm_unreachable("Unsupported storage class for argument kind");
  }
}

spv::BuiltIn SPIRVProducerPassImpl::GetBuiltin(StringRef Name) const {
  return StringSwitch<spv::BuiltIn>(Name)
      .Case("__spirv_GlobalInvocationId", spv::BuiltInGlobalInvocationId)
      .Case("__spirv_LocalInvocationId", spv::BuiltInLocalInvocationId)
      .Case("__spirv_WorkgroupSize", spv::BuiltInWorkgroupSize)
      .Case("__spirv_NumWorkgroups", spv::BuiltInNumWorkgroups)
      .Case("__spirv_WorkgroupId", spv::BuiltInWorkgroupId)
      .Case("__spirv_WorkDim", spv::BuiltInWorkDim)
      .Case("__spirv_GlobalOffset", spv::BuiltInGlobalOffset)
      .Case("__spirv_SubgroupMaxSize", spv::BuiltInSubgroupMaxSize)
      .Default(spv::BuiltInMax);
}

SPIRVID SPIRVProducerPassImpl::getOpExtInstImportID() {
  if (OpExtInstImportID == 0) {
    //
    // Generate OpExtInstImport.
    //
    // Ops[0] ... Ops[n] = Name (Literal String)

    OpExtInstImportID =
        addSPIRVInst<kImports>(spv::OpExtInstImport, "GLSL.std.450");
  }
  return OpExtInstImportID;
}

SPIRVID SPIRVProducerPassImpl::addSPIRVGlobalVariable(const SPIRVID &TypeID,
                                                      spv::StorageClass SC,
                                                      const SPIRVID &InitID,
                                                      bool add_interface) {
  // Generate OpVariable.
  //
  // Ops[0] : Result Type ID
  // Ops[1] : Storage Class
  // Ops[2] : Initialization Value ID (optional)

  SPIRVOperandVec Ops;
  Ops << TypeID << SC;
  if (InitID.isValid()) {
    Ops << InitID;
  }

  SPIRVID VID = addSPIRVInst<kGlobalVariables>(spv::OpVariable, Ops);

  if (SC == spv::StorageClassInput ||
      (add_interface && SpvVersion() >= SPIRVVersion::SPIRV_1_4)) {
    getEntryPointInterfacesList().push_back(VID);
  }

  return VID;
}

Type *SPIRVProducerPassImpl::CanonicalType(Type *type) {
  if (type->isIntegerTy()) {
    auto bit_width = static_cast<uint32_t>(type->getPrimitiveSizeInBits());
    if (bit_width > 1) {
      // round up bit_width to a multiple of 8
      bit_width = ((bit_width + 7) / 8) * 8;
    }
    return IntegerType::get(type->getContext(), bit_width);
  } else if (auto *ptr_ty = dyn_cast<PointerType>(type)) {
    // For the purposes of our Vulkan SPIR-V type system, constant and global
    // are conflated.
    unsigned AddrSpace = ptr_ty->getAddressSpace();
    if (AddressSpace::Constant == AddrSpace) {
      if (!clspv::Option::ConstantArgsInUniformBuffer() &&
          !clspv::Option::PhysicalStorageBuffers()) {
        AddrSpace = AddressSpace::Global;
        // The canonical type of __constant is __global unless constants are
        // passed in uniform buffers.
        auto *GlobalTy = PointerType::getWithSamePointeeType(ptr_ty, AddrSpace);
        return GlobalTy;
      }
    }
  } else if (type->isTargetExtTy()) {
    // Nothing
  } else if (type->getNumContainedTypes() != 0) {
    switch (type->getTypeID()) {
    case Type::StructTyID: {
      SmallVector<Type *, 8> subtypes;
      bool changed = false;
      for (auto *subtype : type->subtypes()) {
        auto canonical = CanonicalType(subtype);
        subtypes.push_back(canonical);
        if (canonical != subtype) {
          changed = true;
        }
      }
      if (changed) {
        return StructType::get(type->getContext(), subtypes,
                               cast<StructType>(type)->isPacked());
      }
      break;
    }
    case Type::ArrayTyID: {
      auto *elem_ty = type->getArrayElementType();
      auto *equiv_elem_ty = CanonicalType(elem_ty);
      if (equiv_elem_ty != elem_ty) {
        return ArrayType::get(equiv_elem_ty,
                              cast<ArrayType>(type)->getNumElements());
      }
      break;
    }
    case Type::FunctionTyID: {
      auto *func_ty = cast<FunctionType>(type);
      auto *return_ty = CanonicalType(func_ty->getReturnType());
      SmallVector<Type *, 8> params;
      for (unsigned i = 0; i < func_ty->getNumParams(); ++i) {
        params.push_back(CanonicalType(func_ty->getParamType(i)));
      }
      return FunctionType::get(return_ty, params, func_ty->isVarArg());
    }
    default:
      break;
    }
  }

  return type;
}

bool SPIRVProducerPassImpl::PointerRequiresLayout(unsigned aspace) {
  if (Option::SpvVersion() >= SPIRVVersion::SPIRV_1_4) {
    switch (aspace) {
    case AddressSpace::PushConstant:
    case AddressSpace::Uniform:
    case AddressSpace::Global:
    case AddressSpace::Constant:
      return true;
    default:
      break;
    }
  }
  return false;
}

SPIRVID SPIRVProducerPassImpl::getSPIRVPointerType(Type *PtrTy, Type *DataTy) {
  if (!PtrTy->isPointerTy()) {
    return getSPIRVType(PtrTy);
  }
  if (!DataTy) {
    llvm_unreachable("Missing inferred type");
  }
  const auto aspace = PtrTy->getPointerAddressSpace();
  const auto needs_layout = PointerRequiresLayout(aspace);

  // This might still be problematic for structures/arrays of pointers. Clspv
  // can only support those in private and function storage classes though.
  auto data_id = getSPIRVType(DataTy, needs_layout);

  // Images and samplers can only be in the UniformConstant address space, so
  // clspv uses them by value in most parts of the code generation. The initial
  // generation of the resource variable and uses generate the correct pointer
  // and load of the type.
  if (auto struct_ty = dyn_cast<StructType>(DataTy)) {
    if (struct_ty->isOpaque() && aspace != AddressSpace::UniformConstant) {
      return data_id;
    }
  }

  auto canonical_aspace = aspace;
  if (aspace == AddressSpace::Constant &&
      !Option::ConstantArgsInUniformBuffer()) {
    canonical_aspace = AddressSpace::Global;
  }

  const unsigned layout_index = needs_layout ? 1 : 0;
  auto &aspace_map = PointerTypeMap[canonical_aspace];
  auto where = aspace_map.find(DataTy);
  if (where != aspace_map.end()) {
    if (where->second[layout_index].isValid()) {
      return where->second[layout_index];
    }
  }

  // Generate the SPIR-V pointer type.
  SPIRVOperandVec ops;
  ops << GetStorageClass(canonical_aspace) << data_id;
  auto ptr_id = addSPIRVInst<kTypes>(spv::OpTypePointer, ops);

  auto &entry = aspace_map[DataTy];
  if (entry.empty())
    entry.resize(2);
  entry[layout_index] = ptr_id;

  return ptr_id;
}

SPIRVID SPIRVProducerPassImpl::getSPIRVFunctionType(FunctionType *FTy,
                                                    Type *RetTy,
                                                    ArrayRef<Type *> ParamTys) {
  bool has_pointers = false;
  if (FTy->getReturnType()->isPointerTy()) {
    has_pointers = true;
  }
  for (auto *param_ty : FTy->params()) {
    if (param_ty->isPointerTy()) {
      has_pointers = true;
      break;
    }
  }

  // If there are no opaque pointer parameters defer to basic type handler.
  if (!has_pointers) {
    return getSPIRVType(FTy);
  }

  // Create a placeholder function type for use in caching. Pointer parameters
  // and return are mangled as placeholder parameter types to avoid collisions.
  // We use arrays for this purpose: [aspace x inferred_ty].
  SmallVector<Type *, 8> placeholder_param_tys;
  int i = 0;
  for (auto *param_ty : FTy->params()) {
    param_ty = CanonicalType(param_ty);
    placeholder_param_tys.push_back(param_ty);
    if (param_ty->isPointerTy()) {
      // Generate a representative type for the parameter type.
      unsigned aspace = param_ty->getPointerAddressSpace();
      auto *inferred_ty = ParamTys[i];
      auto *rep_ty = ArrayType::get(inferred_ty, aspace);
      placeholder_param_tys.push_back(rep_ty);
    }
    i++;
  }
  if (auto ptr_ty = dyn_cast<PointerType>(FTy->getReturnType())) {
    // Generate a representative type for the return type.
    auto *ty = CanonicalType(ptr_ty);
    unsigned aspace = ty->getPointerAddressSpace();
    auto *rep_ty = ArrayType::get(RetTy, aspace);
    placeholder_param_tys.push_back(rep_ty);
  }

  auto *placeholder_ty =
      FunctionType::get(CanonicalType(FTy->getReturnType()),
                        placeholder_param_tys, FTy->isVarArg());
  auto where = FunctionTypeMap.find(placeholder_ty);
  if (where != FunctionTypeMap.end()) {
    return where->second;
  }

  // Generate OpTypeFunction.
  // [0] = Result type
  // [1..n] = Param types
  SPIRVOperandVec ops;
  ops << getSPIRVPointerType(FTy->getReturnType(), RetTy);
  i = 0;
  for (auto *param_ty : FTy->params()) {
    auto *inferred_ty = ParamTys[i++];
    ops << getSPIRVPointerType(param_ty, inferred_ty);
  }
  auto id = addSPIRVInst<kTypes>(spv::OpTypeFunction, ops);
  FunctionTypeMap[placeholder_ty] = id;
  return id;
}

SPIRVID SPIRVProducerPassImpl::getSPIRVType(Type *Ty) {
  // Prior to 1.4, layout decorations are more relaxed so we can reuse a laid
  // out type in non-laid out storage classes.
  bool needs_layout = false;
  if (auto ptr_ty = dyn_cast<PointerType>(Ty)) {
    needs_layout = PointerRequiresLayout(ptr_ty->getPointerAddressSpace());
  }
  return getSPIRVType(Ty, needs_layout);
}

SPIRVID SPIRVProducerPassImpl::getSPIRVType(Type *Ty, bool needs_layout) {
  if (Ty->isOpaquePointerTy()) {
    llvm_unreachable("Unsupported opaque pointer");
  }

  // Only pointers, non-opaque structs and arrays should have layout
  // decorations.
  if (!(isa<PointerType>(Ty) || isa<ArrayType>(Ty) || isa<StructType>(Ty))) {
    needs_layout = false;
  } else if (auto StructTy = dyn_cast<StructType>(Ty)) {
    if (StructTy->isOpaque()) {
      needs_layout = false;
    }
  }
  // |layout| is the index used for |Ty|'s entry in the type map. Each type
  // stores a laid out and non-laid out version of the type.
  const unsigned layout = needs_layout ? 1 : 0;

  auto TI = TypeMap.find(Ty);
  if (TI != TypeMap.end()) {
    assert(layout < TI->second.size());
    if (TI->second[layout].isValid()) {
      return TI->second[layout];
    }
  }

  auto Canonical = CanonicalType(Ty);

  if (Canonical != Ty) {
    auto CanonicalTI = TypeMap.find(Canonical);
    if (CanonicalTI != TypeMap.end()) {
      assert(layout < CanonicalTI->second.size());
      if (CanonicalTI->second[layout].isValid()) {
        auto id = CanonicalTI->second[layout];
        auto &base = TypeMap[Ty];
        if (base.empty()) {
          base.resize(2);
        }
        base[layout] = id;
        return id;
      }
    }
  }

  // Perform the mapping with the canonical type.

  const auto &DL = module->getDataLayout();

  SPIRVID RID;

  switch (Canonical->getTypeID()) {
  default: {
    Canonical->print(errs());
    llvm_unreachable("Unsupported type???");
    break;
  }
  case Type::MetadataTyID:
  case Type::LabelTyID: {
    // Ignore these types.
    break;
  }
  case Type::PointerTyID: {
    llvm_unreachable("getSPIRVType called directly on a pointer type");
    break;
  }
  case Type::TargetExtTyID: {
    auto *ext_ty = cast<TargetExtType>(Canonical);
    if (IsImageType(ext_ty)) {
      const auto dim = ImageDimensionality(ext_ty);
      const auto sampled = IsSampledImageType(ext_ty);
      switch (dim) {
        case spv::Dim1D:
          if (sampled) {
            addCapability(spv::CapabilitySampled1D);
          } else {
            addCapability(spv::CapabilityImage1D);
          }
          break;
        case spv::DimBuffer:
          if (sampled) {
            addCapability(spv::CapabilitySampledBuffer);
          } else {
            addCapability(spv::CapabilityImageBuffer);
          }
          break;
        default:
          break;
      }

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
      SPIRVOperandVec Ops;

      SPIRVID SampledTyID;
      // None of the sampled types have a layout.
      if (IsFloatImageType(ext_ty)) {
          SampledTyID =
              getSPIRVType(Type::getFloatTy(Canonical->getContext()), false);
      } else if (IsUintImageType(ext_ty)) {
          SampledTyID =
              getSPIRVType(Type::getInt32Ty(Canonical->getContext()), false);
      } else if (IsIntImageType(ext_ty)) {
          // Generate a signed 32-bit integer if necessary.
          if (int32ID == 0) {
            SPIRVOperandVec intOps;
            intOps << 32 << 1;
            int32ID = addSPIRVInst<kTypes>(spv::OpTypeInt, intOps);
          }
          SampledTyID = int32ID;

          // Generate a vec4 of the signed int if necessary.
          if (v4int32ID == 0) {
            SPIRVOperandVec vecOps;
            vecOps << int32ID << 4;
            v4int32ID = addSPIRVInst<kTypes>(spv::OpTypeVector, vecOps);
          }
      } else {
          // This was likely an UndefValue.
          SampledTyID =
              getSPIRVType(Type::getFloatTy(Canonical->getContext()), false);
      }
      Ops << SampledTyID;

      spv::Dim DimID = ImageDimensionality(ext_ty);
      Ops << DimID;

      // TODO: Set up Depth.
      Ops << 0;

      uint32_t arrayed = IsArrayImageType(ext_ty) ? 1 : 0;
      Ops << arrayed;

      // TODO: Set up MS.
      Ops << 0;

      // Set up Sampled.
      //
      // From Spec
      //
      // 0 indicates this is only known at run time, not at compile time
      // 1 indicates will be used with sampler
      // 2 indicates will be used without a sampler (a storage image)
      uint32_t Sampled = 1;
      if (!IsSampledImageType(ext_ty)) {
          Sampled = 2;
      }
      Ops << Sampled;

      // TODO: Set up Image Format.
      Ops << spv::ImageFormatUnknown;
      RID = addSPIRVInst<kTypes>(spv::OpTypeImage, Ops);

      // Only need a sampled version of the type if it is used with a sampler.
      // In SPIR-V 1.6 or later, sampled image dimension must not be Buffer
      if (Sampled == 1 && ImageDimensionality(ext_ty) != spv::DimBuffer) {
          Ops.clear();
          Ops << RID;
          getImageTypeMap()[Canonical] =
              addSPIRVInst<kTypes>(spv::OpTypeSampledImage, Ops);
      }
      break;
    } else if (IsSamplerType(ext_ty)) {
      //
      // Generate OpTypeSampler
      //
      // Empty Ops.

      RID = addSPIRVInst<kTypes>(spv::OpTypeSampler);
      break;
    } else {
      llvm_unreachable("Unknown target ext type");
    }
    break;
  }
  case Type::StructTyID: {
    StructType *STy = cast<StructType>(Canonical);

    if (STy->getNumElements() == 1 && STy->getElementType(0)->isArrayTy() &&
        cast<ArrayType>(STy->getElementType(0))->getNumElements() == 0) {
      StructTypesNeedingBlock.insert(STy);
    }

    //
    // Generate OpTypeStruct
    //
    // Ops[0] ... Ops[n] = Member IDs
    SPIRVOperandVec Ops;

    for (auto *EleTy : STy->elements()) {
      Ops << getSPIRVType(EleTy, needs_layout);
    }

    RID = addSPIRVInst<kTypes>(spv::OpTypeStruct, Ops);

    // Generate OpMemberDecorate unless we are generating it for the canonical
    // type.
    StructType *canonical = cast<StructType>(CanonicalType(STy));
    bool use_layout =
        (Option::SpvVersion() < SPIRVVersion::SPIRV_1_4) || needs_layout;
    if (TypesNeedingLayout.idFor(STy) &&
        (canonical == STy || !TypesNeedingLayout.idFor(canonical)) &&
        use_layout) {
      for (unsigned MemberIdx = 0; MemberIdx < STy->getNumElements();
           MemberIdx++) {
        // Ops[0] = Structure Type ID
        // Ops[1] = Member Index(Literal Number)
        // Ops[2] = Decoration (Offset)
        // Ops[3] = Byte Offset (Literal Number)
        const auto ByteOffset =
            GetExplicitLayoutStructMemberOffset(STy, MemberIdx, DL);

        Ops.clear();
        Ops << RID << MemberIdx << spv::DecorationOffset << ByteOffset;

        addSPIRVInst<kAnnotations>(spv::OpMemberDecorate, Ops);
      }
    }

    // Generate OpDecorate unless we are generating it for the canonical type.
    if (StructTypesNeedingBlock.idFor(STy) &&
        (canonical == STy || !StructTypesNeedingBlock.idFor(canonical)) &&
        use_layout) {
      Ops.clear();
      // Use Block decorations with StorageBuffer storage class.
      Ops << RID << spv::DecorationBlock;

      addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
    }
    break;
  }
  case Type::IntegerTyID: {
    uint32_t bit_width =
        static_cast<uint32_t>(Canonical->getPrimitiveSizeInBits());

    if (clspv::Option::Int8Support() && bit_width == 8) {
      addCapability(spv::CapabilityInt8);
    } else if (bit_width == 16) {
      addCapability(spv::CapabilityInt16);
    } else if (bit_width == 64) {
      addCapability(spv::CapabilityInt64);
    }

    if (bit_width == 1) {
      RID = addSPIRVInst<kTypes>(spv::OpTypeBool);
    } else {
      if (!clspv::Option::Int8Support() && bit_width == 8) {
        // i8 is added to TypeMap as i32.
        RID = getSPIRVType(Type::getIntNTy(Canonical->getContext(), 32), false);
      } else {
        SPIRVOperandVec Ops;
        Ops << bit_width << 0 /* not signed */;
        RID = addSPIRVInst<kTypes>(spv::OpTypeInt, Ops);
      }
    }
    break;
  }
  case Type::HalfTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID: {
    uint32_t bit_width =
        static_cast<uint32_t>(Canonical->getPrimitiveSizeInBits());
    if (bit_width == 16) {
      addCapability(spv::CapabilityFloat16);
    } else if (bit_width == 64) {
      addCapability(spv::CapabilityFloat64);
    }

    SPIRVOperandVec Ops;
    Ops << bit_width;

    RID = addSPIRVInst<kTypes>(spv::OpTypeFloat, Ops);
    break;
  }
  case Type::ArrayTyID: {
    ArrayType *ArrTy = cast<ArrayType>(Canonical);
    const uint64_t Length = ArrTy->getArrayNumElements();
    if (Length == 0) {
      // By convention, map it to a RuntimeArray.

      Type *EleTy = ArrTy->getArrayElementType();

      //
      // Generate OpTypeRuntimeArray.
      //
      // OpTypeRuntimeArray
      // Ops[0] = Element Type ID
      SPIRVOperandVec Ops;
      Ops << getSPIRVType(EleTy, needs_layout);

      RID = addSPIRVInst<kTypes>(spv::OpTypeRuntimeArray, Ops);

      if (Hack_generate_runtime_array_stride_early &&
          (Option::SpvVersion() < SPIRVVersion::SPIRV_1_4 || needs_layout)) {
        // Generate OpDecorate.

        // Ops[0] = Target ID
        // Ops[1] = Decoration (ArrayStride)
        // Ops[2] = Stride Number(Literal Number)
        Ops.clear();

        Ops << RID << spv::DecorationArrayStride
            << static_cast<uint32_t>(GetTypeAllocSize(EleTy, DL));

        addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
      }

    } else {

      //
      // Generate OpConstant and OpTypeArray.
      //

      //
      // Generate OpConstant for array length.
      //
      // Add constant for length to constant list.
      Constant *CstLength =
          ConstantInt::get(Type::getInt32Ty(module->getContext()), Length);

      //
      // Generate OpTypeArray.
      //
      // Ops[0] = Element Type ID
      // Ops[1] = Array Length Constant ID
      SPIRVOperandVec Ops;

      Ops << getSPIRVType(ArrTy->getElementType(), needs_layout) << CstLength;

      RID = addSPIRVInst<kTypes>(spv::OpTypeArray, Ops);

      // Remember to generate ArrayStride later
      if (needs_layout || SpvVersion() < SPIRVVersion::SPIRV_1_4) {
        getTypesNeedingArrayStride().insert(StrideType(
            GetTypeAllocSize(ArrTy->getElementType(), module->getDataLayout()),
            RID));
      }
    }
    break;
  }
  case Type::FixedVectorTyID: {
    auto VecTy = cast<VectorType>(Canonical);
    // <4 x i8> is changed to i32 if i8 is not generally supported.
    if (!clspv::Option::Int8Support() &&
        VecTy->getElementType() == Type::getInt8Ty(module->getContext())) {
      if (VecTy->getElementCount().getKnownMinValue() == 4) {
        RID = getSPIRVType(VecTy->getElementType());
        break;
      } else {
        Canonical->print(errs());
        llvm_unreachable("Support above i8 vector type");
      }
    }

    if (VecTy->getElementCount().getKnownMinValue() == 1) {
      RID = getSPIRVType(VecTy->getElementType());
      break;
    }

    // Ops[0] = Component Type ID
    // Ops[1] = Component Count (Literal Number)
    SPIRVOperandVec Ops;
    Ops << VecTy->getElementType()
        << VecTy->getElementCount().getKnownMinValue();

    RID = addSPIRVInst<kTypes>(spv::OpTypeVector, Ops);
    break;
  }
  case Type::VoidTyID: {
    RID = addSPIRVInst<kTypes>(spv::OpTypeVoid);
    break;
  }
  case Type::FunctionTyID: {
    // Generate SPIRV instruction for function type.
    FunctionType *FTy = cast<FunctionType>(Canonical);

    // Ops[0] = Return Type ID
    // Ops[1] ... Ops[n] = Parameter Type IDs
    SPIRVOperandVec Ops;

    // Find SPIRV instruction for return type
    Ops << FTy->getReturnType();

    // Find SPIRV instructions for parameter types
    for (unsigned k = 0; k < FTy->getNumParams(); k++) {
      // Find SPIRV instruction for parameter type.
      auto ParamTy = FTy->getParamType(k);
      Ops << getSPIRVType(ParamTy);
    }

    RID = addSPIRVInst<kTypes>(spv::OpTypeFunction, Ops);
    break;
  }
  }

  if (RID.isValid()) {
    auto &entry = TypeMap[Canonical];
    if (entry.empty()) {
      entry.resize(2);
    }
    entry[layout] = RID;

    if (Canonical != Ty) {
      // Also cache the original type.
      auto &base_entry = TypeMap[Ty];
      if (base_entry.empty()) {
        base_entry.resize(2);
      }
      base_entry[layout] = RID;
    }
  }
  return RID;
}

SPIRVID SPIRVProducerPassImpl::getSPIRVInt32Constant(uint32_t CstVal) {
  Type *i32 = Type::getInt32Ty(module->getContext());
  Constant *Cst = ConstantInt::get(i32, CstVal);
  return getSPIRVValue(Cst);
}

SPIRVID SPIRVProducerPassImpl::getSPIRVConstant(Constant *C) {
  ValueMapType &VMap = getValueMap();
  const bool hack_undef = clspv::Option::HackUndef();

  // Treat poison as an undef.
  auto *Cst = C;
  if (isa<PoisonValue>(Cst)) {
    Cst = UndefValue::get(Cst->getType());
  }

  auto VI = VMap.find(Cst);
  if (VI != VMap.end()) {
    assert(VI->second.isValid());
    return VI->second;
  }

  SPIRVID RID;

  //
  // Generate OpConstant.
  //
  // Ops[0] = Result Type ID
  // Ops[1] .. Ops[n] = Values LiteralNumber
  SPIRVOperandVec Ops;

  if (Cst->getType()->isPointerTy()) {
    auto *inferred_ty =
        clspv::InferType(Cst, Cst->getContext(), &InferredTypeCache);
    Ops << getSPIRVPointerType(Cst->getType(), inferred_ty);
  } else {
    Ops << Cst->getType();
  }

  std::vector<uint32_t> LiteralNum;
  spv::Op Opcode = spv::OpNop;

  if (isa<UndefValue>(Cst)) {
    // Ops[0] = Result Type ID
    Opcode = spv::OpUndef;
    if (hack_undef && IsTypeNullable(Cst->getType())) {
      Opcode = spv::OpConstantNull;
    }
  } else if (const ConstantInt *CI = dyn_cast<ConstantInt>(Cst)) {
    unsigned bit_width = CI->getBitWidth();
    if (bit_width == 1) {
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

      if (bit_width > 32) {
        LiteralNum.push_back(V >> 32);
      }

      Opcode = spv::OpConstant;

      Ops << LiteralNum;
    }
  } else if (const ConstantFP *CFP = dyn_cast<ConstantFP>(Cst)) {
    uint64_t FPVal = CFP->getValueAPF().bitcastToAPInt().getZExtValue();
    Type *CFPTy = CFP->getType();
    if (CFPTy->isFloatTy()) {
      LiteralNum.push_back(FPVal & 0xFFFFFFFF);
    } else if (CFPTy->isDoubleTy()) {
      LiteralNum.push_back(FPVal & 0xFFFFFFFF);
      LiteralNum.push_back(FPVal >> 32);
    } else if (CFPTy->isHalfTy()) {
      LiteralNum.push_back(FPVal & 0xFFFF);
    } else {
      CFPTy->print(errs());
      llvm_unreachable("Implement this ConstantFP Type");
    }

    Opcode = spv::OpConstant;

    Ops << LiteralNum;
  } else if (isa<ConstantDataSequential>(Cst) &&
             cast<ConstantDataSequential>(Cst)->isString()) {
    // Let's convert the constant to int constant specially.
    // This case occurs when all the values are specified as constant
    // ints.
    const ConstantDataSequential *CDS =
                 dyn_cast<ConstantDataSequential>(Cst);
    //
    // Generate OpConstant with OpTypeInt 32 0.
    //
    uint32_t IntValue = 0;
    for (unsigned k = 0; k < CDS->getNumElements(); k++) {
      const uint64_t Val = CDS->getElementAsInteger(k);
      IntValue = (IntValue << 8) | (Val & 0xffu);
    }

    RID = getSPIRVInt32Constant(IntValue);
    
  } else if (const ConstantDataSequential *CDS =
                 dyn_cast<ConstantDataSequential>(Cst)) {
    // Let's convert <4 x i8> constant to int constant specially.
    // This case occurs when all the values are specified as constant
    // ints.
    Type *CstTy = Cst->getType();
    if (is4xi8vec(CstTy)) {
      //
      // Generate OpConstant with OpTypeInt 32 0.
      //
      uint32_t IntValue = 0;
      for (unsigned k = 0; k < 4; k++) {
        const uint64_t Val = CDS->getElementAsInteger(k);
        IntValue = (IntValue << 8) | (Val & 0xffu);
      }

      RID = getSPIRVInt32Constant(IntValue);
    } else if (CDS->getNumElements() > 1) {

      // A normal constant-data-sequential case.
      for (unsigned k = 0; k < CDS->getNumElements(); k++) {
        Ops << CDS->getElementAsConstant(k);
      }

      Opcode = spv::OpConstantComposite;
    }
  } else if (const ConstantAggregate *CA = dyn_cast<ConstantAggregate>(Cst)) {
    // Let's convert <4 x i8> constant to int constant specially.
    // This case occurs when at least one of the values is an undef.
    Type *CstTy = Cst->getType();
    if (is4xi8vec(CstTy)) {
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

      RID = getSPIRVInt32Constant(IntValue);
    } else {

      // We use a constant composite in SPIR-V for our constant aggregate in
      // LLVM.
      Opcode = spv::OpConstantComposite;

      for (unsigned k = 0; k < CA->getNumOperands(); k++) {
        // And add an operand to the composite we are constructing
        Ops << CA->getAggregateElement(k);
      }
    }
  } else if (Cst->isNullValue()) {
    Opcode = spv::OpConstantNull;
  } else if(const Function *Fn = dyn_cast<Function>(Cst)) {
    if (Fn->isIntrinsic()) {
      Fn->print(errs());
      llvm_unreachable("Unsupported llvm intrinsic");
    }
    Fn->print(errs());
    llvm_unreachable("Unhandled function declaration/definition");
  } else if (auto *ConstExpr = dyn_cast<ConstantExpr>(Cst)) {
    // If there is exactly one use we know where to insert the instruction
    if (ConstExpr->getNumUses() == 1) {
      auto *User = *ConstExpr->user_begin();
      auto *EquivInstr =
          ConstExpr->getAsInstruction(dyn_cast<Instruction>(User));
      GenerateInstruction(*EquivInstr);
      RID = VMap[EquivInstr];
    } else {
      llvm_unreachable("Unhandled ConstantExpr");
    }
  } else {
    Cst->print(errs());
    llvm_unreachable("Unsupported Constant???");
  }

  if (Opcode == spv::OpConstantNull && Cst->getType()->isPointerTy()) {
    // Null pointer requires variable pointers.
    setVariablePointersCapabilities(Cst->getType()->getPointerAddressSpace());
  }

  if (RID == 0) {
    RID = addSPIRVInst<kConstants>(Opcode, Ops);
  }

  VMap[Cst] = RID;

  return RID;
}

SPIRVID SPIRVProducerPassImpl::getSPIRVValue(Value *V) {
  auto II = ValueMap.find(V);
  if (II != ValueMap.end()) {
    assert(II->second.isValid());
    return II->second;
  }
  if (Constant *Cst = dyn_cast<Constant>(V)) {
    return getSPIRVConstant(Cst);
  } else {
    llvm_unreachable("Variable not found");
  }
}

void SPIRVProducerPassImpl::GenerateSamplers() {
  SamplerLiteralToIDMap.clear();
  DenseMap<unsigned, unsigned> SamplerLiteralToDescriptorSetMap;
  DenseMap<unsigned, unsigned> SamplerLiteralToBindingMap;

  // We might have samplers in the sampler map that are not used
  // in the translation unit.  We need to allocate variables
  // for them and bindings too.
  DenseSet<unsigned> used_bindings;

  auto *var_fn = module->getFunction(clspv::LiteralSamplerFunction());
  // Return if there are no literal samplers.
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
    //          i32 sampler_mask,
    //          <sampler type> zeroinitializer)
    if (auto *call = dyn_cast<CallInst>(user)) {
      const auto sampler_value = static_cast<unsigned>(
          dyn_cast<ConstantInt>(
              call->getArgOperand(ClspvOperand::kSamplerParams))
              ->getZExtValue());
      const auto descriptor_set = static_cast<unsigned>(
          dyn_cast<ConstantInt>(
              call->getArgOperand(ClspvOperand::kSamplerDescriptorSet))
              ->getZExtValue());
      const auto binding = static_cast<unsigned>(
          dyn_cast<ConstantInt>(
              call->getArgOperand(ClspvOperand::kSamplerBinding))
              ->getZExtValue());

      SamplerLiteralToDescriptorSetMap[sampler_value] = descriptor_set;
      SamplerLiteralToBindingMap[sampler_value] = binding;
      used_bindings.insert(binding);
    }
  }

  DenseSet<size_t> seen;
  for (auto user : var_fn->users()) {
    if (!isa<CallInst>(user))
      continue;

    auto call = cast<CallInst>(user);
    const unsigned sampler_value = static_cast<unsigned>(
        dyn_cast<ConstantInt>(call->getArgOperand(ClspvOperand::kSamplerParams))
            ->getZExtValue());

    // Already allocated a variable for this value.
    if (!seen.insert(sampler_value).second)
      continue;

    // Add literal samplers to each entry point interface as an
    // over-approximation.
    auto sampler_type_id = getSPIRVPointerType(SamplerPointerTy, SamplerDataTy);
    auto sampler_var_id = addSPIRVGlobalVariable(
        sampler_type_id, spv::StorageClassUniformConstant,
        /* InitId = */ SPIRVID(0), /* add_interface = */ true);

    SamplerLiteralToIDMap[sampler_value] = sampler_var_id;

    unsigned descriptor_set;
    unsigned binding;
    if (SamplerLiteralToBindingMap.find(sampler_value) ==
        SamplerLiteralToBindingMap.end()) {
      // This sampler is not actually used.  Find the next one.
      for (binding = 0; used_bindings.count(binding); binding++) {
      }
      descriptor_set = 0; // Literal samplers always use descriptor set 0.
      used_bindings.insert(binding);
    } else {
      descriptor_set = SamplerLiteralToDescriptorSetMap[sampler_value];
      binding = SamplerLiteralToBindingMap[sampler_value];

      auto import_id = getReflectionImport();
      SPIRVOperandVec Ops;
      Ops << getSPIRVType(Type::getVoidTy(module->getContext())) << import_id
          << reflection::ExtInstLiteralSampler
          << getSPIRVInt32Constant(descriptor_set)
          << getSPIRVInt32Constant(binding)
          << getSPIRVInt32Constant(sampler_value);
      addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
    }

    // Ops[0] = Target ID
    // Ops[1] = Decoration (DescriptorSet)
    // Ops[2] = LiteralNumber according to Decoration
    SPIRVOperandVec Ops;
    Ops << sampler_var_id << spv::DecorationDescriptorSet << descriptor_set;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    // Ops[0] = Target ID
    // Ops[1] = Decoration (Binding)
    // Ops[2] = LiteralNumber according to Decoration
    Ops.clear();
    Ops << sampler_var_id << spv::DecorationBinding << binding;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }
}

void SPIRVProducerPassImpl::GenerateResourceVars() {
  ValueMapType &VMap = getValueMap();

  // Generate variables.  Make one for each of resource var info object.
  for (auto *info : ModuleOrderedResourceVars) {
    Type *type = info->var_fn->getReturnType();
    // Remap the address space for opaque types.
    switch (info->arg_kind) {
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::SampledImage:
    case clspv::ArgKind::StorageImage:
    case clspv::ArgKind::StorageTexelBuffer:
    case clspv::ArgKind::UniformTexelBuffer:
      type = info->data_type->getPointerTo(AddressSpace::UniformConstant);
      break;
    default:
      break;
    }

    const auto sc = GetStorageClassForArgKind(info->arg_kind);

    auto type_id = getSPIRVPointerType(type, info->data_type);
    info->var_id = addSPIRVGlobalVariable(type_id, sc);

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
          case clspv::ArgKind::PodUBO:
          case clspv::ArgKind::PodPushConstant:
            // The call maps to the variable directly.
            VMap[call] = info->var_id;
            break;
          case clspv::ArgKind::Sampler:
          case clspv::ArgKind::SampledImage:
          case clspv::ArgKind::StorageImage:
          case clspv::ArgKind::StorageTexelBuffer:
          case clspv::ArgKind::UniformTexelBuffer:
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
  SPIRVOperandVec Ops;
  for (auto *info : ModuleOrderedResourceVars) {
    // Push constants don't need descriptor set or binding decorations.
    if (info->arg_kind == clspv::ArgKind::PodPushConstant)
      continue;

    // Decorate with DescriptorSet and Binding.
    Ops.clear();
    Ops << info->var_id << spv::DecorationDescriptorSet << info->descriptor_set;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    Ops.clear();
    Ops << info->var_id << spv::DecorationBinding << info->binding;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    if (info->coherent) {
      // Decorate with Coherent if required for the variable.
      Ops.clear();
      Ops << info->var_id << spv::DecorationCoherent;
      addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
    }

    // Generate NonWritable and NonReadable
    switch (info->arg_kind) {
    case clspv::ArgKind::Buffer:
    case clspv::ArgKind::BufferUBO:
      if (info->var_fn->getReturnType()->getPointerAddressSpace() ==
          clspv::AddressSpace::Constant) {
        Ops.clear();
        Ops << info->var_id << spv::DecorationNonWritable;
        addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
      }
      break;
    case clspv::ArgKind::StorageImage: {
      // TODO(alan-baker): This is conservative. If compiling for OpenCL 2.0 or
      // above, the compiler treats all write_only images as read_write images.
      if (IsWriteOnlyImageType(info->data_type)) {
        Ops.clear();
        Ops << info->var_id << spv::DecorationNonReadable;
        addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
      }
      break;
    }
    default:
      break;
    }
  }
}

void SPIRVProducerPassImpl::GenerateGlobalVar(GlobalVariable &GV) {
  ValueMapType &VMap = getValueMap();
  std::vector<SPIRVID> &BuiltinDimVec = getBuiltinDimVec();
  const DataLayout &DL = GV.getParent()->getDataLayout();

  const spv::BuiltIn BuiltinType = GetBuiltin(GV.getName());
  Type *Ty = GV.getType();
  PointerType *PTy = cast<PointerType>(Ty);

  SPIRVID InitializerID;

  // Workgroup size is handled differently (it goes into a constant)
  if (spv::BuiltInWorkgroupSize == BuiltinType) {
    uint32_t PrevXDimCst = 0xFFFFFFFF;
    uint32_t PrevYDimCst = 0xFFFFFFFF;
    uint32_t PrevZDimCst = 0xFFFFFFFF;
    bool HasMD = true;
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
          HasMD = false;
          continue;
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
        SPIRVOperandVec Ops;

        SPIRVID XDimCstID =
            getSPIRVValue(mdconst::extract<ConstantInt>(MD->getOperand(0)));
        SPIRVID YDimCstID =
            getSPIRVValue(mdconst::extract<ConstantInt>(MD->getOperand(1)));
        SPIRVID ZDimCstID =
            getSPIRVValue(mdconst::extract<ConstantInt>(MD->getOperand(2)));

        Ops << GV.getValueType() << XDimCstID << YDimCstID
            << ZDimCstID;

        InitializerID =
            addSPIRVInst<kGlobalVariables>(spv::OpConstantComposite, Ops);
      } else {
        HasMD = false;
      }
    }

    // If all kernels do not have metadata for reqd_work_group_size, generate
    // OpSpecConstants for x/y/z dimension.
    if (!HasMD || clspv::Option::NonUniformNDRangeSupported()) {
      //
      // Generate OpSpecConstants for x/y/z dimension.
      //
      // Ops[0] : Result Type ID
      // Ops[1] : Constant size for x/y/z dimension (Literal Number).

      // Allocate spec constants for workgroup size.
      clspv::AddWorkgroupSpecConstants(module);

      SPIRVOperandVec Ops;
      SPIRVID result_type_id = getSPIRVType(
          dyn_cast<VectorType>(GV.getValueType())->getElementType());

      // X Dimension
      Ops << result_type_id << 1;
      SPIRVID XDimCstID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

      // Y Dimension
      Ops.clear();
      Ops << result_type_id << 1;
      SPIRVID YDimCstID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

      // Z Dimension
      Ops.clear();
      Ops << result_type_id << 1;
      SPIRVID ZDimCstID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

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
      Ops.clear();
      Ops << GV.getValueType() << XDimCstID << YDimCstID << ZDimCstID;

      InitializerID =
          addSPIRVInst<kConstants>(spv::OpSpecConstantComposite, Ops);
    }
  } else if (BuiltinType == spv::BuiltInWorkDim) {
    // 1. Generate a specialization constant with a default of 3.
    // 2. Allocate and annotate a SpecId for the constant.
    // 3. Use the spec constant as the initializer for the variable.
    SPIRVOperandVec Ops;

    //
    // Generate OpSpecConstant.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Default literal value

    Ops << IntegerType::get(GV.getContext(), 32) << 3;

    InitializerID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    //
    // Generate SpecId decoration.
    //
    // Ops[0] : target
    // Ops[1] : decoration
    // Ops[2] : SpecId
    auto spec_id = AllocateSpecConstant(module, SpecConstant::kWorkDim);
    Ops.clear();
    Ops << InitializerID << spv::DecorationSpecId << spec_id;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  } else if (BuiltinType == spv::BuiltInGlobalOffset) {
    // 1. Generate a spec constant with a default of {0, 0, 0}.
    // 2. Allocate and annotate SpecIds for the constants.
    // 3. Use the spec constant as the initializer for the variable.
    SPIRVOperandVec Ops;

    //
    // Generate OpSpecConstant for each dimension.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Default literal value
    //
    Ops << IntegerType::get(GV.getContext(), 32) << 0;
    SPIRVID x_id = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    Ops.clear();
    Ops << IntegerType::get(GV.getContext(), 32) << 0;
    SPIRVID y_id = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    Ops.clear();
    Ops << IntegerType::get(GV.getContext(), 32) << 0;
    SPIRVID z_id = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    //
    // Generate SpecId decoration for each dimension.
    //
    // Ops[0] : target
    // Ops[1] : decoration
    // Ops[2] : SpecId
    //
    auto spec_id = AllocateSpecConstant(module, SpecConstant::kGlobalOffsetX);
    Ops.clear();
    Ops << x_id << spv::DecorationSpecId << spec_id;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    spec_id = AllocateSpecConstant(module, SpecConstant::kGlobalOffsetY);
    Ops.clear();
    Ops << y_id << spv::DecorationSpecId << spec_id;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    spec_id = AllocateSpecConstant(module, SpecConstant::kGlobalOffsetZ);
    Ops.clear();
    Ops << z_id << spv::DecorationSpecId << spec_id;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    //
    // Generate OpSpecConstantComposite.
    //
    // Ops[0] : type id
    // Ops[1..n-1] : elements
    //
    Ops.clear();
    Ops << GV.getValueType() << x_id << y_id << z_id;
    InitializerID = addSPIRVInst<kConstants>(spv::OpSpecConstantComposite, Ops);
  } else if (BuiltinType == spv::BuiltInSubgroupMaxSize) {
    // 1. Generate a specialization constant with a default of 1.
    // 2. Allocate and annotate a SpecId for the constant.
    // 3. Use the spec constant as the initializer for the variable.
    SPIRVOperandVec Ops;

    //
    // Generate OpSpecConstant.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Default literal value

    Ops << IntegerType::get(GV.getContext(), 32) << 1;

    InitializerID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    //
    // Generate SpecId decoration.
    //
    // Ops[0] : target
    // Ops[1] : decoration
    // Ops[2] : SpecId
    auto spec_id = AllocateSpecConstant(module, SpecConstant::kSubgroupMaxSize);
    Ops.clear();
    Ops << InitializerID << spv::DecorationSpecId << spec_id;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }

  const auto AS = PTy->getAddressSpace();
  const auto spvSC = GetStorageClass(AS);

  const bool module_scope_constant_external_init =
      (AS == AddressSpace::Constant) && GV.hasInitializer() &&
      clspv::Option::ModuleConstantsInStorageBuffer();

  const bool is_printf_buffer = GV.getName() == PrintfBufferVariableName();

  if (GV.hasInitializer()) {
    auto GVInit = GV.getInitializer();
    if (!isa<UndefValue>(GVInit) && !module_scope_constant_external_init) {
      InitializerID = getSPIRVValue(GVInit);
    }
  }

  // All private, module private, and local global variables can be added to
  // interfaces conservatively.
  const bool interface =
      (AS == AddressSpace::Private || AS == AddressSpace::ModuleScopePrivate ||
       AS == AddressSpace::Local);
  auto ptr_id = getSPIRVPointerType(Ty, GV.getValueType());

  SPIRVID var_id;
  if (!(module_scope_constant_external_init &&
        clspv::Option::PhysicalStorageBuffers())) {
    var_id = addSPIRVGlobalVariable(ptr_id, spvSC, InitializerID, interface);
    VMap[&GV] = var_id;
  }

  auto IsOpenCLBuiltin = [](spv::BuiltIn builtin) {
    return builtin == spv::BuiltInWorkDim ||
           builtin == spv::BuiltInGlobalOffset ||
           builtin == spv::BuiltInSubgroupMaxSize;
  };

  // If we have a builtin (not an OpenCL builtin).
  if (spv::BuiltInMax != BuiltinType && !IsOpenCLBuiltin(BuiltinType)) {
    //
    // Generate OpDecorate.
    //
    // DOps[0] = Target ID
    // DOps[1] = Decoration (Builtin)
    // DOps[2] = BuiltIn ID
    SPIRVID ResultID;

    // WorkgroupSize is different, we decorate the constant composite that has
    // its value, rather than the variable that we use to access the value.
    if (spv::BuiltInWorkgroupSize == BuiltinType) {
      ResultID = InitializerID;
      // Save both the value and variable IDs for later.
      WorkgroupSizeValueID = InitializerID;
      WorkgroupSizeVarID = getSPIRVValue(&GV);
    } else {
      ResultID = getSPIRVValue(&GV);
    }

    SPIRVOperandVec Ops;
    Ops << ResultID << spv::DecorationBuiltIn << BuiltinType;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  } else if (module_scope_constant_external_init) {
    // Emit the intializer as a reflection instruction.
    std::string hexbytes;
    llvm::raw_string_ostream str(hexbytes);
    clspv::ConstantEmitter(DL, str).Emit(GV.getInitializer());
    auto data_id = addSPIRVInst<kDebug>(spv::OpString, str.str().c_str());
    SPIRVOperandVec Ops;
    // If using physical storage buffers, lower the constants GV as a push
    // constant containing a pointer, otherwise use a storage buffer
    if (clspv::Option::PhysicalStorageBuffers()) {
      std::string hexbytes;
      llvm::raw_string_ostream str(hexbytes);
      clspv::ConstantEmitter(DL, str).Emit(GV.getInitializer());

      auto PushConstGV =
          module->getGlobalVariable(clspv::PushConstantsVariableName());
      auto STy = cast<StructType>(PushConstGV->getValueType());
      auto MD = PushConstGV->getMetadata(clspv::PushConstantsMetadataName());
      bool Found = false;
      uint32_t Offset = 0;

      // Find the push constant offset for the module constants pointer
      for (unsigned i = 0; i < STy->getNumElements(); i++) {
        auto pc = static_cast<clspv::PushConstant>(
            mdconst::extract<ConstantInt>(MD->getOperand(i))->getZExtValue());

        if (pc == clspv::PushConstant::ModuleConstantsPointer) {
          Found = true;
          Offset = GetExplicitLayoutStructMemberOffset(STy, i, DL);
        }
      }
      assert(Found);

      Ops << getSPIRVType(Type::getVoidTy(module->getContext()))
          << getReflectionImport()
          << reflection::ExtInstConstantDataPointerPushConstant
          << getSPIRVInt32Constant(Offset) << getSPIRVInt32Constant(8)
          << data_id;
      addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
    } else {
      // This module scope constant is initialized from a storage buffer with
      // data provided by the host at binding 0 of the next descriptor set.
      const uint32_t descriptor_set = TakeDescriptorIndex(module);

      // Reflection instruction for constant data.
      Ops << getSPIRVType(Type::getVoidTy(module->getContext()))
          << getReflectionImport()
          << reflection::ExtInstConstantDataStorageBuffer
          << getSPIRVInt32Constant(descriptor_set) << getSPIRVInt32Constant(0)
          << data_id;
      addSPIRVInst<kReflection>(spv::OpExtInst, Ops);

      // OpDecorate %var DescriptorSet <descriptor_set>
      Ops.clear();
      Ops << VMap[&GV] << spv::DecorationDescriptorSet << descriptor_set;
      addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

      // OpDecorate %var Binding <binding>
      Ops.clear();
      Ops << VMap[&GV] << spv::DecorationBinding << 0;
      addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
    }
  } else if (is_printf_buffer) {
    const uint32_t descriptor_set = TakeDescriptorIndex(module);
    SPIRVOperandVec Ops;
    Ops << var_id << spv::DecorationDescriptorSet << descriptor_set;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    Ops.clear();
    Ops << var_id << spv::DecorationBinding << 0;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    Ops.clear();
    Ops << getSPIRVType(Type::getVoidTy(module->getContext()))
        << getReflectionImport() << reflection::ExtInstPrintfBufferStorageBuffer
        << getSPIRVInt32Constant(descriptor_set) << getSPIRVInt32Constant(0)
        << getSPIRVInt32Constant(clspv::Option::PrintfBufferSize());
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
}

void SPIRVProducerPassImpl::GenerateFuncPrologue(Function &F) {
  ValueMapType &VMap = getValueMap();
  EntryPointVecType &EntryPoints = getEntryPointVec();
  auto &GlobalConstFuncTyMap = getGlobalConstFuncTypeMap();

  FunctionType *FTy = F.getFunctionType();
  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
    auto where = GlobalConstFuncTyMap.find(FTy);
    if (where != GlobalConstFuncTyMap.end()) {
      FTy = where->second.first;
    }
  } else {
    SmallVector<Type *, 4> NewFuncParamTys;
    FunctionType *NewFTy =
        FunctionType::get(FTy->getReturnType(), NewFuncParamTys, false);
    FTy = NewFTy;
  }

  //
  // Generate OPFunction.
  //

  // FOps[0] : Result Type ID
  // FOps[1] : Function Control
  // FOps[2] : Function Type ID
  SPIRVOperandVec FOps;

  Type *inferred_ret_ty = nullptr;
  SmallVector<Type *, 8> inferred_param_tys;
  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {
    for (auto *user : F.users()) {
      if (isa<CallInst>(user)) {
        inferred_ret_ty =
            InferType(user, module->getContext(), &InferredTypeCache);
        if (inferred_ret_ty)
          break;
      }
    }
    for (auto &Arg : F.args()) {
      inferred_param_tys.push_back(
          InferType(&Arg, module->getContext(), &InferredTypeCache));
    }
  } else {
    inferred_ret_ty = FTy->getReturnType();
  }

  SPIRVID ret_type_id =
      getSPIRVPointerType(FTy->getReturnType(), inferred_ret_ty);

  // Find SPIRV instruction for return type.
  FOps << ret_type_id;

  // Check function attributes for SPIRV Function Control.
  uint32_t FuncControl = spv::FunctionControlMaskNone;
  if (F.hasFnAttribute(Attribute::AlwaysInline)) {
    FuncControl |= spv::FunctionControlInlineMask;
  }
  if (F.hasFnAttribute(Attribute::NoInline)) {
    FuncControl |= spv::FunctionControlDontInlineMask;
  }
  // TODO: Check llvm attribute for Function Control Pure.
  if (F.onlyReadsMemory()) {
    FuncControl |= spv::FunctionControlPureMask;
  }
  // TODO: Check llvm attribute for Function Control Const.
  if (F.doesNotAccessMemory()) {
    FuncControl |= spv::FunctionControlConstMask;
  }

  FOps << FuncControl;

  SPIRVID FTyID =
      getSPIRVFunctionType(FTy, inferred_ret_ty, inferred_param_tys);

  FOps << FTyID;

  // Generate SPIRV instruction for function.
  SPIRVID FID = addSPIRVInst(spv::OpFunction, FOps);
  VMap[&F] = FID;

  if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
    EntryPoints.push_back(std::make_pair(&F, FID));
  }

  if (clspv::Option::ShowIDs()) {
    errs() << "Function " << F.getName() << " is " << FID.get() << "\n";
  }

  //
  // Generate OpFunctionParameter for Normal function.
  //
  if (F.getCallingConv() != CallingConv::SPIR_KERNEL) {

    // Iterate Argument for name instead of param type from function type.
    unsigned ArgIdx = 0;
    for (Argument &Arg : F.args()) {
      // ParamOps[0] : Result Type ID
      SPIRVOperandVec Ops;

      // Find SPIRV instruction for parameter type.
      SPIRVID ParamTyID =
          getSPIRVPointerType(Arg.getType(), inferred_param_tys[ArgIdx]);
      Ops << ParamTyID;

      // Generate SPIRV instruction for parameter.
      SPIRVID param_id = addSPIRVInst(spv::OpFunctionParameter, Ops);
      VMap[&Arg] = param_id;

      if (CalledWithCoherentResource(Arg)) {
        // If the arg is passed a coherent resource ever, then decorate this
        // parameter with Coherent too.
        Ops.clear();
        Ops << param_id << spv::DecorationCoherent;
        addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
      }

      // PhysicalStorageBuffer args require a Restrict or Aliased decoration
      if (auto *PtrTy = dyn_cast<PointerType>(Arg.getType())) {
        if (clspv::Option::PhysicalStorageBuffers() &&
            (PtrTy->getAddressSpace() == clspv::AddressSpace::Global ||
             PtrTy->getAddressSpace() == clspv::AddressSpace::Constant)) {
          Ops.clear();
          Ops << param_id
              << (Arg.hasNoAliasAttr() ? spv::DecorationRestrict
                                       : spv::DecorationAliased);
          addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
        }
      }

      ArgIdx++;
    }
  }
}

void SPIRVProducerPassImpl::GenerateModuleInfo() {
  EntryPointVecType &EntryPoints = getEntryPointVec();
  auto &EntryPointInterfaces = getEntryPointInterfacesList();
  std::vector<SPIRVID> &BuiltinDimVec = getBuiltinDimVec();

  SPIRVOperandVec Ops;

  for (auto Capability : CapabilitySet) {
    //
    // Generate OpCapability
    //
    // Ops[0] = Capability
    addSPIRVInst<kCapabilities>(spv::OpCapability, Capability);
  }

  // Storage buffer and variable pointer extensions were made core in SPIR-V
  // 1.3.
  if (SpvVersion() < SPIRVVersion::SPIRV_1_3) {
    //
    // Generate OpExtension.
    //
    // Ops[0] = Name (Literal String)
    //
    addSPIRVInst<kExtensions>(spv::OpExtension,
                              "SPV_KHR_storage_buffer_storage_class");

    if (hasVariablePointers() || hasVariablePointersStorageBuffer()) {
      //
      // Generate OpExtension.
      //
      // Ops[0] = Name (Literal String)
      //
      addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_KHR_variable_pointers");
    }
  }

  if (SpvVersion() < SPIRVVersion::SPIRV_1_4 && hasConvertToF()) {
    addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_KHR_float_controls");
  }

  if (clspv::Option::PhysicalStorageBuffers()) {
    addSPIRVInst<kExtensions>(spv::OpExtension,
                              "SPV_KHR_physical_storage_buffer");
  }

  // Descriptor indexing extension was made core in SPIR-V 1.5.
  if (hasNonUniformPointers() &&
      clspv::Option::SpvVersion() < clspv::Option::SPIRVVersion::SPIRV_1_5) {
    addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_EXT_descriptor_indexing");
  }

  //
  // Generate OpMemoryModel
  //
  // Memory model for Vulkan will always be GLSL450.

  // Ops[0] = Addressing Model
  // Ops[1] = Memory Model
  Ops.clear();
  Ops << (clspv::Option::PhysicalStorageBuffers()
              ? spv::AddressingModelPhysicalStorageBuffer64
              : spv::AddressingModelLogical)
      << spv::MemoryModelGLSL450;

  addSPIRVInst<kMemoryModel>(spv::OpMemoryModel, Ops);

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
    Ops << spv::ExecutionModelGLCompute << EntryPoint.second << name;

    for (auto &Interface : EntryPointInterfaces) {
      Ops << Interface;
    }

    // Starting in SPIR-V 1.4, all statically used global variables must be
    // included in the interface. Private and statically-sized workgroup
    // variables are added to all entry points. Kernel arguments are handled
    // here.
    if (SpvVersion() >= SPIRVVersion::SPIRV_1_4) {
      auto *F = dyn_cast<Function>(EntryPoint.first);
      assert(F);
      assert(F->getCallingConv() == CallingConv::SPIR_KERNEL);

      auto &resource_var_at_index = FunctionToResourceVarsMap[F];
      for (auto *info : resource_var_at_index) {
        if (info) {
          Ops << info->var_id;
        }
      }

      if (clspv::Option::ModuleConstantsInStorageBuffer() &&
          !clspv::Option::PhysicalStorageBuffers()) {
        auto *V = module->getGlobalVariable(
            clspv::ClusteredConstantsVariableName(), true);
        if (V) {
          Ops << getValueMap()[V];
        }
      }

      if (auto *V = module->getGlobalVariable(clspv::PrintfBufferVariableName(),
                                              true)) {
        Ops << getValueMap()[V];
      }

      auto local_spec_id_md =
          module->getNamedMetadata(clspv::LocalSpecIdMetadataName());
      if (local_spec_id_md) {
        for (auto spec_id_op : local_spec_id_md->operands()) {
          if (dyn_cast<Function>(
                  dyn_cast<ValueAsMetadata>(spec_id_op->getOperand(0))
                      ->getValue()) == F) {
            int64_t spec_id =
                mdconst::extract<ConstantInt>(spec_id_op->getOperand(2))
                    ->getSExtValue();
            if (spec_id > 0) {
              auto &info = LocalSpecIdInfoMap[spec_id];
              Ops << info.variable_id;
            }
          }
        }
      }

      // If the kernel uses the global push constant interface it will not be
      // covered by the resource variable iteration above.
      if (auto *PC =
              module->getGlobalVariable(clspv::PushConstantsVariableName())) {
        assert(PC);
        Ops << getValueMap()[PC];
      }
    }

    addSPIRVInst<kEntryPoints>(spv::OpEntryPoint, Ops);
  }

  if (BuiltinDimVec.empty()) {
    for (auto EntryPoint : EntryPoints) {
      const MDNode *MD = dyn_cast<Function>(EntryPoint.first)
                             ->getMetadata("reqd_work_group_size");
      if ((MD != nullptr) && !clspv::Option::NonUniformNDRangeSupported()) {
        //
        // Generate OpExecutionMode
        //

        // Ops[0] = Entry Point ID
        // Ops[1] = Execution Mode
        // Ops[2] ... Ops[n] = Optional literals according to Execution Mode
        Ops.clear();
        Ops << EntryPoint.second << spv::ExecutionModeLocalSize;

        uint32_t XDim = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(0))->getZExtValue());
        uint32_t YDim = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(1))->getZExtValue());
        uint32_t ZDim = static_cast<uint32_t>(
            mdconst::extract<ConstantInt>(MD->getOperand(2))->getZExtValue());

        Ops << XDim << YDim << ZDim;

        addSPIRVInst<kExecutionModes>(spv::OpExecutionMode, Ops);
      }
    }
  }

  // libclc expects the default rounding mode to be RTE
  if (hasConvertToF()) {
    for (auto EntryPoint : EntryPoints) {
      if (clspv::Option::FP16() &&
          ExecutionModeRoundingModeRTE(RoundingModeRTE::fp16)) {
        Ops.clear();
        Ops << EntryPoint.second << spv::ExecutionModeRoundingModeRTE << 16;
        addSPIRVInst<kExecutionModes>(spv::OpExecutionMode, Ops);
      }
      if (ExecutionModeRoundingModeRTE(RoundingModeRTE::fp32)) {
        Ops.clear();
        Ops << EntryPoint.second << spv::ExecutionModeRoundingModeRTE << 32;
        addSPIRVInst<kExecutionModes>(spv::OpExecutionMode, Ops);
      }
      if (clspv::Option::FP64() &&
          ExecutionModeRoundingModeRTE(RoundingModeRTE::fp64)) {
        Ops.clear();
        Ops << EntryPoint.second << spv::ExecutionModeRoundingModeRTE << 64;
        addSPIRVInst<kExecutionModes>(spv::OpExecutionMode, Ops);
      }
    }
  }

  //
  // Generate OpSource.
  //
  // Ops[0] = SourceLanguage ID
  // Ops[1] = Version (LiteralNum)
  //
  uint32_t LangID = spv::SourceLanguageUnknown;
  uint32_t LangVer = 0;
  switch (clspv::Option::Language()) {
  case clspv::Option::SourceLanguage::OpenCL_C_10:
    LangID = spv::SourceLanguageOpenCL_C;
    LangVer = 100;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_11:
    LangID = spv::SourceLanguageOpenCL_C;
    LangVer = 110;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_12:
    LangID = spv::SourceLanguageOpenCL_C;
    LangVer = 120;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_20:
    LangID = spv::SourceLanguageOpenCL_C;
    LangVer = 200;
    break;
  case clspv::Option::SourceLanguage::OpenCL_C_30:
    LangID = spv::SourceLanguageOpenCL_C;
    LangVer = 300;
    break;
  case clspv::Option::SourceLanguage::OpenCL_CPP:
    LangID = spv::SourceLanguageOpenCL_CPP;
    LangVer = 100;
    break;
  default:
    break;
  }

  Ops.clear();
  Ops << LangID << LangVer;
  addSPIRVInst<kDebug>(spv::OpSource, Ops);

  if (!BuiltinDimVec.empty()) {
    //
    // Generate OpDecorates for x/y/z dimension.
    //
    // Ops[0] = Target ID
    // Ops[1] = Decoration (SpecId)
    // Ops[2] = Specialization Constant ID (Literal Number)

    // X Dimension
    Ops.clear();
    Ops << BuiltinDimVec[0] << spv::DecorationSpecId << 0;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    // Y Dimension
    Ops.clear();
    Ops << BuiltinDimVec[1] << spv::DecorationSpecId << 1;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    // Z Dimension
    Ops.clear();
    Ops << BuiltinDimVec[2] << spv::DecorationSpecId << 2;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }
}

void SPIRVProducerPassImpl::GenerateEntryPointInitialStores() {
  // Work around a driver bug.  Initializers on Private variables might not
  // work. So the start of the kernel should store the initializer value to the
  // variables.  Yes, *every* entry point pays this cost if *any* entry point
  // uses this builtin.  At this point I judge this to be an acceptable tradeoff
  // of complexity vs. runtime, for a broken driver.
  // TODO(dneto): Remove this at some point once fixed drivers are widely
  // available.
  if (WorkgroupSizeVarID.isValid()) {
    assert(WorkgroupSizeValueID.isValid());

    SPIRVOperandVec Ops;
    Ops << WorkgroupSizeVarID << WorkgroupSizeValueID;

    addSPIRVInst(spv::OpStore, Ops);
  }
}

void SPIRVProducerPassImpl::GenerateFuncBody(Function &F) {
  ValueMapType &VMap = getValueMap();

  const bool IsKernel = F.getCallingConv() == CallingConv::SPIR_KERNEL;

  for (BasicBlock &BB : F) {
    // Register BasicBlock to ValueMap.

    //
    // Generate OpLabel for Basic Block.
    //
    VMap[&BB] = addSPIRVInst(spv::OpLabel);
    if (NameBasicBlocks) {
      SPIRVOperandVec Ops;
      Ops << VMap[&BB] << BB.getName();
      addSPIRVInst<kNames>(spv::OpName, Ops);
    }

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

spv::Op SPIRVProducerPassImpl::GetSPIRVCmpOpcode(CmpInst *I) {
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

spv::Op SPIRVProducerPassImpl::GetSPIRVPointerCmpOpcode(CmpInst *I) {
  const std::map<CmpInst::Predicate, spv::Op> Map = {
      {CmpInst::ICMP_UGT, spv::OpSGreaterThan},
      {CmpInst::ICMP_UGE, spv::OpSGreaterThanEqual},
      {CmpInst::ICMP_ULT, spv::OpSLessThan},
      {CmpInst::ICMP_ULE, spv::OpSLessThanEqual}};

  assert(0 != Map.count(I->getPredicate()));

  return Map.at(I->getPredicate());
}

spv::Op SPIRVProducerPassImpl::GetSPIRVCastOpcode(Instruction &I) {
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
      {Instruction::BitCast, spv::OpBitcast},
      {Instruction::PtrToInt, spv::OpConvertPtrToU},
      {Instruction::IntToPtr, spv::OpConvertUToPtr},
      };

  assert(0 != Map.count(I.getOpcode()));

  return Map.at(I.getOpcode());
}

spv::Op SPIRVProducerPassImpl::GetSPIRVBinaryOpcode(Instruction &I) {
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

SPIRVID SPIRVProducerPassImpl::getSPIRVBuiltin(spv::BuiltIn BID,
                                               spv::Capability Cap) {
  SPIRVID RID;

  auto ii = BuiltinConstantMap.find(BID);

  if (ii != BuiltinConstantMap.end()) {
    return ii->second;
  } else {
    addCapability(Cap);

    auto *data_ty = IntegerType::get(module->getContext(), 32);
    auto *ptr_ty = data_ty->getPointerTo(AddressSpace::Input);
    auto ptr_id = getSPIRVPointerType(ptr_ty, data_ty);
    RID = addSPIRVGlobalVariable(ptr_id, spv::StorageClassInput);

    BuiltinConstantMap[BID] = RID;

    //
    // Generate OpDecorate.
    //
    // Ops[0] : target
    // Ops[1] : decoration
    // Ops[2] : SpecId
    SPIRVOperandVec Ops;
    Ops << RID << spv::DecorationBuiltIn << static_cast<int>(BID);

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }

  return RID;
}

SPIRVID
SPIRVProducerPassImpl::GenerateClspvInstruction(CallInst *Call,
                                                const FunctionInfo &FuncInfo) {
  SPIRVID RID;

  switch (FuncInfo.getType()) {
  case Builtins::kClspvCompositeConstruct:
    RID = addSPIRVPlaceholder(Call);
    break;
  case Builtins::kClspvResource: {
    if (ResourceVarDeferredLoadCalls.count(Call) && Call->hasNUsesOrMore(1)) {
      // Generate an OpLoad
      SPIRVOperandVec Ops;

      Ops << Call->getArgOperand(ClspvOperand::kResourceDataType)->getType()
          << ResourceVarDeferredLoadCalls[Call];

      RID = addSPIRVInst(spv::OpLoad, Ops);

    } else {
      // This maps to an OpVariable we've already generated.
      // No code is generated for the call.
    }
    break;
  }
  case Builtins::kClspvLocal: {
    // Don't codegen an instruction here, but instead map this call directly
    // to the workgroup variable id.
    int spec_id = static_cast<int>(
        cast<ConstantInt>(Call->getOperand(ClspvOperand::kWorkgroupSpecId))
            ->getSExtValue());
    const auto &info = LocalSpecIdInfoMap[spec_id];
    RID = info.variable_id;
    break;
  }
  case Builtins::kClspvSamplerVarLiteral: {
    // Sampler initializers become a load of the corresponding sampler.
    // Map this to a load from the variable.
    const auto sampler_value = static_cast<unsigned>(
        dyn_cast<ConstantInt>(Call->getArgOperand(ClspvOperand::kSamplerParams))
            ->getZExtValue());

    // Generate an OpLoad
    SPIRVOperandVec Ops;

    Ops << SamplerDataTy << SamplerLiteralToIDMap[sampler_value];

    RID = addSPIRVInst(spv::OpLoad, Ops);
    break;
  }
  case Builtins::kSpirvAtomicXor: {
    // Handle SPIR-V intrinsics
    SPIRVOperandVec Ops;

    if (!Call->getType()->isVoidTy()) {
      Ops << Call->getType();
    }

    for (unsigned i = 0; i < Call->arg_size(); i++) {
      Ops << Call->getArgOperand(i);
    }

    RID = addSPIRVInst(spv::OpAtomicXor, Ops);
    break;
  }
  case Builtins::kSpirvOp: {
    // Handle SPIR-V intrinsics
    auto *arg0 = dyn_cast<ConstantInt>(Call->getArgOperand(0));
    spv::Op opcode = static_cast<spv::Op>(arg0->getZExtValue());
    if (opcode != spv::OpNop) {
      SPIRVOperandVec Ops;

      if (!Call->getType()->isVoidTy()) {
        Ops << Call->getType();
      }

      for (unsigned i = 1; i < Call->arg_size(); i++) {
        Ops << Call->getArgOperand(i);
      }

      RID = addSPIRVInst(opcode, Ops);
    }
    break;
  }
  case Builtins::kClspvGetImageSizes: {
    addCapability(spv::CapabilityImageQuery);
    Value *Image = Call->getArgOperand(0);
    auto *ImageTy = InferType(Image, module->getContext(), &InferredTypeCache);
    if (ImageDimensionality(ImageTy) != spv::Dim3D ||
        !IsSampledImageType(ImageTy)) {
      llvm_unreachable("Unexpected Image in Builtins::kClspvGetImageSizes");
    }

    SPIRVOperandVec Ops;

    Ops << getSPIRVType(
               FixedVectorType::get(Type::getInt32Ty(module->getContext()), 3))
        << Image << getSPIRVInt32Constant(0);
    RID = addSPIRVInst(spv::OpImageQuerySizeLod, Ops);

    Ops.clear();
    auto int4Ty =
        FixedVectorType::get(Type::getInt32Ty(module->getContext()), 4);
    Ops << getSPIRVType(int4Ty) << RID
        << getSPIRVConstant(ConstantInt::get(int4Ty, (uint64_t)1)) << 0 << 1
        << 2 << 4;
    RID = addSPIRVInst(spv::OpVectorShuffle, Ops);

    Ops.clear();
    Ops << getSPIRVType(
               FixedVectorType::get(Type::getFloatTy(module->getContext()), 4))
        << RID;
    RID = addSPIRVInst(spv::OpConvertUToF, Ops);
    break;
  }
  default:
    llvm_unreachable("Unknown CLSPV Instruction");
    break;
  }
  return RID;
}

SPIRVID
SPIRVProducerPassImpl::GenerateImageInstruction(CallInst *Call,
                                                const FunctionInfo &FuncInfo) {
  SPIRVID RID;

  auto GetExtendMask = [](Type *sample_type, bool is_int_image) -> uint32_t {
    if (SpvVersion() >= SPIRVVersion::SPIRV_1_4 &&
        sample_type->getScalarType()->isIntegerTy()) {
      if (is_int_image)
        return spv::ImageOperandsSignExtendMask;
      else
        return spv::ImageOperandsZeroExtendMask;
    }
    return 0;
  };

  auto *image_ty = InferType(Call->getArgOperand(0), module->getContext(),
                             &InferredTypeCache);
  LLVMContext &Context = module->getContext();
  switch (FuncInfo.getType()) {
  case Builtins::kReadImagef:
  case Builtins::kReadImageh:
  case Builtins::kReadImagei:
  case Builtins::kReadImageui: {
    // read_image is converted to OpSampledImage and OpImageSampleExplicitLod.
    // Additionally, OpTypeSampledImage is generated.
    const auto &pi = FuncInfo.getParameter(1);
    if (pi.isSampler()) {
      //
      // Generate OpSampledImage.
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Image ID
      // Ops[2] = Sampler ID
      //
      SPIRVOperandVec Ops;

      Value *Image = Call->getArgOperand(0);
      Value *Sampler = Call->getArgOperand(1);
      Value *Coordinate = Call->getArgOperand(2);

      TypeMapType &OpImageTypeMap = getImageTypeMap();
      SPIRVID ImageTyID = OpImageTypeMap[image_ty];

      Ops << ImageTyID << Image << Sampler;

      SPIRVID SampledImageID = addSPIRVInst(spv::OpSampledImage, Ops);

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

      const bool is_int_image = IsIntImageType(image_ty);
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }

      uint32_t mask = spv::ImageOperandsLodMask |
                      GetExtendMask(Call->getType(), is_int_image);
      Constant *CstFP0 = ConstantFP::get(Context, APFloat(0.0f));
      Ops << result_type << SampledImageID << Coordinate << mask << CstFP0;

      RID = addSPIRVInst(spv::OpImageSampleExplicitLod, Ops);

      if (is_int_image) {
        // Generate the bitcast.
        Ops.clear();
        Ops << Call->getType() << RID;
        RID = addSPIRVInst(spv::OpBitcast, Ops);
      }
    } else if (IsStorageImageType(image_ty)) {
      // read_image on a storage image is mapped to OpImageRead.
      Value *Image = Call->getArgOperand(0);
      Value *Coordinate = Call->getArgOperand(1);

      //
      // Generate OpImageRead
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Image ID
      // Ops[2] = Coordinate
      // No optional image operands.
      //
      SPIRVOperandVec Ops;

      const bool is_int_image = IsIntImageType(image_ty);
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }

      Ops << result_type << Image << Coordinate;
      uint32_t mask = GetExtendMask(Call->getType(), is_int_image);
      if (mask != 0)
        Ops << mask;
      RID = addSPIRVInst(spv::OpImageRead, Ops);

      if (is_int_image) {
        // Generate the bitcast.
        Ops.clear();
        Ops << Call->getType() << RID;
        RID = addSPIRVInst(spv::OpBitcast, Ops);
      }

      // OpImageRead requires StorageImageReadWithoutFormat.
      addCapability(spv::CapabilityStorageImageReadWithoutFormat);
    } else {
      // read_image on a sampled image (without a sampler) is mapped to
      // OpImageFetch.
      Value *Image = Call->getArgOperand(0);
      Value *Coordinate = Call->getArgOperand(1);

      //
      // Generate OpImageFetch
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Image ID
      // Ops[2] = Coordinate ID
      // Ops[3] = Lod
      // Ops[4] = 0
      //
      SPIRVOperandVec Ops;

      const bool is_int_image = IsIntImageType(image_ty);
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }
      Ops << result_type << Image << Coordinate;
      if (ImageDimensionality(image_ty) != spv::DimBuffer) {
        uint32_t mask = spv::ImageOperandsLodMask |
                        GetExtendMask(Call->getType(), is_int_image);
        Ops << mask << getSPIRVInt32Constant(0);
      }

      RID = addSPIRVInst(spv::OpImageFetch, Ops);

      if (is_int_image) {
        // Generate the bitcast.
        Ops.clear();
        Ops << Call->getType() << RID;
        RID = addSPIRVInst(spv::OpBitcast, Ops);
      }
    }
    break;
  }

  case Builtins::kWriteImagef:
  case Builtins::kWriteImageh:
  case Builtins::kWriteImagei:
  case Builtins::kWriteImageui: {
    // write_image is mapped to OpImageWrite.
    //
    // Generate OpImageWrite.
    //
    // Ops[0] = Image ID
    // Ops[1] = Coordinate ID
    // Ops[2] = Texel ID
    // Ops[3] = (Optional) Image Operands Type (Literal Number)
    // Ops[4] ... Ops[n] = (Optional) Operands ID
    //
    SPIRVOperandVec Ops;

    Value *Image = Call->getArgOperand(0);
    Value *Coordinate = Call->getArgOperand(1);
    Value *Texel = Call->getArgOperand(2);

    SPIRVID TexelID = getSPIRVValue(Texel);

    const bool is_int_image = IsIntImageType(image_ty);
    if (is_int_image) {
      // Generate a bitcast to v4int and use it as the texel value.
      Ops << v4int32ID << TexelID;
      TexelID = addSPIRVInst(spv::OpBitcast, Ops);
      Ops.clear();
    }
    Ops << Image << Coordinate << TexelID;
    uint32_t mask = GetExtendMask(Texel->getType(), is_int_image);
    if (mask != 0)
      Ops << mask;
    RID = addSPIRVInst(spv::OpImageWrite, Ops);

    // Image writes require StorageImageWriteWithoutFormat.
    addCapability(spv::CapabilityStorageImageWriteWithoutFormat);
    break;
  }

  case Builtins::kGetImageHeight:
  case Builtins::kGetImageWidth:
  case Builtins::kGetImageDepth:
  case Builtins::kGetImageArraySize:
  case Builtins::kGetImageDim: {
    // get_image_* is mapped to OpImageQuerySize or OpImageQuerySizeLod
    addCapability(spv::CapabilityImageQuery);

    //
    // Generate OpImageQuerySize[Lod]
    //
    // Ops[0] = Image ID
    //
    // Result type has components equal to the dimensionality of the image,
    // plus 1 if the image is arrayed.
    //
    // %sizes = OpImageQuerySize[Lod] %uint[2|3|4] %im [%uint_0]
    SPIRVOperandVec Ops;

    // Implement:
    //     %sizes = OpImageQuerySize[Lod] %uint[2|3|4] %im [%uint_0]
    SPIRVID SizesTypeID;

    Value *Image = Call->getArgOperand(0);
    const uint32_t dim = ImageNumDimensions(image_ty);
    const uint32_t components =
        dim + (IsArrayImageType(image_ty) ? 1 : 0);
    if (components == 1) {
      SizesTypeID = getSPIRVType(Type::getInt32Ty(Context));
    } else {
      SizesTypeID = getSPIRVType(
          FixedVectorType::get(Type::getInt32Ty(Context), components));
    }
    Ops << SizesTypeID << Image;
    spv::Op query_opcode = spv::OpImageQuerySize;
    if (IsSampledImageType(image_ty) &&
        ImageDimensionality(image_ty) != spv::DimBuffer) {
      query_opcode = spv::OpImageQuerySizeLod;
      // Need explicit 0 for Lod operand.
      Ops << getSPIRVInt32Constant(0);
    }

    RID = addSPIRVInst(query_opcode, Ops);

    // May require an extra instruction to create the appropriate result of
    // the builtin function.
    if (FuncInfo.getType() == Builtins::kGetImageDim) {
      if (dim == 3) {
        // get_image_dim returns an int4 for 3D images.
        //

        // Implement:
        //   %result = OpCompositeConstruct %uint4 %sizes %uint_0
        Ops.clear();
        Ops << FixedVectorType::get(Type::getInt32Ty(Context), 4) << RID
            << getSPIRVInt32Constant(0);

        RID = addSPIRVInst(spv::OpCompositeConstruct, Ops);
      } else if (dim != components) {
        // get_image_dim return an int2 regardless of the arrayedness of the
        // image. If the image is arrayed an element must be dropped from the
        // query result.
        //

        // Implement:
        //   %result = OpVectorShuffle %uint2 %sizes %sizes 0 1
        Ops.clear();
        Ops << FixedVectorType::get(Type::getInt32Ty(Context), 2) << RID << RID
            << 0 << 1;

        RID = addSPIRVInst(spv::OpVectorShuffle, Ops);
      }
    } else if (components > 1) {
      // Implement:
      //     %result = OpCompositeExtract %uint %sizes <component number>
      Ops.clear();
      Ops << Type::getInt32Ty(Context) << RID;

      uint32_t component = 0;
      if (FuncInfo.getType() == Builtins::kGetImageHeight)
        component = 1;
      else if (FuncInfo.getType() == Builtins::kGetImageDepth)
        component = 2;
      else if (FuncInfo.getType() == Builtins::kGetImageArraySize)
        component =
            components - 1; // array size is the last element of the vector
      Ops << component;

      RID = addSPIRVInst(spv::OpCompositeExtract, Ops);

      // get_image_array_size returns a size_t so we need to extend it to an
      // i64 if size_t is 64-bit
      if (FuncInfo.getType() == Builtins::kGetImageArraySize &&
          clspv::PointersAre64Bit(*module)) {
        Ops.clear();
        Ops << Type::getInt64Ty(Context) << RID;
        RID = addSPIRVInst(spv::OpUConvert, Ops);
      }
    }
    break;
  }
  case kGetImageChannelDataType:
  case kGetImageChannelOrder: {
    auto GV = module->getGlobalVariable(clspv::PushConstantsVariableName());
    auto offset = getSPIRVValue(mdconst::extract<ConstantInt>(
        Call->getMetadata(clspv::ImageGetterPushConstantOffsetName())
            ->getOperand(0)));
    auto i32 = IntegerType::get(module->getContext(), 32);

    SPIRVOperandVec Ops;
    Ops << getSPIRVPointerType(
               PointerType::get(i32, GV->getType()->getPointerAddressSpace()),
               i32)
        << getSPIRVValue(GV)
        << getSPIRVInt32Constant(GV->getValueType()->getStructNumElements() - 1)
        << offset;
    RID = addSPIRVInst(spv::OpAccessChain, Ops);

    Ops.clear();
    Ops << getSPIRVType(i32) << RID;
    RID = addSPIRVInst(spv::OpLoad, Ops);
  } break;
  default:
    llvm_unreachable("Unsupported Image builtin");
  }

  return RID;
}

SPIRVID
SPIRVProducerPassImpl::GenerateSubgroupInstruction(
    CallInst *Call, const FunctionInfo &FuncInfo) {

  // requires SPIRV version 1.3 or greater
  if (SpvVersion() != SPIRVVersion::SPIRV_1_3) {
    // llvm_unreachable("SubGroups extension requires SPIRV 1.3 or greater");
    // TODO(sjw): error out gracefully
  }

  auto loadBuiltin = [this, Call](spv::BuiltIn spvBI,
                                  spv::Capability spvCap =
                                      spv::CapabilityGroupNonUniform) {
    SPIRVOperandVec Ops;
    Ops << Call->getType() << this->getSPIRVBuiltin(spvBI, spvCap);

    return addSPIRVInst(spv::OpLoad, Ops);
  };

  spv::Op op = spv::OpNop;
  switch (FuncInfo.getType()) {
  case Builtins::kGetSubGroupSize:
    return loadBuiltin(spv::BuiltInSubgroupSize);
  case Builtins::kGetNumSubGroups:
    return loadBuiltin(spv::BuiltInNumSubgroups);
  case Builtins::kGetSubGroupId:
    return loadBuiltin(spv::BuiltInSubgroupId);
  case Builtins::kGetSubGroupLocalId:
    return loadBuiltin(spv::BuiltInSubgroupLocalInvocationId);

  case Builtins::kSubGroupBroadcast:
    if (SpvVersion() < SPIRVVersion::SPIRV_1_5 &&
        !dyn_cast<ConstantInt>(Call->getOperand(1))) {
      llvm_unreachable("sub_group_broadcast requires constant lane Id for "
                       "SPIRV version < 1.5");
    }
    addCapability(spv::CapabilityGroupNonUniformBallot);
    op = spv::OpGroupNonUniformBroadcast;
    break;

  case Builtins::kSubGroupAll:
    addCapability(spv::CapabilityGroupNonUniformVote);
    op = spv::OpGroupNonUniformAll;
    break;
  case Builtins::kSubGroupAny:
    addCapability(spv::CapabilityGroupNonUniformVote);
    op = spv::OpGroupNonUniformAny;
    break;
  case Builtins::kSubGroupReduceAdd:
  case Builtins::kSubGroupScanExclusiveAdd:
  case Builtins::kSubGroupScanInclusiveAdd: {
    addCapability(spv::CapabilityGroupNonUniformArithmetic);
    if (FuncInfo.getParameter(0).type_id == Type::IntegerTyID) {
      op = spv::OpGroupNonUniformIAdd;
    } else {
      op = spv::OpGroupNonUniformFAdd;
    }
    break;
  }
  case Builtins::kSubGroupReduceMin:
  case Builtins::kSubGroupScanExclusiveMin:
  case Builtins::kSubGroupScanInclusiveMin: {
    addCapability(spv::CapabilityGroupNonUniformArithmetic);
    auto &param = FuncInfo.getParameter(0);
    if (param.type_id == Type::IntegerTyID) {
      op = param.is_signed ? spv::OpGroupNonUniformSMin
                           : spv::OpGroupNonUniformUMin;
    } else {
      op = spv::OpGroupNonUniformFMin;
    }
    break;
  }
  case Builtins::kSubGroupReduceMax:
  case Builtins::kSubGroupScanExclusiveMax:
  case Builtins::kSubGroupScanInclusiveMax: {
    addCapability(spv::CapabilityGroupNonUniformArithmetic);
    auto &param = FuncInfo.getParameter(0);
    if (param.type_id == Type::IntegerTyID) {
      op = param.is_signed ? spv::OpGroupNonUniformSMax
                           : spv::OpGroupNonUniformUMax;
    } else {
      op = spv::OpGroupNonUniformFMax;
    }
    break;
  }

  case Builtins::kGetEnqueuedNumSubGroups:
  case Builtins::kGetMaxSubGroupSize:
  case Builtins::kSubGroupBarrier:
  case Builtins::kSubGroupReserveReadPipe:
  case Builtins::kSubGroupReserveWritePipe:
  case Builtins::kSubGroupCommitReadPipe:
  case Builtins::kSubGroupCommitWritePipe:
  case Builtins::kGetKernelSubGroupCountForNdrange:
  case Builtins::kGetKernelMaxSubGroupSizeForNdrange:
  default:
    Call->print(errs());
    llvm_unreachable("Unsupported sub_group operation");
    break;
  }

  assert(op != spv::OpNop);

  SPIRVOperandVec Operands;

  //
  // Generate OpGroupNonUniform*
  //
  // Ops[0] = Result Type ID
  // Ops[1] = ScopeSubgroup
  // Ops[2] = Value ID
  // Ops[3] = Local ID

  // The result type.
  switch (FuncInfo.getType()) {
  case Builtins::kSubGroupAny:
  case Builtins::kSubGroupAll:
    // SPIR-V needs a bool return type for any/all.
    Operands << getSPIRVType(Type::getInt1Ty(module->getContext()));
    break;
  default:
    Operands << Call->getType();
    break;
  }

  // Subgroup Scope
  Operands << getSPIRVInt32Constant(spv::ScopeSubgroup);

  switch (FuncInfo.getType()) {
  case Builtins::kSubGroupReduceAdd:
  case Builtins::kSubGroupReduceMin:
  case Builtins::kSubGroupReduceMax:
    Operands << spv::GroupOperationReduce;
    break;
  case Builtins::kSubGroupScanExclusiveAdd:
  case Builtins::kSubGroupScanExclusiveMin:
  case Builtins::kSubGroupScanExclusiveMax:
    Operands << spv::GroupOperationExclusiveScan;
    break;
  case Builtins::kSubGroupScanInclusiveAdd:
  case Builtins::kSubGroupScanInclusiveMin:
  case Builtins::kSubGroupScanInclusiveMax:
    Operands << spv::GroupOperationInclusiveScan;
    break;
  default:
    break;
  }

  SPIRVID RID;
  switch (FuncInfo.getType()) {
  case Builtins::kSubGroupAny:
  case Builtins::kSubGroupAll: {
    // OpenCL uses an int predicate instead of the bool from SPIR-V.
    // Generate:
    // tmp = predicate != 0
    // op = Any/All predicate
    // RID = op ? 1 : 0
    SPIRVOperandVec Ops;
    Ops << getSPIRVType(Type::getInt1Ty(module->getContext()))
        << Call->getArgOperand(0) << ConstantInt::get(Call->getType(), 0);
    auto cmp = addSPIRVInst(spv::OpINotEqual, Ops);
    Ops.clear();
    Operands << cmp;
    auto subgroup = addSPIRVInst(op, Operands);
    Ops << Call->getType() << subgroup << ConstantInt::get(Call->getType(), 1)
        << ConstantInt::get(Call->getType(), 0);
    RID = addSPIRVInst(spv::OpSelect, Ops);
    break;
  }
  default:
    for (Use &use : Call->args()) {
      Operands << use.get();
    }
    RID = addSPIRVInst(op, Operands);
    break;
  }

  return RID;
}

SPIRVID SPIRVProducerPassImpl::GenerateShuffle2FromCall(Type *Ty, Value *SrcA,
                                                        Value *SrcB,
                                                        Value *Mask) {
  assert(Ty->isVectorTy());
  assert(SrcA->getType() == SrcB->getType());
  auto MaskTy = Mask->getType();
  assert(MaskTy->isVectorTy());
  auto MaskVTy = cast<FixedVectorType>(MaskTy);
  auto MaskNumElements = MaskVTy->getNumElements();
  SPIRVID RID;

  if (auto CstMask = dyn_cast<ConstantDataVector>(Mask)) {
    SPIRVOperandVec Ops;
    Ops << Ty << SrcA << SrcB;
    for (unsigned int each = 0; each < MaskNumElements; each++) {
      auto CstInt = dyn_cast<ConstantInt>(CstMask->getAggregateElement(each));
      assert(CstInt);
      Ops << (unsigned)CstInt->getZExtValue();
    }
    RID = addSPIRVInst(spv::OpVectorShuffle, Ops);
  } else {
    auto VTy = cast<FixedVectorType>(Ty);
    auto ScalarTy = VTy->getScalarType();
    auto MaskScalarTy = MaskVTy->getScalarType();
    auto NumElements =
        (cast<FixedVectorType>(SrcA->getType()))->getNumElements();

    SPIRVOperandVec Ops;
    Ops << VTy;
    RID = addSPIRVInst(spv::OpUndef, Ops);

    bool isShuffle2 = SrcA != SrcB;

    auto CstNumElements = getSPIRVValue(
        ConstantInt::get(Type::getIntNTy(module->getContext(),
                                         MaskScalarTy->getScalarSizeInBits()),
                         NumElements));

    for (unsigned each = 0; each < MaskNumElements; each++) {
      Ops.clear();
      Ops << MaskScalarTy << Mask << each;
      auto Index = addSPIRVInst(spv::OpCompositeExtract, Ops);

      Ops.clear();
      Ops << MaskScalarTy << Index << CstNumElements;
      auto IndexMod = addSPIRVInst(spv::OpUMod, Ops);

      Ops.clear();
      Ops << ScalarTy << SrcA << IndexMod;
      auto Value = addSPIRVInst(spv::OpVectorExtractDynamic, Ops);

      if (isShuffle2) {
        Ops.clear();
        Ops << ScalarTy << SrcB << IndexMod;
        auto ValueB = addSPIRVInst(spv::OpVectorExtractDynamic, Ops);

        Ops.clear();
        Ops << MaskScalarTy << Index
            << getSPIRVValue(ConstantInt::get(
                   Type::getIntNTy(module->getContext(),
                                   MaskScalarTy->getScalarSizeInBits()),
                   NumElements * 2));
        auto IndexMod2 = addSPIRVInst(spv::OpUMod, Ops);

        Ops.clear();
        Ops << Type::getInt1Ty(module->getContext()) << IndexMod2
            << CstNumElements;
        auto Cmp = addSPIRVInst(spv::OpUGreaterThanEqual, Ops);

        Ops.clear();
        Ops << ScalarTy << Cmp << ValueB << Value;
        Value = addSPIRVInst(spv::OpSelect, Ops);
      }

      Ops.clear();
      Ops << VTy << Value << RID << each;
      RID = addSPIRVInst(spv::OpCompositeInsert, Ops);
    }
  }
  return RID;
}

SPIRVID SPIRVProducerPassImpl::GeneratePopcount(Type *Ty, Value *BaseValue,
                                                LLVMContext &Context) {
  // The Base operand of any OpBitCount, OpBitReverse, OpBitFieldInsert,
  // OpBitFieldSExtract, or OpBitFieldUExtract instruction must be a 32-bit
  // integer scalar or a vector of 32-bit integers.
  // https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap46.html#VUID-StandaloneSpirv-Base-04781
  // Thus, non 32-bit types need to be managed explicitly.
  SPIRVID RID;
  const int BitcountSize = 32;
  Type *Int32Ty = Ty->getInt32Ty(Context);
  if (Ty->isVectorTy())
    Int32Ty = VectorType::get(Int32Ty, dyn_cast<VectorType>(Ty));
  auto TyBitWidth = Ty->getScalarSizeInBits();

  SPIRVOperandVec Ops;
  if (TyBitWidth == BitcountSize * 2) {
    Ops.clear();
    Ops << Int32Ty << BaseValue;
    auto convertLower = addSPIRVInst(spv::OpUConvert, Ops);

    Ops.clear();
    Ops << Int32Ty << convertLower;
    auto bitcountLower = addSPIRVInst(spv::OpBitCount, Ops);

    Ops.clear();
    Ops << Ty << BaseValue << ConstantInt::get(Ty, BitcountSize);
    auto UpperValue = addSPIRVInst(spv::OpShiftRightLogical, Ops);

    Ops.clear();
    Ops << Int32Ty << UpperValue;
    auto convertUpper = addSPIRVInst(spv::OpUConvert, Ops);

    Ops.clear();
    Ops << Int32Ty << convertUpper;
    auto bitcountUpper = addSPIRVInst(spv::OpBitCount, Ops);

    Ops.clear();
    Ops << Int32Ty << bitcountLower << bitcountUpper;
    RID = addSPIRVInst(spv::OpIAdd, Ops);

    Ops.clear();
    Ops << Ty << RID;
    RID = addSPIRVInst(spv::OpUConvert, Ops);
  } else if (TyBitWidth == BitcountSize) {
    Ops << Ty << BaseValue;
    RID = addSPIRVInst(spv::OpBitCount, Ops);
  } else if (TyBitWidth < BitcountSize) {
    Ops << Int32Ty << BaseValue;
    RID = addSPIRVInst(spv::OpUConvert, Ops);

    Ops.clear();
    Ops << Int32Ty << RID;
    RID = addSPIRVInst(spv::OpBitCount, Ops);

    Ops.clear();
    Ops << Ty << RID;
    RID = addSPIRVInst(spv::OpUConvert, Ops);
  } else {
    llvm_unreachable("Unsupported type width for kpopcount");
  }
  return RID;
}

SPIRVID SPIRVProducerPassImpl::GenerateInstructionFromCall(CallInst *Call) {
  LLVMContext &Context = module->getContext();

  auto &func_info = Builtins::Lookup(Call->getCalledFunction());
  auto func_type = func_info.getType();

  if (BUILTIN_IN_GROUP(func_type, Clspv)) {
    return GenerateClspvInstruction(Call, func_info);
  } else if (BUILTIN_IN_GROUP(func_type, Image)) {
    return GenerateImageInstruction(Call, func_info);
  } else if (BUILTIN_IN_GROUP(func_type, SubgroupsKHR)) {
    return GenerateSubgroupInstruction(Call, func_info);
  }

  SPIRVID RID;

  switch (Call->getCalledFunction()->getIntrinsicID()) {
  case Intrinsic::dbg_label:
  case Intrinsic::dbg_value:
  case Intrinsic::dbg_declare: {
    // TODO: Generate 'OpExtInst %void %<> Debug*'
    return RID;
  }
  case Intrinsic::ctlz: {
    // Implement as 31 - FindUMsb. Ignore the second operand of llvm.ctlz.
    SPIRVOperandVec Ops;
    Ops << Call->getType() << getOpExtInstImportID()
        << glsl::ExtInst::ExtInstFindUMsb << Call->getArgOperand(0);
    auto find_msb = addSPIRVInst(spv::OpExtInst, Ops);

    Constant *thirty_one = ConstantInt::get(
        Call->getType(), Call->getType()->getScalarSizeInBits() - 1);
    Ops.clear();
    Ops << Call->getType() << thirty_one << find_msb;
    return addSPIRVInst(spv::OpISub, Ops);
  }
  case Intrinsic::cttz: {
    // Implement as:
    // lsb = FindILsb x
    // res = lsb == -1 ? width : lsb
    //
    // Ignore the second operand of llvm.cttz.
    SPIRVOperandVec Ops;
    Ops << Call->getType() << getOpExtInstImportID()
        << glsl::ExtInst::ExtInstFindILsb << Call->getArgOperand(0);
    auto find_lsb = addSPIRVInst(spv::OpExtInst, Ops);

    auto neg_one = Constant::getAllOnesValue(Call->getType());
    auto i1_ty = Call->getType()->getWithNewBitWidth(1);
    auto width = ConstantInt::get(Call->getType(),
                                  Call->getType()->getScalarSizeInBits());

    Ops.clear();
    Ops << i1_ty << find_lsb << neg_one;
    auto cmp = addSPIRVInst(spv::OpIEqual, Ops);

    Ops.clear();
    Ops << Call->getType() << cmp << width << find_lsb;
    return addSPIRVInst(spv::OpSelect, Ops);
  }
  case Intrinsic::ctpop: {
    return GeneratePopcount(Call->getType(), Call->getArgOperand(0), Context);
  }
  case Intrinsic::bitreverse: {
    SPIRVOperandVec Ops;
    Ops << Call->getType() << Call->getArgOperand(0);
    return addSPIRVInst(spv::OpBitReverse, Ops);
  }

  default:
    break;
  }

  switch (func_type) {
  case Builtins::kPopcount: {
    return GeneratePopcount(Call->getType(), Call->getOperand(0), Context);
  }
  case Builtins::kShuffle: {
    auto Src = Call->getOperand(0);
    auto Mask = Call->getOperand(1);
    auto Ty = Call->getType();

    RID = GenerateShuffle2FromCall(Ty, Src, Src, Mask);
    break;
  }
  case Builtins::kShuffle2: {
    auto SrcA = Call->getOperand(0);
    auto SrcB = Call->getOperand(1);
    auto Mask = Call->getOperand(2);
    auto Ty = Call->getType();

    RID = GenerateShuffle2FromCall(Ty, SrcA, SrcB, Mask);
    break;
  }
  case Builtins::kNativeDivide: {
    SPIRVOperandVec Ops;
    Ops << Call->getType() << Call->getOperand(0) << Call->getOperand(1);
    RID = addSPIRVInst(spv::OpFDiv, Ops);
    break;
  }
  default: {
    glsl::ExtInst EInst = Builtins::getDirectOrIndirectExtInstEnum(func_info);

    // Do not replace functions with implementations.
    if (EInst && Call->getCalledFunction()->isDeclaration()) {
      SPIRVID ExtInstImportID = getOpExtInstImportID();

      //
      // Generate OpExtInst.
      //

      // Ops[0] = Result Type ID
      // Ops[1] = Set ID (OpExtInstImport ID)
      // Ops[2] = Instruction Number (Literal Number)
      // Ops[3] ... Ops[n] = Operand 1, ... , Operand n
      SPIRVOperandVec Ops;

      Ops << Call->getType() << ExtInstImportID << EInst;

      switch (EInst) {
      case glsl::ExtInst::ExtInstSAbs:
        // llvm.abs has a second argument that will not translate to the spirv
        // code.
        Ops << Call->getOperand(0);
        break;
      default:
        for (auto &use : Call->args()) {
          Ops << use.get();
        }
        break;
      }

      RID = addSPIRVInst(spv::OpExtInst, Ops);

      const auto IndirectExtInst = Builtins::getIndirectExtInstEnum(func_info);
      if (IndirectExtInst != kGlslExtInstBad) {
        // Generate one more instruction that uses the result of the extended
        // instruction.  Its result id is one more than the id of the
        // extended instruction.
        auto generate_extra_inst = [this, &Call, &RID](spv::Op opcode,
                                                       Constant *constant) {
          //
          // Generate instruction like:
          //   result = opcode constant <extinst-result>
          //
          // Ops[0] = Result Type ID
          // Ops[1] = Operand 0 ;; the constant, suitably splatted
          // Ops[2] = Operand 1 ;; the result of the extended instruction
          SPIRVOperandVec Ops;

          Type *resultTy = Call->getType();

          if (auto *vectorTy = dyn_cast<VectorType>(resultTy)) {
            constant =
                ConstantVector::getSplat(vectorTy->getElementCount(), constant);
          }
          Ops << resultTy << constant << RID;

          RID = addSPIRVInst(opcode, Ops);
        };

        switch (IndirectExtInst) {
        case glsl::ExtInstAcos:  // Implementing acospi
        case glsl::ExtInstAsin:  // Implementing asinpi
        case glsl::ExtInstAtan:  // Implementing atanpi
        case glsl::ExtInstAtan2: // Implementing atan2pi
          generate_extra_inst(
              spv::OpFMul,
              ConstantFP::get(Call->getType()->getScalarType(), kOneOverPi));
          break;

        default:
          assert(false && "internally inconsistent");
        }
      }
    } else {
      switch (Call->getIntrinsicID()) {
      // These LLVM intrinsics have no SPV equivalent.
      // Because they are optimiser hints, we can safely discard them.
      case Intrinsic::experimental_noalias_scope_decl:
        break;
      default:
        // A real function call (not builtin)
        // Call instruction is deferred because it needs function's ID.
        RID = addSPIRVPlaceholder(Call);
        break;
      }
    }

    break;
  }
  }

  return RID;
}

void SPIRVProducerPassImpl::GenerateInstruction(Instruction &I) {
  ValueMapType &VMap = getValueMap();
  DIFileMap &DbgDIFileMap = getDebugDIFileMap();
  BBDILocMap &LastDILocInBB = getBBDILocMap();
  LLVMContext &Context = module->getContext();

  SPIRVID RID;

  auto md = I.getMetadata("dbg");
  if (md && isa<llvm::DILocation>(md)) {
    auto loc = dyn_cast<llvm::DILocation>(md);
    auto line = loc->getLine();
    auto column = loc->getColumn();
    auto file = loc->getFile();
    if (DbgDIFileMap.find(file) == DbgDIFileMap.end()) {
      DbgDIFileMap[file] = addSPIRVInst<kDebug>(
          spv::OpString, file->getFilename().str().c_str());
    }
    auto find = LastDILocInBB.find(I.getParent());
    if (!(find != LastDILocInBB.end() && find->second.first == line &&
          find->second.second == column)) {
      SPIRVOperandVec Ops;
      Ops << DbgDIFileMap[file] << line << column;
      addSPIRVInst(spv::OpLine, Ops);
      LastDILocInBB[I.getParent()] = std::make_pair(line, column);
    }
  } else if (clspv::Option::DebugInfo()) {
    LastDILocInBB.erase(I.getParent());
    addSPIRVInst(spv::OpNoLine);
  }

  if (clspv::Option::DecorateNonUniform() &&
      I.getOpcode() != Instruction::PHI) {
    for (auto &op : I.operands()) {
      if (!isPointerUniform(op)) {
        setNonUniformPointers();

        SPIRVOperandVec Ops;
        Ops << getSPIRVValue(op) << spv::DecorationNonUniform;
        addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
      }
    }
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
      // Handle zext, sext, uitofp, and sitofp with i1 type specially.
      if ((I.getOpcode() == Instruction::ZExt ||
           I.getOpcode() == Instruction::SExt ||
           I.getOpcode() == Instruction::UIToFP ||
           I.getOpcode() == Instruction::SIToFP) &&
          OpTy->isIntOrIntVectorTy(1)) {
        //
        // Generate OpSelect.
        //

        // Ops[0] = Result Type ID
        // Ops[1] = Condition ID
        // Ops[2] = True Constant ID
        // Ops[3] = False Constant ID
        SPIRVOperandVec Ops;

        Ops << I.getType() << I.getOperand(0);

        if (I.getOpcode() == Instruction::ZExt) {
          Ops << ConstantInt::get(I.getType(), 1);
        } else if (I.getOpcode() == Instruction::SExt) {
          Ops << ConstantInt::getSigned(I.getType(), -1);
        } else if (I.getOpcode() == Instruction::UIToFP) {
          Ops << ConstantFP::get(I.getType(), 1.0);
        } else if (I.getOpcode() == Instruction::SIToFP) {
          Ops << ConstantFP::get(I.getType(), -1.0);
        }

        if (I.getOpcode() == Instruction::ZExt) {
          Ops << Constant::getNullValue(I.getType());
        } else if (I.getOpcode() == Instruction::SExt) {
          Ops << Constant::getNullValue(I.getType());
        } else {
          Ops << ConstantFP::get(I.getType(), 0.0);
        }

        RID = addSPIRVInst(spv::OpSelect, Ops);
      } else if (!clspv::Option::Int8Support() &&
                 I.getOpcode() == Instruction::Trunc && fromI32 && toI8) {
        // The SPIR-V target type is a 32-bit int.  Keep only the bottom
        // 8 bits.
        // Before:
        //   %result = trunc i32 %a to i8
        // After
        //   %result = OpBitwiseAnd %uint %a %uint_255

        SPIRVOperandVec Ops;

        Ops << OpTy << I.getOperand(0) << getSPIRVInt32Constant(255);

        RID = addSPIRVInst(spv::OpBitwiseAnd, Ops);
      } else if (!clspv::Option::Int8Support() &&
                 I.getOpcode() == Instruction::BitCast &&
                 ((Ty->isIntOrIntVectorTy(8) && OpTy->isIntOrIntVectorTy(32)) ||
                  (Ty->isIntOrIntVectorTy(32) &&
                   OpTy->isIntOrIntVectorTy(8)))) {
        // Without int8 support, <4 x i8> is represented as i32.
        // The only valid bitcast involving i8 and i32 is <4 x i8> <--> i32
        // because Vulkan's max vector size is 4 and the total bitwidth must
        // match.
        RID = getSPIRVValue(I.getOperand(0));
      } else if (Ty->isIntOrIntVectorTy(1) &&
                 I.getOpcode() == Instruction::Trunc) {
        // We usually map trunc to OpUConvert.
        // But OpUConvert only takes integer types in input, not boolean type.
        // Instead use OpINotEqual.
        SPIRVOperandVec Ops;
        Ops << Ty << I.getOperand(0)
            << getSPIRVValue(ConstantInt::get(OpTy, 0));
        RID = addSPIRVInst(spv::OpINotEqual, Ops);
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Source Value ID
        SPIRVOperandVec Ops;

        if (I.getOpcode() == Instruction::IntToPtr) {
          auto *inferred_ty =
              clspv::InferType(&I, module->getContext(), &InferredTypeCache);
          assert(inferred_ty);
          Ops << getSPIRVPointerType(I.getType(), inferred_ty);
        } else {
          Ops << I.getType();
        }
        Ops << I.getOperand(0);

        auto Op = GetSPIRVCastOpcode(I);
        RID = addSPIRVInst(Op, Ops);

        if (Op == spv::OpConvertSToF || Op == spv::OpConvertUToF ||
            Op == spv::OpFConvert) {
          // signal that we might want to the set the execution mode
          setConvertToF();
        }

        if (clspv::Option::HackConvertToFloat() &&
            (Op == spv::OpConvertSToF || Op == spv::OpConvertUToF)) {
          Ops.clear();
          Ops << I.getType() << RID
              << getSPIRVConstant(Constant::getNullValue(I.getType()));
          RID = addSPIRVInst(spv::OpFAdd, Ops);
        }
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
        SPIRVOperandVec Ops;

        Ops << I.getType();

        Value *CondV = I.getOperand(0);
        if (isa<Constant>(I.getOperand(0))) {
          CondV = I.getOperand(1);
        }
        Ops << CondV;

        RID = addSPIRVInst(spv::OpLogicalNot, Ops);
      } else if (I.getOpcode() == Instruction::SRem) {
        // We cannot map SRem to OpSRem because:
        // For the OpSRem and OpSMod instructions, if either operand is negative
        // the result is undefined.
        // https://www.khronos.org/registry/vulkan/specs/1.3-extensions/html/chap46.html#spirvenv-precision-operation
        //
        // Let's implement signed modulus like that:
        // SRem(x, y) {
        //   rem = (abs(x) % abs(y))
        //   return (x > 0 ? rem : ((rem ^ -1) + 1)); // (x > 0 ? rem : rem *
        //   -1);
        // }

        SPIRVOperandVec Ops;
        Type *Ty = I.getType();
        Type *boolTy = Ty->getInt1Ty(Ty->getContext());
        if (Ty->isVectorTy()) {
          boolTy = VectorType::get(boolTy, dyn_cast<VectorType>(Ty));
        }

        auto Cst0 = ConstantInt::get(Ty, 0, true);
        auto Cst1 = ConstantInt::get(Ty, 1, true);
        auto Cstm1 = ConstantInt::get(Ty, -1, true);
        auto X = I.getOperand(0);
        auto Y = I.getOperand(1);

        // abs(x)
        Ops << Ty << getOpExtInstImportID() << glsl::ExtInst::ExtInstSAbs << X;
        auto AbsX = addSPIRVInst(spv::OpExtInst, Ops);

        // abs(y)
        Ops.clear();
        Ops << Ty << getOpExtInstImportID() << glsl::ExtInst::ExtInstSAbs << Y;
        auto AbsY = addSPIRVInst(spv::OpExtInst, Ops);

        // abs(x) % abs(y)
        Ops.clear();
        Ops << Ty << AbsX << AbsY;
        auto Mod = addSPIRVInst(spv::OpUMod, Ops);

        // x > 0
        Ops.clear();
        Ops << boolTy << X << Cst0;
        auto Cmp = addSPIRVInst(spv::OpSGreaterThan, Ops);

        Ops.clear();
        Ops << Ty << Mod << Cstm1;
        auto Xor = addSPIRVInst(spv::OpBitwiseXor, Ops);

        Ops.clear();
        Ops << Ty << Xor << Cst1;
        auto Modm1 = addSPIRVInst(spv::OpIAdd, Ops);

        Ops.clear();
        Ops << Ty << Cmp << Mod << Modm1;
        RID = addSPIRVInst(spv::OpSelect, Ops);
      } else if (I.getOpcode() == Instruction::FDiv && !Option::UnsafeMath() &&
                 I.getType()->getScalarType()->isFloatTy()) {
        // float div(float a, float b) {
        //   if (abs(b) > 0x1.0p+126f) {
        //     c = 0x1.0p-4f;
        //   } else if (abs(b) < 0x1.0p-126f) {
        //     c = 0x1.0p+24f;
        //   } else {
        //     c = 1.0;
        //   }
        //   return (a / (b * c)) * c;
        // }
        Type *FPTy = I.getType();
        auto a = getSPIRVValue(I.getOperand(0));
        auto b = getSPIRVValue(I.getOperand(1));
        bool is_vector = FPTy->isVectorTy();
        SPIRVOperandVec Ops;
        SPIRVID Ty = getSPIRVType(FPTy);

        const float fmax_val = 0x1.0p+126f;
        const float fmin_val = 0x1.0p-126f;
        const float c_max_val = 0x1.0p-4f;
        const float c_min_val = 0x1.0p+24f;
        SPIRVID divisor, c;

        // Try to optimize it if b is constant.
        if (auto b_cst = dyn_cast<Constant>(I.getOperand(1))) {
          SmallVector<Constant *, 2> csts;
          if (is_vector) {
            for (unsigned i = 0;
                 i < cast<FixedVectorType>(FPTy)->getNumElements(); i++) {
              csts.push_back(b_cst->getAggregateElement(i));
            }
          } else {
            csts.push_back(b_cst);
          }

          SmallVector<Constant *, 2> divisor_vec;
          SmallVector<Constant *, 2> c_vec;
          Type *ScalarTy = FPTy->getScalarType();
          bool c_vec_needed = false;
          bool vector_cst = true;
          for (auto b_elem : csts) {
            float b_elem_val = 1.0f;
            if (auto b_elem_cst_fp = dyn_cast<ConstantFP>(b_elem)) {
              b_elem_val = b_elem_cst_fp->getValue().convertToFloat();
            } else if (!isa<PoisonValue>(b_elem)) {
              vector_cst = false;
              break;
            }
            if (b_elem_val > fmax_val) {
              divisor_vec.push_back(
                  ConstantFP::get(ScalarTy, b_elem_val * c_max_val));
              c_vec.push_back(ConstantFP::get(ScalarTy, c_max_val));
              c_vec_needed = true;
            } else if (b_elem_val < fmin_val) {
              divisor_vec.push_back(
                  ConstantFP::get(ScalarTy, b_elem_val * c_min_val));
              c_vec.push_back(ConstantFP::get(ScalarTy, c_min_val));
              c_vec_needed = true;
            } else {
              divisor_vec.push_back(ConstantFP::get(ScalarTy, b_elem_val));
              c_vec.push_back(ConstantFP::get(ScalarTy, 1.0));
            }
          }
          if (vector_cst && c_vec_needed) {
            if (is_vector) {
              divisor = getSPIRVConstant(ConstantVector::get(divisor_vec));
              c = getSPIRVConstant(ConstantVector::get(c_vec));
            } else {
              divisor = getSPIRVConstant(divisor_vec[0]);
              c = getSPIRVConstant(c_vec[0]);
            }
          } else if (vector_cst) {
            divisor = getSPIRVConstant(b_cst);
          }
        }

        if (!divisor.isValid()) {
          Type *boolTy = IntegerType::get(module->getContext(), 1);
          if (is_vector) {
            boolTy = VectorType::get(boolTy, dyn_cast<VectorType>(FPTy));
          }
          SPIRVID c_max = getSPIRVConstant(ConstantFP::get(FPTy, c_max_val));
          SPIRVID c_min = getSPIRVConstant(ConstantFP::get(FPTy, c_min_val));
          SPIRVID max = getSPIRVConstant(ConstantFP::get(FPTy, fmax_val));
          SPIRVID min = getSPIRVConstant(ConstantFP::get(FPTy, fmin_val));
          SPIRVID c_one = getSPIRVConstant(ConstantFP::get(FPTy, 1.0));

          Ops.clear();
          Ops << Ty << getOpExtInstImportID() << glsl::ExtInst::ExtInstFAbs
              << b;
          SPIRVID abs_b = addSPIRVInst(spv::OpExtInst, Ops);

          Ops.clear();
          Ops << getSPIRVType(boolTy) << abs_b << max;
          SPIRVID cond_max = addSPIRVInst(spv::OpFOrdGreaterThan, Ops);
          Ops.clear();
          Ops << getSPIRVType(boolTy) << abs_b << min;
          SPIRVID cond_min = addSPIRVInst(spv::OpFOrdLessThan, Ops);

          Ops.clear();
          Ops << Ty << cond_max << c_max << c_one;
          c = addSPIRVInst(spv::OpSelect, Ops);
          Ops.clear();
          Ops << Ty << cond_min << c_min << c;
          c = addSPIRVInst(spv::OpSelect, Ops);

          Ops.clear();
          Ops << Ty << b << c;
          divisor = addSPIRVInst(spv::OpFMul, Ops);
        }

        Ops.clear();
        Ops << Ty << a << divisor;
        RID = addSPIRVInst(spv::OpFDiv, Ops);

        if (c.isValid()) {
          Ops.clear();
          Ops << Ty << RID << c;
          RID = addSPIRVInst(spv::OpFMul, Ops);
        }
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Operand 0
        // Ops[2] = Operand 1
        SPIRVOperandVec Ops;

        Ops << I.getType() << I.getOperand(0) << I.getOperand(1);

        auto opcode = GetSPIRVBinaryOpcode(I);
        RID = addSPIRVInst(opcode, Ops);
      }
    } else if (I.getOpcode() == Instruction::FNeg) {
      // The only unary operator.
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Operand 0
      SPIRVOperandVec Ops;

      Ops << I.getType() << I.getOperand(0);
      RID = addSPIRVInst(spv::OpFNegate, Ops);
    } else if (I.getOpcode() == Instruction::Unreachable) {
      RID = addSPIRVInst(spv::OpUnreachable);
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
    SPIRVOperandVec Ops;

    PointerType *ResultType = cast<PointerType>(GEP->getType());
    if (GEP->getPointerAddressSpace() == AddressSpace::ModuleScopePrivate ||
        GlobalConstArgSet.count(GEP->getPointerOperand())) {
      // Use pointer type with private address space for global constant.
      ResultType = PointerType::getWithSamePointeeType(
          ResultType, AddressSpace::ModuleScopePrivate);
    }

    Ops << getSPIRVPointerType(ResultType, GEP->getResultElementType());

    // Generate the base pointer.
    Ops << GEP->getPointerOperand();

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
      // Shader validation in the SPIR-V spec requires that the base pointer to
      // OpPtrAccessChain (in StorageBuffer storage class) be decorated with
      // ArrayStride.
      auto address_space = ResultType->getAddressSpace();
      setVariablePointersCapabilities(address_space);
      switch (GetStorageClass(address_space)) {
      case spv::StorageClassStorageBuffer:
      case spv::StorageClassPhysicalStorageBuffer:
        // Save the type to generate an ArrayStride decoration later, but
        // assume opaque pointers may be present so also cache the SPIRVID for
        // the type and the stride value.
        getTypesNeedingArrayStride().insert(StrideType(
            static_cast<uint32_t>(GetTypeAllocSize(GEP->getSourceElementType(),
                                                   module->getDataLayout())),
            getSPIRVPointerType(GEP->getPointerOperand()->getType(),
                                GEP->getSourceElementType())));
        break;
      case spv::StorageClassWorkgroup:
        break;
      default:
        llvm_unreachable(
            "OpPtrAccessChain is not supported for this storage class");
        break;
      }
    }

    for (auto II = GEP->idx_begin() + offset; II != GEP->idx_end(); II++) {
      Ops << *II;
    }

    RID = addSPIRVInst(Opcode, Ops);
    break;
  }
  case Instruction::ExtractValue: {
    ExtractValueInst *EVI = cast<ExtractValueInst>(&I);
    // Ops[0] = Result Type ID
    // Ops[1] = Composite ID
    // Ops[2] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandVec Ops;

    Ops << I.getType();

    Ops << EVI->getAggregateOperand();

    for (auto &Index : EVI->indices()) {
      Ops << Index;
    }

    RID = addSPIRVInst(spv::OpCompositeExtract, Ops);
    break;
  }
  case Instruction::InsertValue: {
    InsertValueInst *IVI = cast<InsertValueInst>(&I);
    // Ops[0] = Result Type ID
    // Ops[1] = Object ID
    // Ops[2] = Composite ID
    // Ops[3] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandVec Ops;

    Ops << I.getType() << IVI->getInsertedValueOperand()
        << IVI->getAggregateOperand();

    for (auto &Index : IVI->indices()) {
      Ops << Index;
    }

    RID = addSPIRVInst(spv::OpCompositeInsert, Ops);
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
    SPIRVOperandVec Ops;

    // Find SPIRV instruction for parameter type.
    auto Ty = I.getType();
    if (Ty->isPointerTy()) {
      // Selecting between pointers requires variable pointers.
      setVariablePointersCapabilities(Ty->getPointerAddressSpace());
      if (!hasVariablePointers() && !selectFromSameObject(&I)) {
        setVariablePointers();
      }
    }

    SPIRVID type_id;
    if (Ty->isPointerTy()) {
      auto *inferred_ty =
          InferType(&I, module->getContext(), &InferredTypeCache);
      type_id = getSPIRVPointerType(Ty, inferred_ty);
    } else {
      type_id = getSPIRVType(Ty);
    }

    Ops << type_id << I.getOperand(0) << I.getOperand(1) << I.getOperand(2);

    RID = addSPIRVInst(spv::OpSelect, Ops);
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
      SPIRVOperandVec Ops;

      Ops << CompositeTy << I.getOperand(0);

      SPIRVID Op1ID = 0;
      if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1))) {
        // Handle constant index.
        uint32_t Idx = static_cast<uint32_t>(CI->getZExtValue());
        Op1ID = getSPIRVInt32Constant(Idx * 8);
      } else {
        // Handle variable index.
        SPIRVOperandVec TmpOps;

        TmpOps << Type::getInt32Ty(Context) << I.getOperand(1)
               << getSPIRVInt32Constant(8);

        Op1ID = addSPIRVInst(spv::OpIMul, TmpOps);
      }
      Ops << Op1ID;

      SPIRVID ShiftID = addSPIRVInst(spv::OpShiftRightLogical, Ops);

      //
      // Generate OpBitwiseAnd
      //
      // Ops[0] = Result Type ID
      // Ops[1] = Operand 0
      // Ops[2] = Operand 1
      //
      Ops.clear();

      Ops << CompositeTy << ShiftID << getSPIRVInt32Constant(0xFF);

      RID = addSPIRVInst(spv::OpBitwiseAnd, Ops);
      break;
    }

    // Ops[0] = Result Type ID
    // Ops[1] = Composite ID
    // Ops[2] ... Ops[n] = Indexes (Literal Number)
    SPIRVOperandVec Ops;

    Ops << I.getType() << I.getOperand(0);

    spv::Op Opcode = spv::OpCompositeExtract;
    if (const ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(1))) {
      Ops << static_cast<uint32_t>(CI->getZExtValue());
    } else {
      Ops << I.getOperand(1);
      Opcode = spv::OpVectorExtractDynamic;
    }

    RID = addSPIRVInst(Opcode, Ops);
    break;
  }
  case Instruction::InsertElement: {
    // Handle <4 x i8> type manually.
    Type *CompositeTy = I.getOperand(0)->getType();
    if (is4xi8vec(CompositeTy)) {
      SPIRVID CstFFID = getSPIRVInt32Constant(0xFF);

      SPIRVID ShiftAmountID = 0;
      if (ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2))) {
        // Handle constant index.
        uint32_t Idx = static_cast<uint32_t>(CI->getZExtValue());
        ShiftAmountID = getSPIRVInt32Constant(Idx * 8);
      } else {
        // Handle variable index.
        SPIRVOperandVec TmpOps;

        TmpOps << Type::getInt32Ty(Context) << I.getOperand(2)
               << getSPIRVInt32Constant(8);

        ShiftAmountID = addSPIRVInst(spv::OpIMul, TmpOps);
      }

      //
      // Generate mask operations.
      //

      // ShiftLeft mask according to index of insertelement.
      SPIRVOperandVec Ops;

      Ops << CompositeTy << CstFFID << ShiftAmountID;

      SPIRVID MaskID = addSPIRVInst(spv::OpShiftLeftLogical, Ops);

      // Inverse mask.
      Ops.clear();
      Ops << CompositeTy << MaskID;

      SPIRVID InvMaskID = addSPIRVInst(spv::OpNot, Ops);

      // Apply mask.
      Ops.clear();
      Ops << CompositeTy << I.getOperand(0) << InvMaskID;

      SPIRVID OrgValID = addSPIRVInst(spv::OpBitwiseAnd, Ops);

      // Create correct value according to index of insertelement.
      Ops.clear();
      Ops << CompositeTy << I.getOperand(1) << ShiftAmountID;

      SPIRVID InsertValID = addSPIRVInst(spv::OpShiftLeftLogical, Ops);

      // Insert value to original value.
      Ops.clear();
      Ops << CompositeTy << OrgValID << InsertValID;

      RID = addSPIRVInst(spv::OpBitwiseOr, Ops);
      break;
    }

    SPIRVOperandVec Ops;

    // Ops[0] = Result Type ID
    Ops << I.getType();

    spv::Op Opcode = spv::OpCompositeInsert;
    if (const ConstantInt *CI = dyn_cast<ConstantInt>(I.getOperand(2))) {
      const auto value = CI->getZExtValue();
      assert(value <= UINT32_MAX);
      // Ops[1] = Object ID
      // Ops[2] = Composite ID
      // Ops[3] ... Ops[n] = Indexes (Literal Number)
      Ops << I.getOperand(1) << I.getOperand(0) << static_cast<uint32_t>(value);
    } else {
      // Ops[1] = Composite ID
      // Ops[2] = Object ID
      // Ops[3] ... Ops[n] = Indexes (Literal Number)
      Ops << I.getOperand(0) << I.getOperand(1) << I.getOperand(2);
      Opcode = spv::OpVectorInsertDynamic;
    }

    RID = addSPIRVInst(Opcode, Ops);
    break;
  }
  case Instruction::ShuffleVector: {
    // Ops[0] = Result Type ID
    // Ops[1] = Vector 1 ID
    // Ops[2] = Vector 2 ID
    // Ops[3] ... Ops[n] = Components (Literal Number)
    SPIRVOperandVec Ops;

    if (!clspv::Option::Int8Support() && I.getType()->isIntOrIntVectorTy(8)) {
      // <4 x i8> is translated as i32. So shufflevector on <4 x i8> must be
      // implemented as bit operations.
      // This could be optimized, but it is a legacy support case.
      auto int32_ty = Type::getInt32Ty(module->getContext());
      auto tmp = getSPIRVConstant(Constant::getNullValue(int32_ty));
      const auto shuffle = dyn_cast<ShuffleVectorInst>(&I);
      uint32_t i = 0;
      for (auto mask : shuffle->getShuffleMask()) {
        auto op0 = I.getOperand(0);
        auto op1 = I.getOperand(1);
        auto vec_ty = dyn_cast<VectorType>(op0->getType());
        auto num_eles = vec_ty->getElementCount().getFixedValue();
        bool use_op0 = mask < (int)num_eles;
        auto op = use_op0 ? op0 : op1;
        auto mask_byte = mask % num_eles;
        if (!isa<UndefValue>(op) && !isa<PoisonValue>(op)) {
          Ops.clear();

          // This element goes in the |i|'th byte using the |mask_byte| byte of
          // |op|.
          const uint32_t bitmask = 0xff << (mask_byte * 8);
          auto bitmask_const =
              getSPIRVConstant(ConstantInt::get(int32_ty, bitmask));
          Ops << op->getType() << op << bitmask_const;
          auto and_mask = addSPIRVInst(spv::OpBitwiseAnd, Ops);
          Ops.clear();

          const int32_t shift_amount = i * 8 - mask_byte * 8;
          const bool shl = shift_amount > 0;
          if (shift_amount != 0) {
            Ops << op->getType() << and_mask
                << getSPIRVConstant(ConstantInt::get(int32_ty, shift_amount));
            and_mask = addSPIRVInst(
                shl ? spv::OpShiftLeftLogical : spv::OpShiftRightLogical, Ops);
            Ops.clear();
          }

          Ops << I.getType() << tmp << and_mask;
          tmp = addSPIRVInst(spv::OpBitwiseOr, Ops);
        }
        ++i;
      }
      RID = tmp;
    } else {
      Ops << I.getType() << I.getOperand(0) << I.getOperand(1);

      auto shuffle = cast<ShuffleVectorInst>(&I);
      SmallVector<int, 4> mask;
      shuffle->getShuffleMask(mask);
      for (auto i : mask) {
        if (i == PoisonMaskElem) {
          if (clspv::Option::HackUndef())
            // Use 0 instead of undef.
            Ops << 0;
          else
            // Undef for shuffle in SPIR-V.
            Ops << 0xffffffff;
        } else {
          Ops << i;
        }
      }

      RID = addSPIRVInst(spv::OpVectorShuffle, Ops);
    }
    break;
  }
  case Instruction::ICmp:
  case Instruction::FCmp: {
    CmpInst *CmpI = cast<CmpInst>(&I);

    // Pointer comparisons are only supported from SPIR-V 1.4 onwards.
    Type *ArgTy = CmpI->getOperand(0)->getType();
    if (isa<PointerType>(ArgTy)) {
      if (SpvVersion() >= SPIRVVersion::SPIRV_1_4) {
        SPIRVOperandVec Ops;
        auto *lhs = CmpI->getOperand(0);
        auto *rhs = CmpI->getOperand(1);
        auto *lhs_ty = clspv::InferType(lhs, Context, &InferredTypeCache);
        auto *rhs_ty = clspv::InferType(rhs, Context, &InferredTypeCache);
        SPIRVID cmp_lhs, cmp_rhs;
        // Need a better way to handle pointer constants
        if (!lhs_ty && !rhs_ty) {
          llvm_unreachable("neither pointer type can be inferred");
        }
        if (lhs_ty && isa<ConstantPointerNull>(rhs)) {
          cmp_lhs = getSPIRVValue(lhs);
          auto type_id = getSPIRVPointerType(lhs->getType(), lhs_ty);
          Ops.clear();
          Ops << type_id;
          cmp_rhs = addSPIRVInst<kConstants>(spv::Op::OpConstantNull, Ops);
        } else if (rhs_ty && isa<ConstantPointerNull>(rhs)) {
          cmp_rhs = getSPIRVValue(rhs);
          auto type_id = getSPIRVPointerType(rhs->getType(), rhs_ty);
          Ops.clear();
          Ops << type_id;
          cmp_lhs = addSPIRVInst<kConstants>(spv::Op::OpConstantNull, Ops);
        } else {
          cmp_lhs = getSPIRVValue(lhs);
          cmp_rhs = getSPIRVValue(rhs);
        }
        spv::Op Opcode;
        switch (CmpI->getPredicate()) {
        case CmpInst::ICMP_NE:
          Opcode = spv::OpPtrNotEqual;
          break;
        case CmpInst::ICMP_EQ:
          Opcode = spv::OpPtrEqual;
          break;
        case CmpInst::ICMP_UGT:
        case CmpInst::ICMP_UGE:
        case CmpInst::ICMP_ULT:
        case CmpInst::ICMP_ULE:
          Opcode = GetSPIRVPointerCmpOpcode(CmpI);
          Ops.clear();
          Ops << getSPIRVType(Type::getInt32Ty(Context)) << cmp_lhs << cmp_rhs;
          RID = addSPIRVInst(spv::OpPtrDiff, Ops);
          cmp_lhs = RID;
          cmp_rhs = getSPIRVInt32Constant(0);
          break;
        default:
          llvm_unreachable("Unexpected signed pointer comparison");
          break;
        }

        Ops.clear();
        Ops << CmpI->getType() << cmp_lhs << cmp_rhs;
        RID = addSPIRVInst(Opcode, Ops);

        setVariablePointersCapabilities(ArgTy->getPointerAddressSpace());
      } else {
        CmpI->print(errs());
        std::string name = I.getParent()->getParent()->getName().str();
        errs() << "\nPointer comparisons not supported prior to SPIR-V 1.4, "
               << "in function " << name << "\n";
        llvm_unreachable("Pointer comparisons not supported");
      }
      break;
    }

    SPIRVOperandVec Ops;
    if (CmpI->getPredicate() == CmpInst::FCMP_ORD ||
        CmpI->getPredicate() == CmpInst::FCMP_UNO) {
      // Implement ordered and unordered comparisons are OpIsNan instructions.
      // Optimize the constants to simplify the resulting code.
      auto lhs = CmpI->getOperand(0);
      auto rhs = CmpI->getOperand(1);
      auto const_lhs = dyn_cast_or_null<Constant>(lhs);
      auto const_rhs = dyn_cast_or_null<Constant>(rhs);
      if ((const_lhs && const_lhs->isNaN()) ||
          (const_rhs && const_rhs->isNaN())) {
        // Result is a constant, false of ordered, true for unordered.
        if (CmpI->getPredicate() == CmpInst::FCMP_ORD) {
          RID = getSPIRVConstant(ConstantInt::getFalse(CmpI->getType()));
        } else {
          RID = getSPIRVConstant(ConstantInt::getTrue(CmpI->getType()));
        }
        break;
      }
      SPIRVID lhs_id;
      SPIRVID rhs_id;
      if (!const_lhs) {
        // Generate OpIsNan for the lhs.
        Ops.clear();
        Ops << CmpI->getType() << lhs;
        lhs_id = addSPIRVInst(spv::OpIsNan, Ops);
      }
      if (!const_rhs) {
        // Generate OpIsNan for the rhs.
        Ops.clear();
        Ops << CmpI->getType() << rhs;
        rhs_id = addSPIRVInst(spv::OpIsNan, Ops);
      }
      if (lhs_id.isValid() && rhs_id.isValid()) {
        // Or the results for the lhs and rhs.
        Ops.clear();
        Ops << CmpI->getType() << lhs_id << rhs_id;
        RID = addSPIRVInst(spv::OpLogicalOr, Ops);
      } else {
        RID = lhs_id.isValid() ? lhs_id : rhs_id;
      }
      if (CmpI->getPredicate() == CmpInst::FCMP_ORD) {
        // For ordered comparisons, invert the intermediate result.
        Ops.clear();
        Ops << CmpI->getType() << RID;
        RID = addSPIRVInst(spv::OpLogicalNot, Ops);
      }
      break;
    } else {
      // Remaining comparisons map directly to SPIR-V opcodes.
      // Ops[0] = Result Type ID
      // Ops[1] = Operand 1 ID
      // Ops[2] = Operand 2 ID
      Ops << CmpI->getType() << CmpI->getOperand(0) << CmpI->getOperand(1);

      spv::Op Opcode = GetSPIRVCmpOpcode(CmpI);
      RID = addSPIRVInst(Opcode, Ops);
    }
    break;
  }
  case Instruction::Br: {
    // Branch instruction is deferred because it needs label's ID.
    BasicBlock *BrBB = I.getParent();
    if (ContinueBlocks.count(BrBB) || MergeBlocks.count(BrBB)) {
      // Placeholder for Merge operation
      RID = addSPIRVPlaceholder(&I);
    }
    RID = addSPIRVPlaceholder(&I);
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
    // PHI instruction is deferred because it needs label's ID.
    RID = addSPIRVPlaceholder(&I);
    break;
  }
  case Instruction::Alloca: {
    //
    // Generate OpVariable.
    //
    // Ops[0] : Result Type ID
    // Ops[1] : Storage Class
    SPIRVOperandVec Ops;

    Ops << getSPIRVPointerType(I.getType(),
                               cast<AllocaInst>(&I)->getAllocatedType())
        << spv::StorageClassFunction;

    RID = addSPIRVInst(spv::OpVariable, Ops);
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

    SPIRVID PointerID = getSPIRVValue(LD->getPointerOperand());
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

      SPIRVOperandVec Ops;
      Ops << LD->getType() << WorkgroupSizeValueID << WorkgroupSizeValueID;

      RID = addSPIRVInst(spv::OpBitwiseAnd, Ops);
      break;
    }

    // This is the normal path.  Generate a load.

    // Ops[0] = Result Type ID
    // Ops[1] = Pointer ID
    // Ops[2] ... Ops[n] = Optional Memory Access
    //
    // TODO: Do we need to implement Optional Memory Access???

    auto ptr = LD->getPointerOperand();
    auto ptr_ty = ptr->getType();
    SPIRVID result_type_id;
    if (LD->getType()->isPointerTy()) {
      result_type_id = getSPIRVType(LD->getType());
    } else {
      auto layout = PointerRequiresLayout(ptr_ty->getPointerAddressSpace());
      result_type_id = getSPIRVType(LD->getType(), layout);
    }
    SPIRVOperandVec Ops;
    Ops << result_type_id << ptr;

    // Align MemoryOperand is required for PhysicalStorageBuffer
    if (clspv::Option::PhysicalStorageBuffers()) {
      Ops << spv::MemoryAccessAlignedMask;
      Ops << static_cast<uint32_t>(LD->getAlign().value());
    }

    RID = addSPIRVInst(spv::OpLoad, Ops);

    auto no_layout_id = getSPIRVType(LD->getType());
    if (Option::SpvVersion() >= SPIRVVersion::SPIRV_1_4 &&
        no_layout_id.get() != result_type_id.get()) {
      // Generate an OpCopyLogical to convert from the laid out type to a
      // non-laid out type.
      Ops.clear();
      Ops << no_layout_id << RID;
      RID = addSPIRVInst(spv::OpCopyLogical, Ops);
    }
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

    SPIRVOperandVec Ops;
    auto ptr = ST->getPointerOperand();
    auto ptr_ty = ptr->getType();
    auto value = ST->getValueOperand();
    auto value_ty = value->getType();
    auto needs_layout = PointerRequiresLayout(ptr_ty->getPointerAddressSpace());
    if (Option::SpvVersion() >= SPIRVVersion::SPIRV_1_4 && needs_layout &&
        (value_ty->isArrayTy() || value_ty->isStructTy())) {
      // Generate an OpCopyLogical to convert from the non-laid type to the
      // laid out type.
      Ops << getSPIRVType(value_ty, needs_layout) << value;
      RID = addSPIRVInst(spv::OpCopyLogical, Ops);
      Ops.clear();
    }

    // Ops[0] = Pointer ID
    // Ops[1] = Object ID
    // Ops[2] ... Ops[n] = Optional Memory Access (later???)
    //
    // TODO: Do we need to implement Optional Memory Access???
    Ops << ST->getPointerOperand();
    if (RID.isValid()) {
      Ops << RID;
    } else {
      Ops << ST->getValueOperand();
    }

    // Align MemoryOperand is required for PhysicalStorageBuffer
    if (clspv::Option::PhysicalStorageBuffers()) {
      Ops << spv::MemoryAccessAlignedMask;
      Ops << static_cast<uint32_t>(ST->getAlign().value());
    }

    RID = addSPIRVInst(spv::OpStore, Ops);
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
    SPIRVOperandVec Ops;

    Ops << I.getType() << AtomicRMW->getPointerOperand();

    const auto ConstantScopeDevice = getSPIRVInt32Constant(spv::ScopeDevice);
    Ops << ConstantScopeDevice;

    const auto ConstantMemorySemantics =
        getSPIRVInt32Constant(spv::MemorySemanticsUniformMemoryMask |
                              spv::MemorySemanticsSequentiallyConsistentMask);
    Ops << ConstantMemorySemantics << AtomicRMW->getValOperand();

    RID = addSPIRVInst(opcode, Ops);
    break;
  }
  case Instruction::Fence: {
    I.print(errs());
    llvm_unreachable("Unsupported instruction???");
    break;
  }
  case Instruction::Call: {
    CallInst *Call = dyn_cast<CallInst>(&I);
    RID = GenerateInstructionFromCall(Call);
    break;
  }
  case Instruction::Ret: {
    unsigned NumOps = I.getNumOperands();
    if (NumOps == 0) {
      //
      // Generate OpReturn.
      //
      RID = addSPIRVInst(spv::OpReturn);
    } else {
      //
      // Generate OpReturnValue.
      //

      // Ops[0] = Return Value ID
      SPIRVOperandVec Ops;

      Ops << I.getOperand(0);

      RID = addSPIRVInst(spv::OpReturnValue, Ops);
      break;
    }
    break;
  }
  }

  // Register Instruction to ValueMap.
  if (RID.isValid()) {
    VMap[&I] = RID;
  }
}

void SPIRVProducerPassImpl::GenerateFuncEpilogue() {
  //
  // Generate OpFunctionEnd
  //
  addSPIRVInst(spv::OpFunctionEnd);
}

bool SPIRVProducerPassImpl::is4xi8vec(Type *Ty) const {
  // Don't specialize <4 x i8> if i8 is generally supported.
  if (clspv::Option::Int8Support())
    return false;

  LLVMContext &Context = Ty->getContext();
  if (auto VecTy = dyn_cast<VectorType>(Ty)) {
    if (VecTy->getElementType() == Type::getInt8Ty(Context) &&
        VecTy->getElementCount().getKnownMinValue() == 4) {
      return true;
    }
  }

  return false;
}

void SPIRVProducerPassImpl::HandleDeferredInstruction() {
  DeferredInstVecType &DeferredInsts = getDeferredInstVec();

  for (size_t i = 0; i < DeferredInsts.size(); ++i) {
    Value *Inst = DeferredInsts[i].first;
    SPIRVInstruction *Placeholder = DeferredInsts[i].second;
    SPIRVOperandVec Operands;

    auto nextDeferred = [&i, &Inst, &DeferredInsts, &Placeholder]() {
      ++i;
      assert(DeferredInsts.size() > i);
      assert(Inst == DeferredInsts[i].first);
      Placeholder = DeferredInsts[i].second;
    };

    if (BranchInst *Br = dyn_cast<BranchInst>(Inst)) {
      // Check whether this branch needs to be preceeded by merge instruction.
      BasicBlock *BrBB = Br->getParent();
      if (ContinueBlocks.count(BrBB)) {
        //
        // Generate OpLoopMerge.
        //
        // Ops[0] = Merge Block ID
        // Ops[1] = Continue Target ID
        // Ops[2] = Selection Control
        SPIRVOperandVec Ops;

        Ops << MergeBlocks[BrBB] << ContinueBlocks[BrBB]
            << spv::LoopControlMaskNone;

        replaceSPIRVInst(Placeholder, spv::OpLoopMerge, Ops);

        nextDeferred();

      } else if (MergeBlocks.count(BrBB)) {
        //
        // Generate OpSelectionMerge.
        //
        // Ops[0] = Merge Block ID
        // Ops[1] = Selection Control
        SPIRVOperandVec Ops;

        auto MergeBB = MergeBlocks[BrBB];
        Ops << MergeBB << spv::SelectionControlMaskNone;

        replaceSPIRVInst(Placeholder, spv::OpSelectionMerge, Ops);

        nextDeferred();
      }

      if (Br->isConditional()) {
        //
        // Generate OpBranchConditional.
        //
        // Ops[0] = Condition ID
        // Ops[1] = True Label ID
        // Ops[2] = False Label ID
        // Ops[3] ... Ops[n] = Branch weights (Literal Number)
        SPIRVOperandVec Ops;

        Ops << Br->getCondition() << Br->getSuccessor(0) << Br->getSuccessor(1);

        replaceSPIRVInst(Placeholder, spv::OpBranchConditional, Ops);

      } else {
        //
        // Generate OpBranch.
        //
        // Ops[0] = Target Label ID
        SPIRVOperandVec Ops;

        Ops << Br->getSuccessor(0);

        replaceSPIRVInst(Placeholder, spv::OpBranch, Ops);
      }
    } else if (PHINode *PHI = dyn_cast<PHINode>(Inst)) {
      if (PHI->getType()->isPointerTy()) {
        // OpPhi on pointers requires variable pointers.
        setVariablePointersCapabilities(
            PHI->getType()->getPointerAddressSpace());
        if (!hasVariablePointers() && !selectFromSameObject(PHI)) {
          setVariablePointers();
        }
      }

      //
      // Generate OpPhi.
      //
      // Ops[0] = Result Type ID
      // Ops[1] ... Ops[n] = (Variable ID, Parent ID) pairs
      SPIRVOperandVec Ops;

      if (PHI->getType()->isPointerTy()) {
        auto *inferred_ty =
            InferType(PHI, module->getContext(), &InferredTypeCache);
        Ops << getSPIRVPointerType(PHI->getType(), inferred_ty);
      } else {
        Ops << PHI->getType();
      }

      for (unsigned j = 0; j < PHI->getNumIncomingValues(); j++) {
        Ops << PHI->getIncomingValue(j) << PHI->getIncomingBlock(j);
      }

      replaceSPIRVInst(Placeholder, spv::OpPhi, Ops);

    } else if (CallInst *Call = dyn_cast<CallInst>(Inst)) {
      Function *Callee = Call->getCalledFunction();
      auto callee_name = Callee->getName();

      if (Builtins::Lookup(Callee) == Builtins::kClspvCompositeConstruct) {
        // Generate an OpCompositeConstruct
        SPIRVOperandVec Ops;

        // The result type.
        Ops << Call->getType();

        for (Use &use : Call->args()) {
          Ops << use.get();
        }

        replaceSPIRVInst(Placeholder, spv::OpCompositeConstruct, Ops);

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
        SPIRVOperandVec Ops;

        SPIRVID type_id;
        if (Call->getType()->isPointerTy()) {
          auto *inferred_ty =
              InferType(Call, module->getContext(), &InferredTypeCache);
          type_id = getSPIRVPointerType(Call->getType(), inferred_ty);
        } else {
          type_id = getSPIRVType(Call->getType());
        }
        Ops << type_id;

        SPIRVID CalleeID = getSPIRVValue(Callee);
        if (!CalleeID.isValid()) {
          errs() << "Can't translate function call.  Missing builtin? "
                 << callee_name << " in: " << *Call << "\n";
          // TODO(dneto): Can we error out?  Enabling this llvm_unreachable
          // causes an infinite loop.  Instead, go ahead and generate
          // the bad function call.  A validator will catch the 0-Id.
          // llvm_unreachable("Can't translate function call");
        }

        Ops << CalleeID;

        FunctionType *CalleeFTy = cast<FunctionType>(Call->getFunctionType());
        for (unsigned j = 0; j < CalleeFTy->getNumParams(); j++) {
          auto *operand = Call->getOperand(j);
          auto *operand_type = operand->getType();
          auto *inferred_ty =
              InferType(operand, module->getContext(), &InferredTypeCache);
          StructType *struct_ty = dyn_cast_or_null<StructType>(inferred_ty);
          // Images and samplers can be passed as function parameters without
          // variable pointers.
          if (operand_type->isPointerTy() && !IsImageType(struct_ty) &&
              !IsSamplerType(struct_ty)) {
            auto sc =
                GetStorageClass(operand->getType()->getPointerAddressSpace());
            if (sc == spv::StorageClassStorageBuffer) {
              // Passing SSBO by reference requires variable pointers storage
              // buffer.
              setVariablePointersStorageBuffer();
            } else if (sc == spv::StorageClassWorkgroup) {
              // Workgroup references require variable pointers if they are not
              // memory object declarations.
              if (auto *operand_call = dyn_cast<CallInst>(operand)) {
                // Workgroup accessor represents a variable reference.
                if (Builtins::Lookup(operand_call->getCalledFunction()) !=
                    Builtins::kClspvLocal)
                  setVariablePointers();
              } else {
                // Arguments are function parameters.
                if (!isa<Argument>(operand))
                  setVariablePointers();
              }
            }
          }
          Ops << operand;
        }

        replaceSPIRVInst(Placeholder, spv::OpFunctionCall, Ops);
      }
    }
  }
}

void SPIRVProducerPassImpl::HandleDeferredDecorations() {
  if (getTypesNeedingArrayStride().empty()) {
    return;
  }

  // Insert ArrayStride decorations on pointer types, due to OpPtrAccessChain
  // instructions we generated earlier.
  DenseSet<uint32_t> seen;
  for (auto stride_type : getTypesNeedingArrayStride()) {
    auto stride = stride_type.stride;
    auto id = stride_type.id;
    assert(id.isValid() && stride != 0);
    if (!seen.insert(id.get()).second)
      continue;

    // Ops[0] = Target ID
    // Ops[1] = Decoration (ArrayStride)
    // Ops[2] = Stride number (Literal Number)
    SPIRVOperandVec Ops;

    Ops << id << spv::DecorationArrayStride << stride;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }
}

void SPIRVProducerPassImpl::WriteOneWord(uint32_t Word) {
  binaryOut->write(reinterpret_cast<const char *>(&Word), sizeof(uint32_t));
}

void SPIRVProducerPassImpl::WriteResultID(const SPIRVInstruction &Inst) {
  WriteOneWord(Inst.getResultID().get());
}

void SPIRVProducerPassImpl::WriteWordCountAndOpcode(
    const SPIRVInstruction &Inst) {
  // High 16 bit : Word Count
  // Low 16 bit  : Opcode
  uint32_t Word = Inst.getOpcode();
  const uint32_t count = Inst.getWordCount();
  if (count > 65535) {
    errs() << "Word count limit of 65535 exceeded: " << count << "\n";
    llvm_unreachable("Word count too high");
  }
  Word |= Inst.getWordCount() << 16;
  WriteOneWord(Word);
}

void SPIRVProducerPassImpl::WriteOperand(const SPIRVOperand &Op) {
  SPIRVOperandType OpTy = Op.getType();
  switch (OpTy) {
  default: {
    llvm_unreachable("Unsupported SPIRV Operand Type???");
    break;
  }
  case SPIRVOperandType::NUMBERID: {
    WriteOneWord(Op.getNumID());
    break;
  }
  case SPIRVOperandType::LITERAL_STRING: {
    std::string Str = Op.getLiteralStr();
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
  case SPIRVOperandType::LITERAL_WORD: {
    WriteOneWord(Op.getLiteralNum()[0]);
    break;
  }
  case SPIRVOperandType::LITERAL_DWORD: {
    WriteOneWord(Op.getLiteralNum()[0]);
    WriteOneWord(Op.getLiteralNum()[1]);
    break;
  }
  }
}

void SPIRVProducerPassImpl::WriteSPIRVBinary() {
  for (int i = 0; i < kSectionCount; ++i) {
    WriteSPIRVBinary(SPIRVSections[i]);
  }
}

void SPIRVProducerPassImpl::WriteSPIRVBinary(
    SPIRVInstructionList &SPIRVInstList) {
  for (const auto &Inst : SPIRVInstList) {
    const auto &Ops = Inst.getOperands();
    spv::Op Opcode = static_cast<spv::Op>(Inst.getOpcode());

    switch (Opcode) {
    default: {
      errs() << "Unsupported SPIR-V instruction opcode " << int(Opcode) << "\n";
      llvm_unreachable("Unsupported SPIRV instruction");
      break;
    }
    case spv::OpName:
    case spv::OpLine:
    case spv::OpNoLine:
    case spv::OpUnreachable:
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
    case spv::OpCopyMemory:
    case spv::OpAtomicStore: {
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
    case spv::OpTypeFunction:
    case spv::OpString: {
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
    case spv::OpBitReverse:
    case spv::OpFNegate:
    case spv::OpIAdd:
    case spv::OpIAddCarry:
    case spv::OpFAdd:
    case spv::OpISub:
    case spv::OpISubBorrow:
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
    case spv::OpCopyLogical:
    case spv::OpCopyObject:
    case spv::OpVectorInsertDynamic:
    case spv::OpVectorShuffle:
    case spv::OpIEqual:
    case spv::OpINotEqual:
    case spv::OpPtrEqual:
    case spv::OpPtrNotEqual:
    case spv::OpPtrDiff:
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
    case spv::OpImageFetch:
    case spv::OpImageRead:
    case spv::OpImageSampleExplicitLod:
    case spv::OpImageQuerySize:
    case spv::OpImageQuerySizeLod:
    case spv::OpSelect:
    case spv::OpPhi:
    case spv::OpLoad:
    case spv::OpAtomicLoad:
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
    case spv::OpDot:
    case spv::OpGroupNonUniformAll:
    case spv::OpGroupNonUniformAny:
    case spv::OpGroupNonUniformBroadcast:
    case spv::OpGroupNonUniformIAdd:
    case spv::OpGroupNonUniformFAdd:
    case spv::OpGroupNonUniformSMin:
    case spv::OpGroupNonUniformUMin:
    case spv::OpGroupNonUniformFMin:
    case spv::OpGroupNonUniformSMax:
    case spv::OpGroupNonUniformUMax:
    case spv::OpGroupNonUniformFMax: {
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

bool SPIRVProducerPassImpl::IsTypeNullable(const Type *type) const {
  switch (type->getTypeID()) {
  case Type::HalfTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID:
  case Type::IntegerTyID:
  case Type::FixedVectorTyID:
    return true;
  case Type::PointerTyID: {
    // Samplers and images should not be nulled, but we lack that information
    // here. That said, an undef image/sampler is likely already problematic
    // (e.g. due to a phi).
    return true;
  }
  case Type::ArrayTyID:
    return IsTypeNullable(type->getArrayElementType());
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

void SPIRVProducerPassImpl::PopulateUBOTypeMaps() {
  if (auto *offsets_md =
          module->getNamedMetadata(clspv::RemappedTypeOffsetMetadataName())) {
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
          module->getNamedMetadata(clspv::RemappedTypeSizesMetadataName())) {
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

uint64_t SPIRVProducerPassImpl::GetTypeSizeInBits(Type *type,
                                                  const DataLayout &DL) {
  auto iter = RemappedUBOTypeSizes.find(type);
  if (iter != RemappedUBOTypeSizes.end()) {
    return std::get<0>(iter->second);
  }

  return DL.getTypeSizeInBits(type);
}

uint64_t SPIRVProducerPassImpl::GetTypeAllocSize(Type *type,
                                                 const DataLayout &DL) {
  auto iter = RemappedUBOTypeSizes.find(type);
  if (iter != RemappedUBOTypeSizes.end()) {
    return std::get<2>(iter->second);
  }

  return DL.getTypeAllocSize(type);
}

uint32_t SPIRVProducerPassImpl::GetExplicitLayoutStructMemberOffset(
    StructType *type, unsigned member, const DataLayout &DL) {
  const auto StructLayout = DL.getStructLayout(type);
  // Search for the correct offsets if this type was remapped.
  std::vector<uint32_t> *offsets = nullptr;
  auto iter = RemappedUBOTypeOffsets.find(type);
  if (iter != RemappedUBOTypeOffsets.end()) {
    offsets = &iter->second;
  }
  auto ByteOffset =
      static_cast<uint32_t>(StructLayout->getElementOffset(member));
  if (offsets) {
    ByteOffset = (*offsets)[member];
  }

  return ByteOffset;
}

void SPIRVProducerPassImpl::setVariablePointersCapabilities(
    unsigned address_space) {
  if (GetStorageClass(address_space) == spv::StorageClassStorageBuffer) {
    setVariablePointersStorageBuffer();
  } else {
    setVariablePointers();
  }
}

Value *SPIRVProducerPassImpl::GetBasePointer(Value *v) {
  if (auto *gep = dyn_cast<GetElementPtrInst>(v)) {
    return GetBasePointer(gep->getPointerOperand());
  }

  // Conservatively return |v|.
  return v;
}

bool SPIRVProducerPassImpl::sameResource(Value *lhs, Value *rhs) const {
  if (auto *lhs_call = dyn_cast<CallInst>(lhs)) {
    if (auto *rhs_call = dyn_cast<CallInst>(rhs)) {
      const auto &lhs_func_info =
          Builtins::Lookup(lhs_call->getCalledFunction());
      const auto &rhs_func_info =
          Builtins::Lookup(rhs_call->getCalledFunction());
      if (lhs_func_info.getType() == Builtins::kClspvResource &&
          rhs_func_info.getType() == Builtins::kClspvResource) {
        // For resource accessors, match descriptor set and binding.
        if (lhs_call->getOperand(ClspvOperand::kResourceDescriptorSet) ==
                rhs_call->getOperand(ClspvOperand::kResourceDescriptorSet) &&
            lhs_call->getOperand(ClspvOperand::kResourceBinding) ==
                rhs_call->getOperand(ClspvOperand::kResourceBinding))
          return true;
      } else if (lhs_func_info.getType() == Builtins::kClspvLocal &&
                 rhs_func_info.getType() == Builtins::kClspvLocal) {
        // For workgroup resources, match spec id.
        if (lhs_call->getOperand(ClspvOperand::kWorkgroupSpecId) ==
            rhs_call->getOperand(ClspvOperand::kWorkgroupSpecId))
          return true;
      }
    }
  }

  return false;
}

bool SPIRVProducerPassImpl::selectFromSameObject(Instruction *inst) {
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

bool SPIRVProducerPassImpl::isPointerUniform(Value *ptr) {
  if (!ptr->getType()->isPointerTy()) {
    return true;
  }
  if (GetStorageClass(ptr->getType()->getPointerAddressSpace()) !=
      spv::StorageClassStorageBuffer) {
    return true;
  }

  while (auto gep = dyn_cast<GetElementPtrInst>(ptr)) {
    ptr = gep->getPointerOperand();
  }

  if (NonUniformPointers.count(ptr) > 0) {
    return false;
  }

  bool uniformPointer = true;
  if (auto inst = dyn_cast<PHINode>(ptr)) {
    uniformPointer = selectFromSameObject(inst);
  } else if (auto inst = dyn_cast<SelectInst>(ptr)) {
    uniformPointer = selectFromSameObject(inst);
  }
  if (!uniformPointer) {
    NonUniformPointers.insert(ptr);
  }
  return uniformPointer;
}

bool SPIRVProducerPassImpl::CalledWithCoherentResource(Argument &Arg) {
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
        Builtins::Lookup(resource_call->getCalledFunction()).getType() ==
            Builtins::kClspvResource) {
      // If this is a resource accessor function, check if the coherent operand
      // is set.
      const auto coherent =
          unsigned(dyn_cast<ConstantInt>(resource_call->getArgOperand(
                                             ClspvOperand::kResourceCoherent))
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

void SPIRVProducerPassImpl::PopulateStructuredCFGMaps() {
  // First, track loop merges and continues.
  DenseSet<BasicBlock *> LoopMergesAndContinues;
  for (auto &F : *module) {
    if (F.isDeclaration())
      continue;

    auto &FAM = MAM->getResult<FunctionAnalysisManagerModuleProxy>(*module)
                    .getManager();
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    std::deque<BasicBlock *> order;
    DenseSet<BasicBlock *> visited;
    clspv::ComputeStructuredOrder(&*F.begin(), &DT, LI, &order, &visited);

    for (auto BB : order) {
      auto terminator = BB->getTerminator();
      auto branch = dyn_cast<BranchInst>(terminator);
      if (LI.isLoopHeader(BB)) {
        auto L = LI.getLoopFor(BB);
        BasicBlock *ContinueBB = nullptr;
        BasicBlock *MergeBB = nullptr;

        MergeBB = L->getExitBlock();
        if (!MergeBB) {
          // StructurizeCFG pass converts CFG into triangle shape and the cfg
          // has regions with single entry/exit. As a result, loop should not
          // have multiple exits.
          llvm_unreachable("Loop has multiple exits???");
        }

        if (L->isLoopLatch(BB)) {
          ContinueBB = BB;
        } else {
          // From SPIR-V spec 2.11, Continue Target must dominate that back-edge
          // block.
          BasicBlock *Header = L->getHeader();
          BasicBlock *Latch = L->getLoopLatch();
          for (auto *loop_block : L->blocks()) {
            if (loop_block == Header) {
              continue;
            }

            // Check whether block dominates block with back-edge.
            // The loop latch is the single block with a back-edge. If it was
            // possible, StructurizeCFG made the loop conform to this
            // requirement, otherwise |Latch| is a nullptr.
            if (DT.dominates(loop_block, Latch)) {
              ContinueBB = loop_block;
            }
          }

          if (!ContinueBB) {
            llvm_unreachable("Wrong continue block from loop");
          }
        }

        // Record the continue and merge blocks.
        MergeBlocks[BB] = MergeBB;
        ContinueBlocks[BB] = ContinueBB;
        LoopMergesAndContinues.insert(MergeBB);
        LoopMergesAndContinues.insert(ContinueBB);
      } else if (branch && branch->isConditional()) {
        auto L = LI.getLoopFor(BB);
        bool HasBackedge = false;
        while (L && !HasBackedge) {
          if (L->isLoopLatch(BB)) {
            HasBackedge = true;
          }
          L = L->getParentLoop();
        }

        if (!HasBackedge) {
          // Only need a merge if the branch doesn't include a loop break or
          // continue.
          auto true_bb = branch->getSuccessor(0);
          auto false_bb = branch->getSuccessor(1);
          if (!LoopMergesAndContinues.count(true_bb) &&
              !LoopMergesAndContinues.count(false_bb)) {
            // StructurizeCFG pass already manipulated CFG. Just use false block
            // of branch instruction as merge block.
            MergeBlocks[BB] = false_bb;
          }
        }
      }
    }
  }
}

SPIRVID SPIRVProducerPassImpl::getReflectionImport() {
  if (!ReflectionID.isValid()) {
    if (SpvVersion() < clspv::Option::SPIRVVersion::SPIRV_1_6) {
      addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_KHR_non_semantic_info");
    }
    ReflectionID = addSPIRVInst<kImports>(spv::OpExtInstImport,
                                          "NonSemantic.ClspvReflection.5");
  }
  return ReflectionID;
}

void SPIRVProducerPassImpl::GenerateReflection() {
  GenerateKernelReflection();
  GeneratePrintfReflection();
  GeneratePushConstantReflection();
  GenerateSpecConstantReflection();
}

void SPIRVProducerPassImpl::GeneratePushConstantReflection() {
  if (auto GV = module->getGlobalVariable(clspv::PushConstantsVariableName())) {
    auto const &DL = module->getDataLayout();
    auto MD = GV->getMetadata(clspv::PushConstantsMetadataName());
    auto STy = cast<StructType>(GV->getValueType());

    for (unsigned i = 0; i < STy->getNumElements(); i++) {
      auto pc = static_cast<clspv::PushConstant>(
          mdconst::extract<ConstantInt>(MD->getOperand(i))->getZExtValue());
      if (pc == PushConstant::KernelArgument ||
          pc == PushConstant::ImageMetadata ||
          pc == PushConstant::ModuleConstantsPointer)
        continue;

      auto memberType = STy->getElementType(i);
      auto offset = GetExplicitLayoutStructMemberOffset(STy, i, DL);
#ifndef NDEBUG
      unsigned previousOffset = 0;
      if (i > 0) {
        previousOffset = GetExplicitLayoutStructMemberOffset(STy, i - 1, DL);
      }
      assert(isValidExplicitLayout(*module, STy, i,
                                   spv::StorageClassPushConstant, offset,
                                   previousOffset));
#endif

      reflection::ExtInst pc_inst = reflection::ExtInstMax;
      switch (pc) {
      case PushConstant::GlobalOffset:
        pc_inst = reflection::ExtInstPushConstantGlobalOffset;
        break;
      case PushConstant::EnqueuedLocalSize:
        pc_inst = reflection::ExtInstPushConstantEnqueuedLocalSize;
        break;
      case PushConstant::GlobalSize:
        pc_inst = reflection::ExtInstPushConstantGlobalSize;
        break;
      case PushConstant::RegionOffset:
        pc_inst = reflection::ExtInstPushConstantRegionOffset;
        break;
      case PushConstant::NumWorkgroups:
        pc_inst = reflection::ExtInstPushConstantNumWorkgroups;
        break;
      case PushConstant::RegionGroupOffset:
        pc_inst = reflection::ExtInstPushConstantRegionGroupOffset;
        break;
      case PushConstant::PrintfBufferPointer:
        pc_inst = reflection::ExtInstPrintfBufferPointerPushConstant;
        break;
      default:
        llvm_unreachable("Unhandled push constant");
        break;
      }

      auto import_id = getReflectionImport();
      auto size = static_cast<uint32_t>(GetTypeSizeInBits(memberType, DL)) / 8;
      SPIRVOperandVec Ops;
      Ops << getSPIRVType(Type::getVoidTy(module->getContext())) << import_id
          << pc_inst << getSPIRVInt32Constant(offset)
          << getSPIRVInt32Constant(size);

      if (pc == PushConstant::PrintfBufferPointer) {
        Ops << getSPIRVInt32Constant(clspv::Option::PrintfBufferSize());
      }
      addSPIRVInst(spv::OpExtInst, Ops);
    }
  }
}

void SPIRVProducerPassImpl::GenerateSpecConstantReflection() {
  const uint32_t kMax = std::numeric_limits<uint32_t>::max();
  uint32_t wgsize_id[3] = {kMax, kMax, kMax};
  uint32_t global_offset_id[3] = {kMax, kMax, kMax};
  uint32_t work_dim_id = kMax;
  uint32_t subgroup_max_size_id = kMax;
  for (auto pair : clspv::GetSpecConstants(module)) {
    auto kind = pair.first;
    auto id = pair.second;

    // Local memory size is only used for kernel arguments.
    if (kind == SpecConstant::kLocalMemorySize)
      continue;

    switch (kind) {
    case SpecConstant::kWorkgroupSizeX:
      wgsize_id[0] = id;
      break;
    case SpecConstant::kWorkgroupSizeY:
      wgsize_id[1] = id;
      break;
    case SpecConstant::kWorkgroupSizeZ:
      wgsize_id[2] = id;
      break;
    case SpecConstant::kGlobalOffsetX:
      global_offset_id[0] = id;
      break;
    case SpecConstant::kGlobalOffsetY:
      global_offset_id[1] = id;
      break;
    case SpecConstant::kGlobalOffsetZ:
      global_offset_id[2] = id;
      break;
    case SpecConstant::kWorkDim:
      work_dim_id = id;
      break;
    case SpecConstant::kSubgroupMaxSize:
      subgroup_max_size_id = id;
      break;
    default:
      llvm_unreachable("Unhandled spec constant");
    }
  }

  auto import_id = getReflectionImport();
  auto void_id = getSPIRVType(Type::getVoidTy(module->getContext()));
  SPIRVOperandVec Ops;
  if (wgsize_id[0] != kMax) {
    assert(wgsize_id[1] != kMax);
    assert(wgsize_id[2] != kMax);
    Ops.clear();
    Ops << void_id << import_id << reflection::ExtInstSpecConstantWorkgroupSize
        << getSPIRVInt32Constant(wgsize_id[0])
        << getSPIRVInt32Constant(wgsize_id[1])
        << getSPIRVInt32Constant(wgsize_id[2]);
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
  if (global_offset_id[0] != kMax) {
    assert(global_offset_id[1] != kMax);
    assert(global_offset_id[2] != kMax);
    Ops.clear();
    Ops << void_id << import_id << reflection::ExtInstSpecConstantGlobalOffset
        << getSPIRVInt32Constant(global_offset_id[0])
        << getSPIRVInt32Constant(global_offset_id[1])
        << getSPIRVInt32Constant(global_offset_id[2]);
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
  if (work_dim_id != kMax) {
    Ops.clear();
    Ops << void_id << import_id << reflection::ExtInstSpecConstantWorkDim
        << getSPIRVInt32Constant(work_dim_id);
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
  if (subgroup_max_size_id != kMax) {
    Ops.clear();
    Ops << void_id << import_id
        << reflection::ExtInstSpecConstantSubgroupMaxSize
        << getSPIRVInt32Constant(subgroup_max_size_id);
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
}

void SPIRVProducerPassImpl::GenerateKernelReflection() {
  const auto &DL = module->getDataLayout();
  auto import_id = getReflectionImport();
  auto void_id = getSPIRVType(Type::getVoidTy(module->getContext()));

  for (auto &F : *module) {
    if (F.isDeclaration() || F.getCallingConv() != CallingConv::SPIR_KERNEL) {
      continue;
    }

    // OpString for the kernel name.
    auto kernel_name =
        addSPIRVInst<kDebug>(spv::OpString, F.getName().str().c_str());

    // If we've clustered POD arguments, then argument details are in metadata.
    // If an argument maps to a resource variable, then get descriptor set and
    // binding from the resource variable.  Other info comes from the metadata.
    const auto *arg_map = F.getMetadata(clspv::KernelArgMapMetadataName());
    uint32_t num_args = 0;
    if (arg_map) {
      num_args = arg_map->getNumOperands();
    } else {
      num_args = F.getFunctionType()->getNumParams();
    }

    uint32_t kernel_flags = reflection::ExtKernelPropertyFlags::None;
    if (F.hasMetadata(clspv::PrintfKernelMetadataName())) {
      kernel_flags |= reflection::ExtKernelPropertyFlags::MayUsePrintf;
    }

    auto attributes_op_string = addSPIRVInst<kDebug>(
        spv::OpString, functionAttrStrings[F.getName()].c_str());

    // Kernel declaration
    // Ops[0] = void type
    // Ops[1] = reflection ext import
    // Ops[2] = function id
    // Ops[3] = kernel name
    // Ops[4] = number of arguments
    // Ops[5] = Flags
    // Ops[6] = Attributes
    SPIRVOperandVec Ops;
    Ops << void_id << import_id << reflection::ExtInstKernel << ValueMap[&F]
        << kernel_name << getSPIRVInt32Constant(num_args)
        << getSPIRVInt32Constant(kernel_flags) << attributes_op_string;
    auto kernel_decl = addSPIRVInst<kReflection>(spv::OpExtInst, Ops);

    // Generate the required workgroup size property if it was specified.
    if (const MDNode *MD = F.getMetadata("reqd_work_group_size")) {
      uint32_t CurXDimCst = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(0))->getZExtValue());
      uint32_t CurYDimCst = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(1))->getZExtValue());
      uint32_t CurZDimCst = static_cast<uint32_t>(
          mdconst::extract<ConstantInt>(MD->getOperand(2))->getZExtValue());

      Ops.clear();
      Ops << void_id << import_id
          << reflection::ExtInstPropertyRequiredWorkgroupSize << kernel_decl
          << getSPIRVInt32Constant(CurXDimCst)
          << getSPIRVInt32Constant(CurYDimCst)
          << getSPIRVInt32Constant(CurZDimCst);
      addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
    }

    auto &resource_var_at_index = FunctionToResourceVarsMap[&F];

    auto local_spec_id_md =
        module->getNamedMetadata(clspv::LocalSpecIdMetadataName());

    // Map new ordinals to old ordinals to be able to use old ordinals when
    // generating reflection for image metadata.
    std::unordered_map<uint32_t, uint32_t> ordinals_map;

    if (arg_map) {
      for (const auto &arg : arg_map->operands()) {
        const MDNode *arg_node = dyn_cast<MDNode>(arg.get());
        assert(arg_node->getNumOperands() == 6);
        const auto name =
            dyn_cast<MDString>(arg_node->getOperand(0))->getString();
        const auto old_index =
            dyn_extract<ConstantInt>(arg_node->getOperand(1))->getZExtValue();
        // Remapped argument index
        const int new_index = static_cast<int>(
            dyn_extract<ConstantInt>(arg_node->getOperand(2))->getSExtValue());
        const auto offset =
            dyn_extract<ConstantInt>(arg_node->getOperand(3))->getZExtValue();
        const auto size =
            dyn_extract<ConstantInt>(arg_node->getOperand(4))->getZExtValue();
        const auto argKind = clspv::GetArgKindFromName(
            dyn_cast<MDString>(arg_node->getOperand(5))->getString().str());

        ordinals_map[new_index] = old_index;

        // If this is a local memory argument, find the right spec id for this
        // argument.
        int64_t spec_id = -1;
        if (argKind == clspv::ArgKind::Local && local_spec_id_md) {
          for (auto spec_id_arg : local_spec_id_md->operands()) {
            if ((&F == dyn_cast<Function>(
                           dyn_cast<ValueAsMetadata>(spec_id_arg->getOperand(0))
                               ->getValue())) &&
                (static_cast<uint64_t>(new_index) ==
                 mdconst::extract<ConstantInt>(spec_id_arg->getOperand(1))
                     ->getZExtValue())) {
              spec_id =
                  mdconst::extract<ConstantInt>(spec_id_arg->getOperand(2))
                      ->getSExtValue();
              break;
            }
          }
        }

        // Generate the specific argument instruction.
        const uint32_t ordinal = static_cast<uint32_t>(old_index);
        uint32_t arg_offset = static_cast<uint32_t>(offset);
        const uint32_t arg_size = static_cast<uint32_t>(size);
        uint32_t elem_size = 0;
        uint32_t descriptor_set = 0;
        uint32_t binding = 0;
        if (spec_id > 0) {
          auto &local_arg_info = LocalSpecIdInfoMap[spec_id];
          elem_size = static_cast<uint32_t>(
              GetTypeAllocSize(local_arg_info.elem_type, DL));
        } else if (new_index >= 0) {
          if (static_cast<uint64_t>(new_index) >=
                  resource_var_at_index.size() ||
              !resource_var_at_index[new_index]) {
            // Unused
            continue;
          }
          auto *info = resource_var_at_index[new_index];
          assert(info);
          descriptor_set = info->descriptor_set;
          binding = info->binding;
        }
        AddArgumentReflection(F, kernel_decl, name.str(), argKind, ordinal,
                              descriptor_set, binding, arg_offset, arg_size,
                              static_cast<uint32_t>(spec_id), elem_size);
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
          if (info->arg_kind == clspv::ArgKind::Pod ||
              info->arg_kind == clspv::ArgKind::PodUBO ||
              info->arg_kind == clspv::ArgKind::PodPushConstant) {
            arg_size =
                static_cast<uint32_t>(DL.getTypeStoreSize(arg->getType()));
          }

          // Local pointer arguments are unused in this case.
          // offset, spec_id and elem_size always 0.
          AddArgumentReflection(F, kernel_decl, arg->getName().str(),
                                info->arg_kind, arg_index, info->descriptor_set,
                                info->binding, 0, arg_size, 0, 0);
        }
        arg_index++;
      }
      // Generate mappings for pointer-to-local arguments.
      for (arg_index = 0; arg_index < arguments.size(); ++arg_index) {
        Argument *arg = arguments[arg_index];
        auto where = LocalArgSpecIds.find(arg);
        if (where != LocalArgSpecIds.end()) {
          auto &local_arg_info = LocalSpecIdInfoMap[where->second];

          // descriptor_set, binding, offset and size are always 0.
          AddArgumentReflection(F, kernel_decl, arg->getName().str(),
                                ArgKind::Local, arg_index, 0, 0, 0, 0,
                                static_cast<uint32_t>(local_arg_info.spec_id),
                                static_cast<uint32_t>(GetTypeAllocSize(
                                    local_arg_info.elem_type, DL)));
        }
      }
    }

    // Generate the reflection for the image channel getter function if it is
    // used in this kernel.
    auto *image_getter_md = F.getMetadata(clspv::PushConstantsMetadataImageChannelName());
    if (image_getter_md) {
      auto GV = module->getGlobalVariable(clspv::PushConstantsVariableName());
      auto STy = cast<StructType>(GV->getValueType());
      auto num_operands = image_getter_md->getNumOperands();
      assert(num_operands % 3 == 0);
      for (unsigned i = 0; i < num_operands; i += 3) {
        auto ordinal =
            mdconst::extract<ConstantInt>(image_getter_md->getOperand(i + 0))
                ->getZExtValue();

        // Ordinals could have changed because of pod arguments, remap it to the
        // initial ordinal if needed.
        auto find = ordinals_map.find(ordinal);
        if (find != ordinals_map.end()) {
          ordinal = find->second;
        }

        auto index =
            mdconst::extract<ConstantInt>(image_getter_md->getOperand(i + 1))
                ->getZExtValue();
        auto pc = static_cast<clspv::ImageMetadata>(
            mdconst::extract<ConstantInt>(image_getter_md->getOperand(i + 2))
                ->getZExtValue());
        auto offset = GetExplicitLayoutStructMemberOffset(
                          STy, STy->getStructNumElements() - 1, DL) +
                      GetExplicitLayoutStructMemberOffset(
                          cast<StructType>(STy->getStructElementType(
                              STy->getStructNumElements() - 1)),
                          index, DL);

        reflection::ExtInst pc_inst = reflection::ExtInstMax;
        switch (pc) {
        case ImageMetadata::ChannelOrder:
          pc_inst =
              reflection::ExtInstImageArgumentInfoChannelOrderPushConstant;
          break;
        case ImageMetadata::ChannelDataType:
          pc_inst =
              reflection::ExtInstImageArgumentInfoChannelDataTypePushConstant;
          break;
        default:
          llvm_unreachable("Unhandled push constant");
          break;
        }
        Ops.clear();
        Ops << getSPIRVType(Type::getVoidTy(module->getContext())) << import_id
            << pc_inst << kernel_decl << getSPIRVInt32Constant(ordinal)
            << getSPIRVInt32Constant(offset)
            << getSPIRVInt32Constant(sizeof(uint32_t));
        addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
      }
    }
  }
}

void SPIRVProducerPassImpl::AddArgumentReflection(
    const Function &kernelFn, SPIRVID kernel_decl, const std::string &name,
    clspv::ArgKind arg_kind, uint32_t ordinal, uint32_t descriptor_set,
    uint32_t binding, uint32_t offset, uint32_t size, uint32_t spec_id,
    uint32_t elem_size) {
  // Generate ArgumentInfo for this argument.
  auto import_id = getReflectionImport();
  auto kernel_arg_name = kernelFn.getMetadata("kernel_arg_name");
  SPIRVID arg_name;
  if (kernel_arg_name) {
    arg_name = addSPIRVInst<kDebug>(
        spv::OpString, dyn_cast<MDString>(kernel_arg_name->getOperand(ordinal))
                           ->getString()
                           .str()
                           .c_str());
  } else {
    // For legacy purpose
    arg_name = addSPIRVInst<kDebug>(spv::OpString, name.c_str());
  }
  auto void_id = getSPIRVType(Type::getVoidTy(module->getContext()));
  SPIRVOperandVec Ops;
  Ops << void_id << import_id << reflection::ExtInstArgumentInfo << arg_name;

  if (clspv::Option::KernelArgInfo()) {
    assert(kernelFn.getMetadata("kernel_arg_type") &&
            kernelFn.getMetadata("kernel_arg_addr_space") &&
            kernelFn.getMetadata("kernel_arg_access_qual") &&
            kernelFn.getMetadata("kernel_arg_type_qual")
          );
    auto const &type_op =
        kernelFn.getMetadata("kernel_arg_type")->getOperand(ordinal);
    auto const &type_name_str = dyn_cast<MDString>(type_op)->getString();
    auto type_name =
        addSPIRVInst<kDebug>(spv::OpString, type_name_str.str().c_str());
    Ops << type_name;

    auto const &addrspace_op =
        kernelFn.getMetadata("kernel_arg_addr_space")->getOperand(ordinal);
    auto addrspace =
        mdconst::extract<ConstantInt>(addrspace_op)->getZExtValue();
    unsigned addrspace_enum_value = 0x119E; // CL_KERNEL_ARG_ADDRESS_PRIVATE
    switch (addrspace) {
    case clspv::AddressSpace::Global:
      addrspace_enum_value = 0x119B; // CL_KERNEL_ARG_ADDRESS_GLOBAL
      break;
    case clspv::AddressSpace::Constant:
      addrspace_enum_value = 0x119D; // CL_KERNEL_ARG_ADDRESS_CONSTANT
      break;
    case clspv::AddressSpace::Local:
      addrspace_enum_value = 0x119C; // CL_KERNEL_ARG_ADDRESS_LOCAL
      break;
    }
    auto addrspace_enum = getSPIRVInt32Constant(addrspace_enum_value);
    Ops << addrspace_enum;

    auto const &access_qual_op =
        kernelFn.getMetadata("kernel_arg_access_qual")->getOperand(ordinal);
    auto const &access_qual_str =
        dyn_cast<MDString>(access_qual_op)->getString();
    unsigned access_qual_enum_value =
        StringSwitch<unsigned>(access_qual_str)
            .Case("read_only", 0x11A0)  // CL_KERNEL_ARG_ACCESS_READ_ONLY
            .Case("write_only", 0x11A1) // CL_KERNEL_ARG_ACCESS_WRITE_ONLY
            .Case("read_write", 0x11A2) // CL_KERNEL_ARG_ACCESS_READ_WRITE
            .Default(0x11A3);           // CL_KERNEL_ARG_ACCESS_NONE
    auto access_qual_enum = getSPIRVInt32Constant(access_qual_enum_value);
    Ops << access_qual_enum;

    auto const &type_qual_op =
        kernelFn.getMetadata("kernel_arg_type_qual")->getOperand(ordinal);
    auto const &type_qual_str = dyn_cast<MDString>(type_qual_op)->getString();
    unsigned type_qual_enum_value = 0; // CL_KERNEL_ARG_TYPE_NONE
    if (type_qual_str.find("const") != std::string::npos) {
      type_qual_enum_value |= (1 << 0); // CL_KERNEL_ARG_TYPE_CONST
    }
    if (type_qual_str.find("restrict") != std::string::npos) {
      type_qual_enum_value |= (1 << 1); // CL_KERNEL_ARG_TYPE_RESTRICT
    }
    if (type_qual_str.find("volatile") != std::string::npos) {
      type_qual_enum_value |= (1 << 2); // CL_KERNEL_ARG_TYPE_VOLATILE
    }
    if (type_qual_str.find("pipe") != std::string::npos) {
      type_qual_enum_value |= (1 << 3); // CL_KERNEL_ARG_TYPE_PIPE
    }
    auto type_qual_enum = getSPIRVInt32Constant(type_qual_enum_value);
    Ops << type_qual_enum;
  
  }

  auto arg_info = addSPIRVInst<kReflection>(spv::OpExtInst, Ops);

  Ops.clear();
  Ops << void_id << import_id;
  reflection::ExtInst ext_inst = reflection::ExtInstMax;
  // Determine the extended instruction.
  switch (arg_kind) {
  case clspv::ArgKind::Buffer:
    ext_inst = reflection::ExtInstArgumentStorageBuffer;
    break;
  case clspv::ArgKind::BufferUBO:
    ext_inst = reflection::ExtInstArgumentUniform;
    break;
  case clspv::ArgKind::Local:
    ext_inst = reflection::ExtInstArgumentWorkgroup;
    break;
  case clspv::ArgKind::Pod:
    ext_inst = reflection::ExtInstArgumentPodStorageBuffer;
    break;
  case clspv::ArgKind::PodUBO:
    ext_inst = reflection::ExtInstArgumentPodUniform;
    break;
  case clspv::ArgKind::PodPushConstant:
    ext_inst = reflection::ExtInstArgumentPodPushConstant;
    break;
  case clspv::ArgKind::PointerPushConstant:
    ext_inst = reflection::ExtInstArgumentPointerPushConstant;
    break;
  case clspv::ArgKind::PointerUBO:
    ext_inst = reflection::ExtInstArgumentPointerUniform;
    break;
  case clspv::ArgKind::SampledImage:
    ext_inst = reflection::ExtInstArgumentSampledImage;
    break;
  case clspv::ArgKind::StorageImage:
    ext_inst = reflection::ExtInstArgumentStorageImage;
    break;
  case clspv::ArgKind::Sampler:
    ext_inst = reflection::ExtInstArgumentSampler;
    break;
  case clspv::ArgKind::StorageTexelBuffer:
    ext_inst = reflection::ExtInstArgumentStorageTexelBuffer;
    break;
  case clspv::ArgKind::UniformTexelBuffer:
    ext_inst = reflection::ExtInstArgumentUniformTexelBuffer;
    break;
  default:
    llvm_unreachable("Unhandled argument reflection");
    break;
  }
  Ops << ext_inst << kernel_decl << getSPIRVInt32Constant(ordinal);

  // Add descriptor set and binding for applicable arguments.
  switch (arg_kind) {
  case clspv::ArgKind::Buffer:
  case clspv::ArgKind::BufferUBO:
  case clspv::ArgKind::Pod:
  case clspv::ArgKind::PodUBO:
  case clspv::ArgKind::PointerUBO:
  case clspv::ArgKind::SampledImage:
  case clspv::ArgKind::StorageImage:
  case clspv::ArgKind::Sampler:
  case clspv::ArgKind::StorageTexelBuffer:
  case clspv::ArgKind::UniformTexelBuffer:
    Ops << getSPIRVInt32Constant(descriptor_set)
        << getSPIRVInt32Constant(binding);
    break;
  default:
    break;
  }

  // Add remaining operands for arguments.
  switch (arg_kind) {
  case clspv::ArgKind::Local:
    Ops << getSPIRVInt32Constant(spec_id) << getSPIRVInt32Constant(elem_size);
    break;
  case clspv::ArgKind::Pod:
  case clspv::ArgKind::PodUBO:
  case clspv::ArgKind::PodPushConstant:
  case clspv::ArgKind::PointerPushConstant:
  case clspv::ArgKind::PointerUBO:
    Ops << getSPIRVInt32Constant(offset) << getSPIRVInt32Constant(size);
    break;
  default:
    break;
  }
  Ops << arg_info;
  addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
}

void SPIRVProducerPassImpl::GeneratePrintfReflection() {
  auto import_id = getReflectionImport();
  auto void_id = getSPIRVType(Type::getVoidTy(module->getContext()));

  auto *PrintfMD = module->getNamedMetadata(PrintfMetadataName());
  if (!PrintfMD) {
    return;
  }

  SPIRVOperandVec Ops;

  for (auto *PrintMD : PrintfMD->operands()) {
    Ops << void_id << import_id << reflection::ExtInstPrintfInfo;

    assert(PrintMD->getNumOperands() == 3);
    auto *PrintfID = dyn_cast<ConstantAsMetadata>(PrintMD->getOperand(0).get());
    auto *PrintfString = dyn_cast<MDString>(PrintMD->getOperand(1).get());
    auto *PrintfArgs = dyn_cast<MDTuple>(PrintMD->getOperand(2).get());
    auto PrintfStringConstant = addSPIRVInst<kDebug>(
        spv::OpString, PrintfString->getString().str().c_str());

    Ops << getSPIRVInt32Constant(static_cast<int32_t>(
        mdconst::extract<ConstantInt>(PrintfID)->getZExtValue()));
    Ops << PrintfStringConstant;
    for (auto &ArgSizeOperand : PrintfArgs->operands()) {
      auto *ArgSizeConst = dyn_cast<ConstantAsMetadata>(ArgSizeOperand.get());
      int32_t ArgSizeVal = static_cast<int32_t>(
          mdconst::extract<ConstantInt>(ArgSizeConst)->getZExtValue());
      Ops << getSPIRVInt32Constant(ArgSizeVal);
    }
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
  }
}
