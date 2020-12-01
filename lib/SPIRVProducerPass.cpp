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
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
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

cl::opt<bool> ShowResourceVars("show-rv", cl::init(false), cl::Hidden,
                               cl::desc("Show resource variable creation"));

cl::opt<bool>
    ShowProducerIR("show-producer-ir", cl::init(false), cl::ReallyHidden,
                   cl::desc("Dump the IR at the start of SPIRVProducer"));

// These hacks exist to help transition code generation algorithms
// without making huge noise in detailed test output.
const bool Hack_generate_runtime_array_stride_early = true;

// The value of 1/pi.  This value is from MSDN
// https://msdn.microsoft.com/en-us/library/4hwaceh6.aspx
const double kOneOverPi = 0.318309886183790671538;
const glsl::ExtInst kGlslExtInstBad = static_cast<glsl::ExtInst>(0);

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
  explicit SPIRVOperand(SPIRVOperandType Ty, uint32_t Num) : Type(Ty) {
    LiteralNum[0] = Num;
  }
  explicit SPIRVOperand(SPIRVOperandType Ty, const char *Str)
      : Type(Ty), LiteralStr(Str) {}
  explicit SPIRVOperand(SPIRVOperandType Ty, StringRef Str)
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

struct SPIRVProducerPass final : public ModulePass {
  typedef DenseMap<Type *, SPIRVID> TypeMapType;
  typedef UniqueVector<Type *> TypeList;
  typedef DenseMap<Value *, SPIRVID> ValueMapType;
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

  explicit SPIRVProducerPass(
      raw_pwrite_stream &out,
      ArrayRef<std::pair<unsigned, std::string>> samplerMap,
      bool outputCInitList)
      : ModulePass(ID), module(nullptr), samplerMap(samplerMap), out(out),
        binaryTempOut(binaryTempUnderlyingVector), binaryOut(&out),
        outputCInitList(outputCInitList), patchBoundOffset(0), nextID(1),
        OpExtInstImportID(0), HasVariablePointersStorageBuffer(false),
        HasVariablePointers(false), SamplerTy(nullptr), WorkgroupSizeValueID(0),
        WorkgroupSizeVarID(0) {
    addCapability(spv::CapabilityShader);
    Ptr = this;
  }

  virtual ~SPIRVProducerPass() {
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

  CapabilitySetType &getCapabilitySet() { return CapabilitySet; }
  TypeMapType &getImageTypeMap() { return ImageTypeMap; }
  TypeList &getTypeList() { return Types; }
  ValueMapType &getValueMap() { return ValueMap; }
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

  void GenerateLLVMIRInfo();
  // Populate GlobalConstFuncTypeMap. Also, if module-scope __constant will
  // *not* be converted to a storage buffer, replace each such global variable
  // with one in the storage class expecgted by SPIR-V.
  void FindGlobalConstVars();
  // Populate ResourceVarInfoList, FunctionToResourceVarsMap, and
  // ModuleOrderedResourceVars.
  void FindResourceVars();
  void FindTypePerGlobalVar(GlobalVariable &GV);
  void FindTypePerFunc(Function &F);
  void FindTypesForSamplerMap();
  void FindTypesForResourceVars();
  // Inserts |Ty| and relevant sub-types into the |Types| member, indicating
  // that |Ty| and its subtypes will need a corresponding SPIR-V type.
  void FindType(Type *Ty);

  // Returns the canonical type of |type|.
  //
  // By default, clspv maps both __constant and __global address space pointers
  // to StorageBuffer storage class. In order to prevent duplicate types from
  // being generated, clspv uses the canonical type as a representative.
  Type *CanonicalType(Type *type);

  // Lookup or create Types, Constants.
  // Returns SPIRVID once it has been created.
  SPIRVID getSPIRVType(Type *Ty);
  SPIRVID getSPIRVConstant(Constant *Cst);
  SPIRVID getSPIRVInt32Constant(uint32_t CstVal);
  // Lookup SPIRVID of llvm::Value, may create Constant.
  SPIRVID getSPIRVValue(Value *V);

  SPIRVID getSPIRVBuiltin(spv::BuiltIn BID, spv::Capability Cap);

  // Generates instructions for SPIR-V types corresponding to the LLVM types
  // saved in the |Types| member.  A type follows its subtypes.  IDs are
  // allocated sequentially starting with the current value of nextID, and
  // with a type following its subtypes.  Also updates nextID to just beyond
  // the last generated ID.
  void GenerateSPIRVTypes();
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
  spv::Op GetSPIRVCastOpcode(Instruction &I);
  spv::Op GetSPIRVBinaryOpcode(Instruction &I);
  SPIRVID GenerateClspvInstruction(CallInst *Call,
                                   const FunctionInfo &FuncInfo);
  SPIRVID GenerateImageInstruction(CallInst *Call,
                                   const FunctionInfo &FuncInfo);
  SPIRVID GenerateSubgroupInstruction(CallInst *Call,
                                      const FunctionInfo &FuncInfo);
  SPIRVID GenerateInstructionFromCall(CallInst *Call);
  void GenerateInstruction(Instruction &I);
  void GenerateFuncEpilogue();
  void HandleDeferredInstruction();
  void HandleDeferredDecorations();
  bool is4xi8vec(Type *Ty) const;
  spv::StorageClass GetStorageClass(unsigned AddrSpace) const;
  spv::StorageClass GetStorageClassForArgKind(clspv::ArgKind arg_kind) const;
  spv::BuiltIn GetBuiltin(StringRef globalVarName) const;
  // Returns the GLSL extended instruction enum that the given function
  // call maps to.  If none, then returns the 0 value, i.e. GLSLstd4580Bad.
  glsl::ExtInst getExtInstEnum(const Builtins::FunctionInfo &func_info);
  // Returns the GLSL extended instruction enum indirectly used by the given
  // function.  That is, to implement the given function, we use an extended
  // instruction plus one more instruction. If none, then returns the 0 value,
  // i.e. GLSLstd4580Bad.
  glsl::ExtInst getIndirectExtInstEnum(const Builtins::FunctionInfo &func_info);
  // Returns the single GLSL extended instruction used directly or
  // indirectly by the given function call.
  glsl::ExtInst
  getDirectOrIndirectExtInstEnum(const Builtins::FunctionInfo &func_info);
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
  uint64_t GetTypeStoreSize(Type *type, const DataLayout &DL);
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

  // Returns true if |Arg| is called with a coherent resource.
  bool CalledWithCoherentResource(Argument &Arg);

  //
  // Primary interface for adding SPIRVInstructions to a SPIRVSection.
  template <enum SPIRVSection TSection = kFunctions>
  SPIRVID addSPIRVInst(spv::Op Opcode, SPIRVOperandVec &Operands) {
    bool has_result, has_result_type;
    spv::HasResultAndType(Opcode, &has_result, &has_result_type);
    SPIRVID RID = has_result ? incrNextID() : 0;
    SPIRVSections[TSection].emplace_back(Opcode, RID, Operands);
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
                                 const SPIRVID &InitID = SPIRVID());

  SPIRVID getReflectionImport();
  void GenerateReflection();
  void GenerateKernelReflection();
  void GeneratePushConstantReflection();
  void GenerateSpecConstantReflection();
  void AddArgumentReflection(SPIRVID kernel_decl, const std::string &name,
                             clspv::ArgKind arg_kind, uint32_t ordinal,
                             uint32_t descriptor_set, uint32_t binding,
                             uint32_t offset, uint32_t size, uint32_t spec_id,
                             uint32_t elem_size);

private:
  static char ID;

  Module *module;

  // Set of Capabilities required
  CapabilitySetType CapabilitySet;

  // Map from clspv::BuiltinType to SPIRV Global Variable
  BuiltinConstantMapType BuiltinConstantMap;

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
  const bool outputCInitList; // If true, output look like {0x7023, ... , 5}
  uint64_t patchBoundOffset;
  uint32_t nextID;

  SPIRVID incrNextID() { return nextID++; }

  // ID for OpTypeInt 32 1.
  SPIRVID int32ID;
  // ID for OpTypeVector %int 4.
  SPIRVID v4int32ID;

  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  TypeMapType TypeMap;
  // Maps an LLVM image type to its SPIR-V ID.
  TypeMapType ImageTypeMap;
  // A unique-vector of LLVM types that map to a SPIR-V type.
  TypeList Types;
  // Maps an LLVM Value pointer to the corresponding SPIR-V Id.
  ValueMapType ValueMap;
  SPIRVInstructionList SPIRVSections[kSectionCount];

  EntryPointVecType EntryPointVec;
  DeferredInstVecType DeferredInstVec;
  SPIRVIDListType EntryPointInterfacesList;
  SPIRVID OpExtInstImportID;
  std::vector<SPIRVID> BuiltinDimensionVec;
  bool HasVariablePointersStorageBuffer;
  bool HasVariablePointers;
  Type *SamplerTy;
  DenseMap<unsigned, SPIRVID> SamplerLiteralToIDMap;

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
  SPIRVID WorkgroupSizeValueID;
  SPIRVID WorkgroupSizeVarID;

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

public:
  static SPIRVProducerPass *Ptr;
};

char SPIRVProducerPass::ID;
SPIRVProducerPass *SPIRVProducerPass::Ptr = nullptr;

} // namespace

namespace clspv {
ModulePass *
createSPIRVProducerPass(raw_pwrite_stream &out,
                        ArrayRef<std::pair<unsigned, std::string>> samplerMap,
                        bool outputCInitList) {
  return new SPIRVProducerPass(out, samplerMap, outputCInitList);
}
} // namespace clspv

namespace {
SPIRVOperandVec &operator<<(SPIRVOperandVec &list, uint32_t num) {
  list.emplace_back(LITERAL_WORD, num);
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, int32_t num) {
  list.emplace_back(LITERAL_WORD, static_cast<uint32_t>(num));
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, ArrayRef<uint32_t> num_vec) {
  list.emplace_back(num_vec);
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, StringRef str) {
  list.emplace_back(LITERAL_STRING, str);
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, Type *t) {
  list.emplace_back(NUMBERID, SPIRVProducerPass::Ptr->getSPIRVType(t).get());
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, Value *v) {
  list.emplace_back(NUMBERID, SPIRVProducerPass::Ptr->getSPIRVValue(v).get());
  return list;
}

SPIRVOperandVec &operator<<(SPIRVOperandVec &list, const SPIRVID &v) {
  list.emplace_back(NUMBERID, v.get());
  return list;
}
} // namespace

bool SPIRVProducerPass::runOnModule(Module &M) {
  // TODO(sjw): Need to reset all data members for each Module, or better
  // yet create a new SPIRVProducer for every module.. For now only
  // allow 1 call.
  assert(module == nullptr);
  module = &M;
  if (ShowProducerIR) {
    llvm::outs() << *module << "\n";
  }
  binaryOut = outputCInitList ? &binaryTempOut : &out;

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

    // Collect types' information from global variable.
    FindTypePerGlobalVar(GV);
  }

  // Generate SPIRV instructions for types.
  GenerateSPIRVTypes();

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
    out << os.str();
  }

  return false;
}

void SPIRVProducerPass::outputHeader() {
  binaryOut->write(reinterpret_cast<const char *>(&spv::MagicNumber),
                   sizeof(spv::MagicNumber));
  uint32_t minor = 0;
  if (SpvVersion() == SPIRVVersion::SPIRV_1_3) {
    minor = 3;
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

void SPIRVProducerPass::patchHeader() {
  // for a binary we just write the value of nextID over bound
  binaryOut->pwrite(reinterpret_cast<char *>(&nextID), sizeof(nextID),
                    patchBoundOffset);
}

void SPIRVProducerPass::GenerateLLVMIRInfo() {
  // This function generates LLVM IR for function such as global variable for
  // argument, constant and pointer type for argument access. These information
  // is artificial one because we need Vulkan SPIR-V output. This function is
  // executed ahead of FindType and FindConstant.

  FindGlobalConstVars();

  FindResourceVars();

  bool HasWorkGroupBuiltin = false;
  for (GlobalVariable &GV : module->globals()) {
    const spv::BuiltIn BuiltinType = GetBuiltin(GV.getName());
    if (spv::BuiltInWorkgroupSize == BuiltinType) {
      HasWorkGroupBuiltin = true;
    }
  }

  FindTypesForSamplerMap();
  FindTypesForResourceVars();
}

void SPIRVProducerPass::FindGlobalConstVars() {
  clspv::NormalizeGlobalVariables(*module);
  const DataLayout &DL = module->getDataLayout();

  SmallVector<GlobalVariable *, 8> GVList;
  SmallVector<GlobalVariable *, 8> DeadGVList;
  for (GlobalVariable &GV : module->globals()) {
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
      Type *NewGVTy = GV->getType()->getPointerElementType();
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

void SPIRVProducerPass::FindResourceVars() {
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
              rv = new ResourceVarInfo(
                  static_cast<int>(ResourceVarInfoList.size()), set, binding,
                  &F, arg_kind, coherent);
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
                  &F, arg_kind, coherent);
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
             << "\n";
    }
  }
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

      if (Call) {
        auto &func_info = Builtins::Lookup(Call->getCalledFunction());
        if (func_info.getType() == Builtins::kClspvResource ||
            func_info.getType() == Builtins::kClspvLocal) {
          // This is a fake call representing access to a resource/workgroup
          // variable. We handle that elsewhere.
          continue;
        }
      }

      // #497: InsertValue and ExtractValue map to OpCompositeInsert and
      // OpCompositeExtract which takes literal values for indices. As a result
      // don't map the type of indices.
      if (I.getOpcode() == Instruction::ExtractValue) {
        FindType(I.getOperand(0)->getType());
        continue;
      }
      if (I.getOpcode() == Instruction::InsertValue) {
        FindType(I.getOperand(0)->getType());
        FindType(I.getOperand(1)->getType());
        continue;
      }

      // #497: InsertElement and ExtractElement map to OpCompositeExtract if
      // the index is a constant. In such a case don't map the index type.
      if (I.getOpcode() == Instruction::ExtractElement) {
        FindType(I.getOperand(0)->getType());
        Value *op1 = I.getOperand(1);
        if (!isa<Constant>(op1) || isa<GlobalValue>(op1)) {
          FindType(op1->getType());
        }
        continue;
      }
      if (I.getOpcode() == Instruction::InsertElement) {
        FindType(I.getOperand(0)->getType());
        FindType(I.getOperand(1)->getType());
        Value *op2 = I.getOperand(2);
        if (!isa<Constant>(op2) || isa<GlobalValue>(op2)) {
          FindType(op2->getType());
        }
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
          if (Builtins::Lookup(OpCall->getCalledFunction()) ==
              Builtins::kClspvLocal) {
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
      if (Call && Builtins::Lookup(Call->getCalledFunction()) ==
                      Builtins::kClspvSamplerVarLiteral) {
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

void SPIRVProducerPass::FindTypesForSamplerMap() {
  // If we are using a sampler map, find the type of the sampler.
  if (module->getFunction(clspv::LiteralSamplerFunction()) ||
      !getSamplerMap().empty()) {
    auto SamplerStructTy =
        StructType::getTypeByName(module->getContext(), "opencl.sampler_t");
    if (!SamplerStructTy) {
      SamplerStructTy =
          StructType::create(module->getContext(), "opencl.sampler_t");
    }

    SamplerTy = SamplerStructTy->getPointerTo(AddressSpace::UniformConstant);

    FindType(SamplerTy);
  }
}

void SPIRVProducerPass::FindTypesForResourceVars() {
  // Record types so they are generated.
  TypesNeedingLayout.reset();
  StructTypesNeedingBlock.reset();

  // To match older clspv codegen, generate the float type first if required
  // for images.
  for (const auto *info : ModuleOrderedResourceVars) {
    if (info->arg_kind == clspv::ArgKind::SampledImage ||
        info->arg_kind == clspv::ArgKind::StorageImage) {
      if (IsIntImageType(info->var_fn->getReturnType())) {
        // Nothing for now...
      } else if (IsUintImageType(info->var_fn->getReturnType())) {
        FindType(Type::getInt32Ty(module->getContext()));
      }

      // We need "float" either for the sampled type or for the Lod operand.
      FindType(Type::getFloatTy(module->getContext()));
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
    case clspv::ArgKind::PodUBO:
    case clspv::ArgKind::PodPushConstant:
      if (auto *sty = dyn_cast<StructType>(type->getPointerElementType())) {
        StructTypesNeedingBlock.insert(sty);
      } else {
        errs() << *type << "\n";
        llvm_unreachable("POD arguments must map to structures!");
      }
      break;
    case clspv::ArgKind::SampledImage:
    case clspv::ArgKind::StorageImage:
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
            cast<StructType>(PTy->getPointerElementType()));
      }
    }
  }

  for (const GlobalVariable &GV : module->globals()) {
    if (GV.getAddressSpace() == clspv::AddressSpace::PushConstant) {
      auto Ty = cast<PointerType>(GV.getType())->getPointerElementType();
      assert(Ty->isStructTy() && "Push constants have to be structures.");
      auto STy = cast<StructType>(Ty);
      StructTypesNeedingBlock.insert(STy);
    }
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

void SPIRVProducerPass::GenerateWorkgroupVars() {
  // The SpecId assignment for pointer-to-local arguments is recorded in
  // module-level metadata. Translate that information into local argument
  // information.
  LLVMContext &Context = module->getContext();
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
    if (LocalSpecIdInfoMap.count(spec_id))
      continue;

    // Generate the spec constant.
    SPIRVOperandVec Ops;
    Ops << Type::getInt32Ty(Context) << 1;
    SPIRVID ArraySizeID = addSPIRVInst<kConstants>(spv::OpSpecConstant, Ops);

    // Generate the array type.
    Type *ElemTy = arg->getType()->getPointerElementType();
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
  case AddressSpace::PushConstant:
    return spv::StorageClassPushConstant;
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
      .Case("__spirv_WorkDim", spv::BuiltInWorkDim)
      .Case("__spirv_GlobalOffset", spv::BuiltInGlobalOffset)
      .Default(spv::BuiltInMax);
}

SPIRVID SPIRVProducerPass::getOpExtInstImportID() {
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

SPIRVID SPIRVProducerPass::addSPIRVGlobalVariable(const SPIRVID &TypeID,
                                                  spv::StorageClass SC,
                                                  const SPIRVID &InitID) {
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

  if (SC == spv::StorageClassInput) {
    getEntryPointInterfacesList().push_back(VID);
  }

  return VID;
}

Type *SPIRVProducerPass::CanonicalType(Type *type) {
  if (type->getNumContainedTypes() != 0) {
    switch (type->getTypeID()) {
    case Type::PointerTyID: {
      // For the purposes of our Vulkan SPIR-V type system, constant and global
      // are conflated.
      auto *ptr_ty = cast<PointerType>(type);
      unsigned AddrSpace = ptr_ty->getAddressSpace();
      if (AddressSpace::Constant == AddrSpace) {
        if (!clspv::Option::ConstantArgsInUniformBuffer()) {
          AddrSpace = AddressSpace::Global;
          // The canonical type of __constant is __global unless constants are
          // passed in uniform buffers.
          auto *GlobalTy =
              ptr_ty->getPointerElementType()->getPointerTo(AddrSpace);
          return GlobalTy;
        }
      }
      break;
    }
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

SPIRVID SPIRVProducerPass::getSPIRVType(Type *Ty) {
  auto TI = TypeMap.find(Ty);
  if (TI != TypeMap.end()) {
    assert(TI->second.isValid());
    return TI->second;
  }

  auto Canonical = CanonicalType(Ty);
  if (Canonical != Ty) {
    auto CanonicalTI = TypeMap.find(Canonical);
    if (CanonicalTI != TypeMap.end()) {
      assert(CanonicalTI->second.isValid());
      return CanonicalTI->second;
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
    PointerType *PTy = cast<PointerType>(Canonical);
    unsigned AddrSpace = PTy->getAddressSpace();

    if (AddrSpace != AddressSpace::UniformConstant) {
      auto PointeeTy = PTy->getElementType();
      if (PointeeTy->isStructTy() &&
          dyn_cast<StructType>(PointeeTy)->isOpaque()) {
        // TODO(sjw): assert always an image?
        RID = getSPIRVType(PointeeTy);
        break;
      }
    }

    //
    // Generate OpTypePointer.
    //

    // OpTypePointer
    // Ops[0] = Storage Class
    // Ops[1] = Element Type ID
    SPIRVOperandVec Ops;

    Ops << GetStorageClass(AddrSpace) << PTy->getElementType();

    RID = addSPIRVInst<kTypes>(spv::OpTypePointer, Ops);
    break;
  }
  case Type::StructTyID: {
    StructType *STy = cast<StructType>(Canonical);

    // Handle sampler type.
    if (STy->isOpaque()) {
      if (STy->getName().equals("opencl.sampler_t")) {
        //
        // Generate OpTypeSampler
        //
        // Empty Ops.

        RID = addSPIRVInst<kTypes>(spv::OpTypeSampler);
        break;
      } else if (STy->getName().startswith("opencl.image1d_ro_t") ||
                 STy->getName().startswith("opencl.image1d_rw_t") ||
                 STy->getName().startswith("opencl.image1d_wo_t") ||
                 STy->getName().startswith("opencl.image1d_array_ro_t") ||
                 STy->getName().startswith("opencl.image1d_array_rw_t") ||
                 STy->getName().startswith("opencl.image1d_array_wo_t") ||
                 STy->getName().startswith("opencl.image2d_ro_t") ||
                 STy->getName().startswith("opencl.image2d_rw_t") ||
                 STy->getName().startswith("opencl.image2d_wo_t") ||
                 STy->getName().startswith("opencl.image2d_array_ro_t") ||
                 STy->getName().startswith("opencl.image2d_array_rw_t") ||
                 STy->getName().startswith("opencl.image2d_array_wo_t") ||
                 STy->getName().startswith("opencl.image3d_ro_t") ||
                 STy->getName().startswith("opencl.image3d_rw_t") ||
                 STy->getName().startswith("opencl.image3d_wo_t")) {
        if (STy->getName().startswith("opencl.image1d_")) {
          if (STy->getName().contains(".sampled"))
            addCapability(spv::CapabilitySampled1D);
          else
            addCapability(spv::CapabilityImage1D);
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
        if (STy->getName().contains(".float")) {
          SampledTyID = getSPIRVType(Type::getFloatTy(Canonical->getContext()));
        } else if (STy->getName().contains(".uint")) {
          SampledTyID = getSPIRVType(Type::getInt32Ty(Canonical->getContext()));
        } else if (STy->getName().contains(".int")) {
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
          SampledTyID = getSPIRVType(Type::getFloatTy(Canonical->getContext()));
        }
        Ops << SampledTyID;

        spv::Dim DimID = spv::Dim2D;
        if (STy->getName().startswith("opencl.image1d_ro_t") ||
            STy->getName().startswith("opencl.image1d_rw_t") ||
            STy->getName().startswith("opencl.image1d_wo_t") ||
            STy->getName().startswith("opencl.image1d_array_ro_t") ||
            STy->getName().startswith("opencl.image1d_array_rw_t") ||
            STy->getName().startswith("opencl.image1d_array_wo_t")) {
          DimID = spv::Dim1D;
        } else if (STy->getName().startswith("opencl.image3d_ro_t") ||
                   STy->getName().startswith("opencl.image3d_rw_t") ||
                   STy->getName().startswith("opencl.image3d_wo_t")) {
          DimID = spv::Dim3D;
        }
        Ops << DimID;

        // TODO: Set up Depth.
        Ops << 0;

        uint32_t arrayed = STy->getName().contains("_array_") ? 1 : 0;
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
        if (!STy->getName().contains(".sampled")) {
          Sampled = 2;
        }
        Ops << Sampled;

        // TODO: Set up Image Format.
        Ops << spv::ImageFormatUnknown;
        RID = addSPIRVInst<kTypes>(spv::OpTypeImage, Ops);

        // Only need a sampled version of the type if it is used with a sampler.
        if (Sampled == 1) {
          Ops.clear();
          Ops << RID;
          getImageTypeMap()[Canonical] =
              addSPIRVInst<kTypes>(spv::OpTypeSampledImage, Ops);
        }
        break;
      }
    }

    //
    // Generate OpTypeStruct
    //
    // Ops[0] ... Ops[n] = Member IDs
    SPIRVOperandVec Ops;

    for (auto *EleTy : STy->elements()) {
      Ops << EleTy;
    }

    RID = addSPIRVInst<kTypes>(spv::OpTypeStruct, Ops);

    // Generate OpMemberDecorate unless we are generating it for the canonical
    // type.
    StructType *canonical = cast<StructType>(CanonicalType(STy));
    if (TypesNeedingLayout.idFor(STy) &&
        (canonical == STy || !TypesNeedingLayout.idFor(canonical))) {
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
        (canonical == STy || !StructTypesNeedingBlock.idFor(canonical))) {
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
        RID = getSPIRVType(Type::getIntNTy(Canonical->getContext(), 32));
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
      Ops << EleTy;

      RID = addSPIRVInst<kTypes>(spv::OpTypeRuntimeArray, Ops);

      if (Hack_generate_runtime_array_stride_early) {
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

      // Remember to generate ArrayStride later
      getTypesNeedingArrayStride().insert(Canonical);

      //
      // Generate OpTypeArray.
      //
      // Ops[0] = Element Type ID
      // Ops[1] = Array Length Constant ID
      SPIRVOperandVec Ops;

      Ops << ArrTy->getElementType() << CstLength;

      RID = addSPIRVInst<kTypes>(spv::OpTypeArray, Ops);
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
      if (ParamTy->isPointerTy()) {
        auto PointeeTy = ParamTy->getPointerElementType();
        if (PointeeTy->isStructTy() &&
            dyn_cast<StructType>(PointeeTy)->isOpaque()) {
          ParamTy = PointeeTy;
        }
      }

      Ops << ParamTy;
    }

    RID = addSPIRVInst<kTypes>(spv::OpTypeFunction, Ops);
    break;
  }
  }

  if (RID.isValid()) {
    TypeMap[Canonical] = RID;
    if (Ty != Canonical) {
      // Speed up future lookups of this type by also caching the non-canonical
      // type.
      TypeMap[Ty] = RID;
    }
  }
  return RID;
}

void SPIRVProducerPass::GenerateSPIRVTypes() {
  for (Type *Ty : getTypeList()) {
    getSPIRVType(Ty);
  }
}

SPIRVID SPIRVProducerPass::getSPIRVInt32Constant(uint32_t CstVal) {
  Type *i32 = Type::getInt32Ty(module->getContext());
  Constant *Cst = ConstantInt::get(i32, CstVal);
  return getSPIRVValue(Cst);
}

SPIRVID SPIRVProducerPass::getSPIRVConstant(Constant *Cst) {
  ValueMapType &VMap = getValueMap();
  const bool hack_undef = clspv::Option::HackUndef();

  SPIRVID RID;

  //
  // Generate OpConstant.
  //
  // Ops[0] = Result Type ID
  // Ops[1] .. Ops[n] = Values LiteralNumber
  SPIRVOperandVec Ops;

  Ops << Cst->getType();

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
    Cst->print(errs());
    llvm_unreachable("Implement this Constant");

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
    } else {

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

SPIRVID SPIRVProducerPass::getSPIRVValue(Value *V) {
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

void SPIRVProducerPass::GenerateSamplers() {
  auto &sampler_map = getSamplerMap();
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
    //          i32 (index-into-sampler-map|sampler_mask))
    if (auto *call = dyn_cast<CallInst>(user)) {
      const auto third_param = static_cast<unsigned>(
          dyn_cast<ConstantInt>(call->getArgOperand(2))->getZExtValue());
      auto sampler_value = third_param;
      if (clspv::Option::UseSamplerMap()) {
        if (third_param >= sampler_map.size()) {
          errs() << "Out of bounds index to sampler map: " << third_param;
          llvm_unreachable("bad sampler init: out of bounds");
        }
        sampler_value = sampler_map[third_param].first;
      }

      const auto descriptor_set = static_cast<unsigned>(
          dyn_cast<ConstantInt>(call->getArgOperand(0))->getZExtValue());
      const auto binding = static_cast<unsigned>(
          dyn_cast<ConstantInt>(call->getArgOperand(1))->getZExtValue());

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
    const unsigned third_param = static_cast<unsigned>(
        dyn_cast<ConstantInt>(call->getArgOperand(2))->getZExtValue());

    // Already allocated a variable for this value.
    if (!seen.insert(third_param).second)
      continue;

    auto sampler_value = third_param;
    if (clspv::Option::UseSamplerMap()) {
      sampler_value = sampler_map[third_param].first;
    }

    auto sampler_var_id = addSPIRVGlobalVariable(
        getSPIRVType(SamplerTy), spv::StorageClassUniformConstant);

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

void SPIRVProducerPass::GenerateResourceVars() {
  ValueMapType &VMap = getValueMap();

  // Generate variables.  Make one for each of resource var info object.
  for (auto *info : ModuleOrderedResourceVars) {
    Type *type = info->var_fn->getReturnType();
    // Remap the address space for opaque types.
    switch (info->arg_kind) {
    case clspv::ArgKind::Sampler:
    case clspv::ArgKind::SampledImage:
    case clspv::ArgKind::StorageImage:
      type = PointerType::get(type->getPointerElementType(),
                              clspv::AddressSpace::UniformConstant);
      break;
    default:
      break;
    }

    const auto sc = GetStorageClassForArgKind(info->arg_kind);

    info->var_id = addSPIRVGlobalVariable(getSPIRVType(type), sc);

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
      auto *type = info->var_fn->getReturnType();
      auto *struct_ty = cast<StructType>(type->getPointerElementType());
      // TODO(alan-baker): This is conservative. If compiling for OpenCL 2.0 or
      // above, the compiler treats all write_only images as read_write images.
      if (struct_ty->getName().contains("_wo_t")) {
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

void SPIRVProducerPass::GenerateGlobalVar(GlobalVariable &GV) {
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

        Ops << Ty->getPointerElementType() << XDimCstID << YDimCstID
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
          dyn_cast<VectorType>(Ty->getPointerElementType())->getElementType());

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
      Ops << Ty->getPointerElementType() << XDimCstID << YDimCstID << ZDimCstID;

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
    Ops << GV.getType()->getPointerElementType() << x_id << y_id << z_id;
    InitializerID = addSPIRVInst<kConstants>(spv::OpSpecConstantComposite, Ops);
  }

  const auto AS = PTy->getAddressSpace();
  const auto spvSC = GetStorageClass(AS);

  const bool module_scope_constant_external_init =
      (AS == AddressSpace::Constant) && GV.hasInitializer() &&
      clspv::Option::ModuleConstantsInStorageBuffer();

  if (GV.hasInitializer()) {
    auto GVInit = GV.getInitializer();
    if (!isa<UndefValue>(GVInit) && !module_scope_constant_external_init) {
      InitializerID = getSPIRVValue(GVInit);
    }
  }

  SPIRVID var_id =
      addSPIRVGlobalVariable(getSPIRVType(Ty), spvSC, InitializerID);

  VMap[&GV] = var_id;

  auto IsOpenCLBuiltin = [](spv::BuiltIn builtin) {
    return builtin == spv::BuiltInWorkDim ||
           builtin == spv::BuiltInGlobalOffset;
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
    // This module scope constant is initialized from a storage buffer with data
    // provided by the host at binding 0 of the next descriptor set.
    const uint32_t descriptor_set = TakeDescriptorIndex(module);

    // Emit the intializer as a reflection instruction.
    // Use "kind,buffer" to indicate storage buffer. We might want to expand
    // that later to other types, like uniform buffer.
    std::string hexbytes;
    llvm::raw_string_ostream str(hexbytes);
    clspv::ConstantEmitter(DL, str).Emit(GV.getInitializer());

    // Reflection instruction for constant data.
    SPIRVOperandVec Ops;
    auto data_id = addSPIRVInst<kDebug>(spv::OpString, str.str().c_str());
    Ops << getSPIRVType(Type::getVoidTy(module->getContext()))
        << getReflectionImport() << reflection::ExtInstConstantDataStorageBuffer
        << getSPIRVInt32Constant(descriptor_set) << getSPIRVInt32Constant(0)
        << data_id;
    addSPIRVInst<kReflection>(spv::OpExtInst, Ops);

    // OpDecorate %var DescriptorSet <descriptor_set>
    Ops.clear();
    Ops << var_id << spv::DecorationDescriptorSet << descriptor_set;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);

    // OpDecorate %var Binding <binding>
    Ops.clear();
    Ops << var_id << spv::DecorationBinding << 0;
    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }
}

void SPIRVProducerPass::GenerateFuncPrologue(Function &F) {
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
  SPIRVOperandVec FOps;

  // Find SPIRV instruction for return type.
  FOps << FTy->getReturnType();

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

  FOps << FuncControl;

  SPIRVID FTyID;
  if (F.getCallingConv() == CallingConv::SPIR_KERNEL) {
    SmallVector<Type *, 4> NewFuncParamTys;
    FunctionType *NewFTy =
        FunctionType::get(FTy->getReturnType(), NewFuncParamTys, false);
    FTyID = getSPIRVType(NewFTy);
  } else {
    // Handle regular function with global constant parameters.
    if (GlobalConstFuncTyMap.count(FTy)) {
      FTyID = getSPIRVType(GlobalConstFuncTyMap[FTy].first);
    } else {
      FTyID = getSPIRVType(FTy);
    }
  }

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
      SPIRVID ParamTyID = getSPIRVType(Arg.getType());
      if (PointerType *PTy = dyn_cast<PointerType>(Arg.getType())) {
        if (GlobalConstFuncTyMap.count(FTy)) {
          if (ArgIdx == GlobalConstFuncTyMap[FTy].second) {
            Type *EleTy = PTy->getPointerElementType();
            Type *ArgTy =
                PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);
            ParamTyID = getSPIRVType(ArgTy);
            GlobalConstArgSet.insert(&Arg);
          }
        }
      }
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

      ArgIdx++;
    }
  }
}

void SPIRVProducerPass::GenerateModuleInfo() {
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

  // Always add the storage buffer extension
  {
    //
    // Generate OpExtension.
    //
    // Ops[0] = Name (Literal String)
    //
    addSPIRVInst<kExtensions>(spv::OpExtension,
                              "SPV_KHR_storage_buffer_storage_class");
  }

  if (hasVariablePointers() || hasVariablePointersStorageBuffer()) {
    //
    // Generate OpExtension.
    //
    // Ops[0] = Name (Literal String)
    //
    addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_KHR_variable_pointers");
  }

  //
  // Generate OpMemoryModel
  //
  // Memory model for Vulkan will always be GLSL450.

  // Ops[0] = Addressing Model
  // Ops[1] = Memory Model
  Ops.clear();
  Ops << spv::AddressingModelLogical << spv::MemoryModelGLSL450;

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

void SPIRVProducerPass::GenerateEntryPointInitialStores() {
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

void SPIRVProducerPass::GenerateFuncBody(Function &F) {
  ValueMapType &VMap = getValueMap();

  const bool IsKernel = F.getCallingConv() == CallingConv::SPIR_KERNEL;

  for (BasicBlock &BB : F) {
    // Register BasicBlock to ValueMap.

    //
    // Generate OpLabel for Basic Block.
    //
    VMap[&BB] = addSPIRVInst(spv::OpLabel);

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

SPIRVID SPIRVProducerPass::getSPIRVBuiltin(spv::BuiltIn BID,
                                           spv::Capability Cap) {
  SPIRVID RID;

  auto ii = BuiltinConstantMap.find(BID);

  if (ii != BuiltinConstantMap.end()) {
    return ii->second;
  } else {
    addCapability(Cap);

    Type *type = PointerType::get(IntegerType::get(module->getContext(), 32),
                                  AddressSpace::Input);

    RID = addSPIRVGlobalVariable(getSPIRVType(type), spv::StorageClassInput);

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
SPIRVProducerPass::GenerateClspvInstruction(CallInst *Call,
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

      Ops << Call->getType()->getPointerElementType()
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
        cast<ConstantInt>(Call->getOperand(0))->getSExtValue());
    const auto &info = LocalSpecIdInfoMap[spec_id];
    RID = info.variable_id;
    break;
  }
  case Builtins::kClspvSamplerVarLiteral: {
    // Sampler initializers become a load of the corresponding sampler.
    // Map this to a load from the variable.
    const auto third_param = static_cast<unsigned>(
        dyn_cast<ConstantInt>(Call->getArgOperand(2))->getZExtValue());
    auto sampler_value = third_param;
    if (clspv::Option::UseSamplerMap()) {
      sampler_value = getSamplerMap()[third_param].first;
    }

    // Generate an OpLoad
    SPIRVOperandVec Ops;

    Ops << SamplerTy->getPointerElementType()
        << SamplerLiteralToIDMap[sampler_value];

    RID = addSPIRVInst(spv::OpLoad, Ops);
    break;
  }
  case Builtins::kSpirvAtomicXor: {
    // Handle SPIR-V intrinsics
    SPIRVOperandVec Ops;

    if (!Call->getType()->isVoidTy()) {
      Ops << Call->getType();
    }

    for (unsigned i = 0; i < Call->getNumArgOperands(); i++) {
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

      for (unsigned i = 1; i < Call->getNumArgOperands(); i++) {
        Ops << Call->getArgOperand(i);
      }

      RID = addSPIRVInst(opcode, Ops);
    }
    break;
  }
  case Builtins::kSpirvCopyMemory: {
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

    SPIRVOperandVec Ops;
    Ops << Call->getArgOperand(0) << Call->getArgOperand(1) << MemoryAccess
        << static_cast<uint32_t>(Alignment);

    RID = addSPIRVInst(spv::OpCopyMemory, Ops);
    break;
  }
  default:
    llvm_unreachable("Unknown CLSPV Instruction");
    break;
  }
  return RID;
}

SPIRVID
SPIRVProducerPass::GenerateImageInstruction(CallInst *Call,
                                            const FunctionInfo &FuncInfo) {
  SPIRVID RID;

  LLVMContext &Context = module->getContext();
  switch (FuncInfo.getType()) {
  case Builtins::kReadImagef:
  case Builtins::kReadImageh:
  case Builtins::kReadImagei:
  case Builtins::kReadImageui: {
    // read_image is converted to OpSampledImage and OpImageSampleExplicitLod.
    // Additionally, OpTypeSampledImage is generated.
    const auto image_ty = Call->getArgOperand(0)->getType();
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
      Type *ImageTy = Image->getType()->getPointerElementType();
      SPIRVID ImageTyID = OpImageTypeMap[ImageTy];

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

      const bool is_int_image = IsIntImageType(Image->getType());
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }

      Constant *CstFP0 = ConstantFP::get(Context, APFloat(0.0f));
      Ops << result_type << SampledImageID << Coordinate
          << spv::ImageOperandsLodMask << CstFP0;

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

      const bool is_int_image = IsIntImageType(Image->getType());
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }

      Ops << result_type << Image << Coordinate;
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

      const bool is_int_image = IsIntImageType(Image->getType());
      SPIRVID result_type;
      if (is_int_image) {
        result_type = v4int32ID;
      } else {
        result_type = getSPIRVType(Call->getType());
      }

      Ops << result_type << Image << Coordinate << spv::ImageOperandsLodMask
          << getSPIRVInt32Constant(0);

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

    const bool is_int_image = IsIntImageType(Image->getType());
    if (is_int_image) {
      // Generate a bitcast to v4int and use it as the texel value.
      Ops << v4int32ID << TexelID;
      TexelID = addSPIRVInst(spv::OpBitcast, Ops);
      Ops.clear();
    }
    Ops << Image << Coordinate << TexelID;
    RID = addSPIRVInst(spv::OpImageWrite, Ops);

    // Image writes require StorageImageWriteWithoutFormat.
    addCapability(spv::CapabilityStorageImageWriteWithoutFormat);
    break;
  }

  case Builtins::kGetImageHeight:
  case Builtins::kGetImageWidth:
  case Builtins::kGetImageDepth:
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
    const uint32_t dim = ImageDimensionality(Image->getType());
    const uint32_t components =
        dim + (IsArrayImageType(Image->getType()) ? 1 : 0);
    if (components == 1) {
      SizesTypeID = getSPIRVType(Type::getInt32Ty(Context));
    } else {
      SizesTypeID = getSPIRVType(
          FixedVectorType::get(Type::getInt32Ty(Context), components));
    }
    Ops << SizesTypeID << Image;
    spv::Op query_opcode = spv::OpImageQuerySize;
    if (IsSampledImageType(Image->getType())) {
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
      Ops << Call->getType() << RID;

      uint32_t component = 0;
      if (FuncInfo.getType() == Builtins::kGetImageHeight)
        component = 1;
      else if (FuncInfo.getType() == Builtins::kGetImageDepth)
        component = 2;
      Ops << component;

      RID = addSPIRVInst(spv::OpCompositeExtract, Ops);
    }
    break;
  }
  default:
    llvm_unreachable("Unsupported Image builtin");
  }

  return RID;
}

SPIRVID
SPIRVProducerPass::GenerateSubgroupInstruction(CallInst *Call,
                                               const FunctionInfo &FuncInfo) {
  SPIRVID RID;

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
    // TODO(sjw): requires CapabilityKernel (incompatible with Shader)
  case Builtins::kGetMaxSubGroupSize:
    // TODO(sjw): use SpecConstant, capability Kernel (incompatible with Shader)
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
  Operands << Call->getType();

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

  for (Use &use : Call->arg_operands()) {
    Operands << use.get();
  }

  return addSPIRVInst(op, Operands);
}

SPIRVID SPIRVProducerPass::GenerateInstructionFromCall(CallInst *Call) {
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

  switch (func_type) {
  case Builtins::kPopcount: {
    //
    // Generate OpBitCount
    //
    // Ops[0] = Result Type ID
    // Ops[1] = Base ID
    SPIRVOperandVec Ops;
    Ops << Call->getType() << Call->getOperand(0);

    RID = addSPIRVInst(spv::OpBitCount, Ops);
    break;
  }
  default: {
    glsl::ExtInst EInst = getDirectOrIndirectExtInstEnum(func_info);

    if (EInst) {
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

      for (auto &use : Call->arg_operands()) {
        Ops << use.get();
      }

      RID = addSPIRVInst(spv::OpExtInst, Ops);

      const auto IndirectExtInst = getIndirectExtInstEnum(func_info);
      if (IndirectExtInst != kGlslExtInstBad) {
        // Generate one more instruction that uses the result of the extended
        // instruction.  Its result id is one more than the id of the
        // extended instruction.
        auto generate_extra_inst = [this, &Context, &Call,
                                    &RID](spv::Op opcode, Constant *constant) {
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

        auto bitwidth = Call->getType()->getScalarSizeInBits();
        switch (IndirectExtInst) {
        case glsl::ExtInstFindUMsb: // Implementing clz
          generate_extra_inst(
              spv::OpISub,
              ConstantInt::get(Call->getType()->getScalarType(), bitwidth - 1));
          break;
        case glsl::ExtInstFindILsb: { // Implementing ctz
          auto neg_one = Constant::getAllOnesValue(Call->getType());
          Constant *int_32 =
              ConstantInt::get(Call->getType()->getScalarType(), 32);
          Type *i1_ty = Type::getInt1Ty(Call->getContext());
          if (auto vec_ty = dyn_cast<VectorType>(Call->getType())) {
            i1_ty = VectorType::get(i1_ty, vec_ty->getElementCount());
            int_32 =
                ConstantVector::getSplat(vec_ty->getElementCount(), int_32);
          }

          SPIRVOperandVec local_ops;
          local_ops << i1_ty << RID << neg_one;
          auto cmp = addSPIRVInst(spv::OpIEqual, local_ops);
          local_ops.clear();
          local_ops << Call->getType() << cmp << int_32 << RID;
          RID = addSPIRVInst(spv::OpSelect, local_ops);
          break;
        }
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
      // A real function call (not builtin)
      // Call instruction is deferred because it needs function's ID.
      RID = addSPIRVPlaceholder(Call);
    }

    break;
  }
  }

  return RID;
}

void SPIRVProducerPass::GenerateInstruction(Instruction &I) {
  ValueMapType &VMap = getValueMap();
  LLVMContext &Context = module->getContext();

  SPIRVID RID;

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
        SPIRVOperandVec Ops;

        Ops << I.getType() << I.getOperand(0);

        if (I.getOpcode() == Instruction::ZExt) {
          Ops << ConstantInt::get(I.getType(), 1);
        } else if (I.getOpcode() == Instruction::SExt) {
          Ops << ConstantInt::getSigned(I.getType(), -1);
        } else {
          Ops << ConstantFP::get(I.getType(), 1.0);
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
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Source Value ID
        SPIRVOperandVec Ops;

        Ops << I.getType() << I.getOperand(0);

        RID = addSPIRVInst(GetSPIRVCastOpcode(I), Ops);
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
      } else {
        // Ops[0] = Result Type ID
        // Ops[1] = Operand 0
        // Ops[2] = Operand 1
        SPIRVOperandVec Ops;

        Ops << I.getType() << I.getOperand(0) << I.getOperand(1);

        RID = addSPIRVInst(GetSPIRVBinaryOpcode(I), Ops);
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
      Type *EleTy = I.getType()->getPointerElementType();
      ResultType = PointerType::get(EleTy, AddressSpace::ModuleScopePrivate);
    }

    Ops << ResultType;

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
        // Save the need to generate an ArrayStride decoration.  But defer
        // generation until later, so we only make one decoration.
        getTypesNeedingArrayStride().insert(GEP->getPointerOperandType());
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
      auto PointeeTy = Ty->getPointerElementType();
      if (PointeeTy->isStructTy() &&
          dyn_cast<StructType>(PointeeTy)->isOpaque()) {
        Ty = PointeeTy;
      } else {
        // Selecting between pointers requires variable pointers.
        setVariablePointersCapabilities(Ty->getPointerAddressSpace());
        if (!hasVariablePointers() && !selectFromSameObject(&I)) {
          setVariablePointers();
        }
      }
    }

    Ops << Ty << I.getOperand(0) << I.getOperand(1) << I.getOperand(2);

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

    Ops << I.getType() << I.getOperand(0) << I.getOperand(1);

    auto shuffle = cast<ShuffleVectorInst>(&I);
    SmallVector<int, 4> mask;
    shuffle->getShuffleMask(mask);
    for (auto i : mask) {
      if (i == UndefMaskElem) {
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
    break;
  }
  case Instruction::ICmp:
  case Instruction::FCmp: {
    CmpInst *CmpI = cast<CmpInst>(&I);

    // Pointer equality is invalid.
    Type *ArgTy = CmpI->getOperand(0)->getType();
    if (isa<PointerType>(ArgTy)) {
      CmpI->print(errs());
      std::string name = I.getParent()->getParent()->getName().str();
      errs()
          << "\nPointer equality test is not supported by SPIR-V for Vulkan, "
          << "in function " << name << "\n";
      llvm_unreachable("Pointer equality check is invalid");
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

    Ops << I.getType() << spv::StorageClassFunction;

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

    SPIRVOperandVec Ops;
    Ops << LD->getType() << LD->getPointerOperand();

    RID = addSPIRVInst(spv::OpLoad, Ops);
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
    SPIRVOperandVec Ops;
    Ops << ST->getPointerOperand() << ST->getValueOperand();

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

void SPIRVProducerPass::GenerateFuncEpilogue() {
  //
  // Generate OpFunctionEnd
  //
  addSPIRVInst(spv::OpFunctionEnd);
}

bool SPIRVProducerPass::is4xi8vec(Type *Ty) const {
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

void SPIRVProducerPass::HandleDeferredInstruction() {
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
      if (PHI->getType()->isPointerTy() && !IsSamplerType(PHI->getType()) &&
          !IsImageType(PHI->getType())) {
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

      Ops << PHI->getType();

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

        for (Use &use : Call->arg_operands()) {
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

        Ops << Call->getType();

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
          // Images and samplers can be passed as function parameters without
          // variable pointers.
          if (operand_type->isPointerTy() && !IsImageType(operand_type) &&
              !IsSamplerType(operand_type)) {
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

void SPIRVProducerPass::HandleDeferredDecorations() {
  const auto &DL = module->getDataLayout();
  if (getTypesNeedingArrayStride().empty()) {
    return;
  }

  // Insert ArrayStride decorations on pointer types, due to OpPtrAccessChain
  // instructions we generated earlier.
  DenseSet<uint32_t> seen;
  for (auto *type : getTypesNeedingArrayStride()) {
    auto id = getSPIRVType(type);
    if (!seen.insert(id.get()).second)
      continue;

    Type *elemTy = nullptr;
    if (auto *ptrTy = dyn_cast<PointerType>(type)) {
      elemTy = ptrTy->getElementType();
    } else if (auto *arrayTy = dyn_cast<ArrayType>(type)) {
      elemTy = arrayTy->getElementType();
    } else if (auto *vecTy = dyn_cast<VectorType>(type)) {
      elemTy = vecTy->getElementType();
    } else {
      errs() << "Unhandled strided type " << *type << "\n";
      llvm_unreachable("Unhandled strided type");
    }

    // Ops[0] = Target ID
    // Ops[1] = Decoration (ArrayStride)
    // Ops[2] = Stride number (Literal Number)
    SPIRVOperandVec Ops;

    // Same as DL.getIndexedOffsetInType( elemTy, { 1 } );
    const uint32_t stride = static_cast<uint32_t>(GetTypeAllocSize(elemTy, DL));

    Ops << id << spv::DecorationArrayStride << stride;

    addSPIRVInst<kAnnotations>(spv::OpDecorate, Ops);
  }
}

glsl::ExtInst
SPIRVProducerPass::getExtInstEnum(const Builtins::FunctionInfo &func_info) {
  switch (func_info.getType()) {
  case Builtins::kClamp: {
    auto param_type = func_info.getParameter(0);
    if (param_type.type_id == Type::FloatTyID) {
      return glsl::ExtInst::ExtInstFClamp;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSClamp
                                : glsl::ExtInst::ExtInstUClamp;
  }
  case Builtins::kMax: {
    auto param_type = func_info.getParameter(0);
    if (param_type.type_id == Type::FloatTyID) {
      return glsl::ExtInst::ExtInstFMax;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSMax
                                : glsl::ExtInst::ExtInstUMax;
  }
  case Builtins::kMin: {
    auto param_type = func_info.getParameter(0);
    if (param_type.type_id == Type::FloatTyID) {
      return glsl::ExtInst::ExtInstFMin;
    }
    return param_type.is_signed ? glsl::ExtInst::ExtInstSMin
                                : glsl::ExtInst::ExtInstUMin;
  }
  case Builtins::kAbs:
    return glsl::ExtInst::ExtInstSAbs;
  case Builtins::kFmax:
    return glsl::ExtInst::ExtInstNMax;
  case Builtins::kFmin:
    return glsl::ExtInst::ExtInstNMin;
  case Builtins::kDegrees:
    return glsl::ExtInst::ExtInstDegrees;
  case Builtins::kRadians:
    return glsl::ExtInst::ExtInstRadians;
  case Builtins::kMix:
    return glsl::ExtInst::ExtInstFMix;
  case Builtins::kAcos:
  case Builtins::kAcospi:
    return glsl::ExtInst::ExtInstAcos;
  case Builtins::kAcosh:
    return glsl::ExtInst::ExtInstAcosh;
  case Builtins::kAsin:
  case Builtins::kAsinpi:
    return glsl::ExtInst::ExtInstAsin;
  case Builtins::kAsinh:
    return glsl::ExtInst::ExtInstAsinh;
  case Builtins::kAtan:
  case Builtins::kAtanpi:
    return glsl::ExtInst::ExtInstAtan;
  case Builtins::kAtanh:
    return glsl::ExtInst::ExtInstAtanh;
  case Builtins::kAtan2:
  case Builtins::kAtan2pi:
    return glsl::ExtInst::ExtInstAtan2;
  case Builtins::kCeil:
    return glsl::ExtInst::ExtInstCeil;
  case Builtins::kSin:
  case Builtins::kHalfSin:
  case Builtins::kNativeSin:
    return glsl::ExtInst::ExtInstSin;
  case Builtins::kSinh:
    return glsl::ExtInst::ExtInstSinh;
  case Builtins::kCos:
  case Builtins::kHalfCos:
  case Builtins::kNativeCos:
    return glsl::ExtInst::ExtInstCos;
  case Builtins::kCosh:
    return glsl::ExtInst::ExtInstCosh;
  case Builtins::kTan:
  case Builtins::kHalfTan:
  case Builtins::kNativeTan:
    return glsl::ExtInst::ExtInstTan;
  case Builtins::kTanh:
    return glsl::ExtInst::ExtInstTanh;
  case Builtins::kExp:
  case Builtins::kHalfExp:
  case Builtins::kNativeExp:
    return glsl::ExtInst::ExtInstExp;
  case Builtins::kExp2:
  case Builtins::kHalfExp2:
  case Builtins::kNativeExp2:
    return glsl::ExtInst::ExtInstExp2;
  case Builtins::kLog:
  case Builtins::kHalfLog:
  case Builtins::kNativeLog:
    return glsl::ExtInst::ExtInstLog;
  case Builtins::kLog2:
  case Builtins::kHalfLog2:
  case Builtins::kNativeLog2:
    return glsl::ExtInst::ExtInstLog2;
  case Builtins::kFabs:
    return glsl::ExtInst::ExtInstFAbs;
  case Builtins::kFma:
    return glsl::ExtInst::ExtInstFma;
  case Builtins::kFloor:
    return glsl::ExtInst::ExtInstFloor;
  case Builtins::kLdexp:
    return glsl::ExtInst::ExtInstLdexp;
  case Builtins::kPow:
  case Builtins::kPowr:
  case Builtins::kHalfPowr:
  case Builtins::kNativePowr:
    return glsl::ExtInst::ExtInstPow;
  case Builtins::kRint:
    return glsl::ExtInst::ExtInstRoundEven;
  case Builtins::kRound:
    return glsl::ExtInst::ExtInstRound;
  case Builtins::kSqrt:
  case Builtins::kHalfSqrt:
  case Builtins::kNativeSqrt:
    return glsl::ExtInst::ExtInstSqrt;
  case Builtins::kRsqrt:
  case Builtins::kHalfRsqrt:
  case Builtins::kNativeRsqrt:
    return glsl::ExtInst::ExtInstInverseSqrt;
  case Builtins::kTrunc:
    return glsl::ExtInst::ExtInstTrunc;
  case Builtins::kFrexp:
    return glsl::ExtInst::ExtInstFrexp;
  case Builtins::kClspvFract:
  case Builtins::kFract:
    return glsl::ExtInst::ExtInstFract;
  case Builtins::kSign:
    return glsl::ExtInst::ExtInstFSign;
  case Builtins::kLength:
  case Builtins::kFastLength:
    return glsl::ExtInst::ExtInstLength;
  case Builtins::kDistance:
  case Builtins::kFastDistance:
    return glsl::ExtInst::ExtInstDistance;
  case Builtins::kStep:
    return glsl::ExtInst::ExtInstStep;
  case Builtins::kSmoothstep:
    return glsl::ExtInst::ExtInstSmoothStep;
  case Builtins::kCross:
    return glsl::ExtInst::ExtInstCross;
  case Builtins::kNormalize:
  case Builtins::kFastNormalize:
    return glsl::ExtInst::ExtInstNormalize;
  case Builtins::kSpirvPack:
    return glsl::ExtInst::ExtInstPackHalf2x16;
  case Builtins::kSpirvUnpack:
    return glsl::ExtInst::ExtInstUnpackHalf2x16;
  default:
    break;
  }

  if (func_info.getName().find("llvm.fmuladd.") == 0) {
    return glsl::ExtInst::ExtInstFma;
  }
  return kGlslExtInstBad;
}

glsl::ExtInst SPIRVProducerPass::getIndirectExtInstEnum(
    const Builtins::FunctionInfo &func_info) {
  switch (func_info.getType()) {
  case Builtins::kClz:
    return glsl::ExtInst::ExtInstFindUMsb;
  case Builtins::kCtz:
    return glsl::ExtInst::ExtInstFindILsb;
  case Builtins::kAcospi:
    return glsl::ExtInst::ExtInstAcos;
  case Builtins::kAsinpi:
    return glsl::ExtInst::ExtInstAsin;
  case Builtins::kAtanpi:
    return glsl::ExtInst::ExtInstAtan;
  case Builtins::kAtan2pi:
    return glsl::ExtInst::ExtInstAtan2;
  default:
    break;
  }
  return kGlslExtInstBad;
}

glsl::ExtInst SPIRVProducerPass::getDirectOrIndirectExtInstEnum(
    const Builtins::FunctionInfo &func_info) {
  auto direct = getExtInstEnum(func_info);
  if (direct != kGlslExtInstBad)
    return direct;
  return getIndirectExtInstEnum(func_info);
}

void SPIRVProducerPass::WriteOneWord(uint32_t Word) {
  binaryOut->write(reinterpret_cast<const char *>(&Word), sizeof(uint32_t));
}

void SPIRVProducerPass::WriteResultID(const SPIRVInstruction &Inst) {
  WriteOneWord(Inst.getResultID().get());
}

void SPIRVProducerPass::WriteWordCountAndOpcode(const SPIRVInstruction &Inst) {
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

void SPIRVProducerPass::WriteOperand(const SPIRVOperand &Op) {
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

void SPIRVProducerPass::WriteSPIRVBinary() {
  for (int i = 0; i < kSectionCount; ++i) {
    WriteSPIRVBinary(SPIRVSections[i]);
  }
}

void SPIRVProducerPass::WriteSPIRVBinary(SPIRVInstructionList &SPIRVInstList) {
  for (const auto &Inst : SPIRVInstList) {
    const auto &Ops = Inst.getOperands();
    spv::Op Opcode = static_cast<spv::Op>(Inst.getOpcode());

    switch (Opcode) {
    default: {
      errs() << "Unsupported SPIR-V instruction opcode " << int(Opcode) << "\n";
      llvm_unreachable("Unsupported SPIRV instruction");
      break;
    }
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

bool SPIRVProducerPass::IsTypeNullable(const Type *type) const {
  switch (type->getTypeID()) {
  case Type::HalfTyID:
  case Type::FloatTyID:
  case Type::DoubleTyID:
  case Type::IntegerTyID:
  case Type::FixedVectorTyID:
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

void SPIRVProducerPass::PopulateUBOTypeMaps() {
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

uint32_t SPIRVProducerPass::GetExplicitLayoutStructMemberOffset(
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

void SPIRVProducerPass::setVariablePointersCapabilities(
    unsigned address_space) {
  if (GetStorageClass(address_space) == spv::StorageClassStorageBuffer) {
    setVariablePointersStorageBuffer();
  } else {
    setVariablePointers();
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
      const auto &lhs_func_info =
          Builtins::Lookup(lhs_call->getCalledFunction());
      const auto &rhs_func_info =
          Builtins::Lookup(rhs_call->getCalledFunction());
      if (lhs_func_info.getType() == Builtins::kClspvResource &&
          rhs_func_info.getType() == Builtins::kClspvResource) {
        // For resource accessors, match descriptor set and binding.
        if (lhs_call->getOperand(0) == rhs_call->getOperand(0) &&
            lhs_call->getOperand(1) == rhs_call->getOperand(1))
          return true;
      } else if (lhs_func_info.getType() == Builtins::kClspvLocal &&
                 rhs_func_info.getType() == Builtins::kClspvLocal) {
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
        Builtins::Lookup(resource_call->getCalledFunction()).getType() ==
            Builtins::kClspvResource) {
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

void SPIRVProducerPass::PopulateStructuredCFGMaps() {
  // First, track loop merges and continues.
  DenseSet<BasicBlock *> LoopMergesAndContinues;
  for (auto &F : *module) {
    if (F.isDeclaration())
      continue;

    DominatorTree &DT = getAnalysis<DominatorTreeWrapperPass>(F).getDomTree();
    const LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>(F).getLoopInfo();
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

SPIRVID SPIRVProducerPass::getReflectionImport() {
  if (!ReflectionID.isValid()) {
    addSPIRVInst<kExtensions>(spv::OpExtension, "SPV_KHR_non_semantic_info");
    ReflectionID = addSPIRVInst<kImports>(spv::OpExtInstImport,
                                          "NonSemantic.ClspvReflection.1");
  }
  return ReflectionID;
}

void SPIRVProducerPass::GenerateReflection() {
  GenerateKernelReflection();
  GeneratePushConstantReflection();
  GenerateSpecConstantReflection();
}

void SPIRVProducerPass::GeneratePushConstantReflection() {
  if (auto GV = module->getGlobalVariable(clspv::PushConstantsVariableName())) {
    auto const &DL = module->getDataLayout();
    auto MD = GV->getMetadata(clspv::PushConstantsMetadataName());
    auto STy = cast<StructType>(GV->getValueType());

    for (unsigned i = 0; i < STy->getNumElements(); i++) {
      auto pc = static_cast<clspv::PushConstant>(
          mdconst::extract<ConstantInt>(MD->getOperand(i))->getZExtValue());
      if (pc == PushConstant::KernelArgument)
        continue;

      auto memberType = STy->getElementType(i);
      auto offset = GetExplicitLayoutStructMemberOffset(STy, i, DL);
      unsigned previousOffset = 0;
      if (i > 0) {
        previousOffset = GetExplicitLayoutStructMemberOffset(STy, i - 1, DL);
      }
      auto size = static_cast<uint32_t>(GetTypeSizeInBits(memberType, DL)) / 8;
      assert(isValidExplicitLayout(*module, STy, i,
                                   spv::StorageClassPushConstant, offset,
                                   previousOffset));

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
      default:
        llvm_unreachable("Unhandled push constant");
        break;
      }

      auto import_id = getReflectionImport();
      SPIRVOperandVec Ops;
      Ops << getSPIRVType(Type::getVoidTy(module->getContext())) << import_id
          << pc_inst << getSPIRVInt32Constant(offset)
          << getSPIRVInt32Constant(size);
      addSPIRVInst(spv::OpExtInst, Ops);
    }
  }
}

void SPIRVProducerPass::GenerateSpecConstantReflection() {
  const uint32_t kMax = std::numeric_limits<uint32_t>::max();
  uint32_t wgsize_id[3] = {kMax, kMax, kMax};
  uint32_t global_offset_id[3] = {kMax, kMax, kMax};
  uint32_t work_dim_id = kMax;
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
}

void SPIRVProducerPass::GenerateKernelReflection() {
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

    // Kernel declaration
    // Ops[0] = void type
    // Ops[1] = reflection ext import
    // Ops[2] = function id
    // Ops[3] = kernel name
    SPIRVOperandVec Ops;
    Ops << void_id << import_id << reflection::ExtInstKernel << ValueMap[&F]
        << kernel_name;
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
    auto *func_ty = F.getFunctionType();

    // If we've clustered POD arguments, then argument details are in metadata.
    // If an argument maps to a resource variable, then get descriptor set and
    // binding from the resource variable.  Other info comes from the metadata.
    const auto *arg_map = F.getMetadata(clspv::KernelArgMapMetadataName());
    auto local_spec_id_md =
        module->getNamedMetadata(clspv::LocalSpecIdMetadataName());
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

        // If this is a local memory argument, find the right spec id for this
        // argument.
        int64_t spec_id = -1;
        if (argKind == clspv::ArgKind::Local) {
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
        const uint32_t arg_offset = static_cast<uint32_t>(offset);
        const uint32_t arg_size = static_cast<uint32_t>(size);
        uint32_t elem_size = 0;
        uint32_t descriptor_set = 0;
        uint32_t binding = 0;
        if (spec_id > 0) {
          elem_size = static_cast<uint32_t>(
              GetTypeAllocSize(func_ty->getParamType(unsigned(new_index))
                                   ->getPointerElementType(),
                               DL));
        } else if (new_index >= 0) {
          auto *info = resource_var_at_index[new_index];
          assert(info);
          descriptor_set = info->descriptor_set;
          binding = info->binding;
        }
        AddArgumentReflection(kernel_decl, name.str(), argKind, ordinal,
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
          AddArgumentReflection(kernel_decl, arg->getName().str(),
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
          AddArgumentReflection(kernel_decl, arg->getName().str(),
                                ArgKind::Local, arg_index, 0, 0, 0, 0,
                                static_cast<uint32_t>(local_arg_info.spec_id),
                                static_cast<uint32_t>(GetTypeAllocSize(
                                    local_arg_info.elem_type, DL)));
        }
      }
    }
  }
}

void SPIRVProducerPass::AddArgumentReflection(
    SPIRVID kernel_decl, const std::string &name, clspv::ArgKind arg_kind,
    uint32_t ordinal, uint32_t descriptor_set, uint32_t binding,
    uint32_t offset, uint32_t size, uint32_t spec_id, uint32_t elem_size) {
  // Generate ArgumentInfo for this argument.
  // TODO: generate remaining optional operands.
  auto import_id = getReflectionImport();
  auto arg_name = addSPIRVInst<kDebug>(spv::OpString, name.c_str());
  auto void_id = getSPIRVType(Type::getVoidTy(module->getContext()));
  SPIRVOperandVec Ops;
  Ops << void_id << import_id << reflection::ExtInstArgumentInfo << arg_name;
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
  case clspv::ArgKind::SampledImage:
    ext_inst = reflection::ExtInstArgumentSampledImage;
    break;
  case clspv::ArgKind::StorageImage:
    ext_inst = reflection::ExtInstArgumentStorageImage;
    break;
  case clspv::ArgKind::Sampler:
    ext_inst = reflection::ExtInstArgumentSampler;
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
  case clspv::ArgKind::SampledImage:
  case clspv::ArgKind::StorageImage:
  case clspv::ArgKind::Sampler:
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
    Ops << getSPIRVInt32Constant(offset) << getSPIRVInt32Constant(size);
    break;
  default:
    break;
  }
  Ops << arg_info;
  addSPIRVInst<kReflection>(spv::OpExtInst, Ops);
}
