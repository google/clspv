// RUN: clspv %target %s -o %t.spv --cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-NOT: OpCapability StorageImageReadWithoutFormat
// CHECK-DAG: %[[BOOL_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeBool
// CHECK-DAG: %[[INT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[SAMPLER_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampler
// CHECK-DAG: %[[READ_ONLY_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeImage %[[FLOAT_TYPE_ID]] 3D 0 0 0 1 Unknown
// CHECK-DAG: %[[FLOAT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 4
// CHECK-DAG: %[[INT4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[INT_TYPE_ID]] 4
// CHECK-DAG: %[[INT3_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[INT_TYPE_ID]] 3
// CHECK-DAG: %[[BOOL4_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[BOOL_TYPE_ID]] 4
// CHECK-DAG: %[[SAMPLED_IMAGE_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeSampledImage %[[READ_ONLY_IMAGE_TYPE_ID]]
// CHECK-DAG: %[[FP_CONSTANT_0_5_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0.5
// CHECK-DAG: %[[FP_CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[FLOAT_TYPE_ID]] 0
// CHECK-DAG: %[[UINT_0:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 0
// CHECK-DAG: %[[UINT_16:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 16
// CHECK-DAG: %[[UINT_1:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 1
// CHECK-DAG: %[[UINT_48:[a-zA-Z0-9_]*]] = OpConstant %[[INT_TYPE_ID]] 48
// CHECK: %[[S_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[SAMPLER_TYPE_ID]]
// CHECK: %[[I_LOAD_ID:[a-zA-Z0-9_]*]] = OpLoad %[[READ_ONLY_IMAGE_TYPE_ID]]

// CHECK: %[[COORD_ID:[a-zA-Z0-9_]*]] = OpCompositeConstruct %[[INT4_TYPE_ID]]
// CHECK: %[[BITCAST:[a-zA-Z0-9_]*]] = OpBitcast %[[FLOAT4_TYPE_ID]] %[[COORD_ID]]
// CHECK: %[[IMAGE_SIZES3:[a-zA-Z0-9_]*]] = OpImageQuerySizeLod %[[INT3_TYPE_ID]] %[[I_LOAD_ID]]
// CHECK: %[[IMAGE_SIZES4:[a-zA-Z0-9_]*]] = OpCompositeConstruct %[[INT4_TYPE_ID]] %[[IMAGE_SIZES3]]
// CHECK: %[[CONVERT:[a-zA-Z0-9_]*]] = OpConvertSToF %[[FLOAT4_TYPE_ID]] %[[IMAGE_SIZES4]]
// CHECK: %[[FLOOR:[a-zA-Z0-9_]*]] = OpExtInst %[[FLOAT4_TYPE_ID]] {{.*}} Floor %[[BITCAST]]
// CHECK: %[[FADD:[a-zA-Z0-9_]*]] = OpFAdd %[[FLOAT4_TYPE_ID]] %[[FLOOR]] {{.*}}
// CHECK: %[[FDIV_NEAREST:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT4_TYPE_ID]] %[[FADD]] %[[CONVERT]]
// CHECK: %[[FDIV_LINEAR:[a-zA-Z0-9_]*]] = OpFDiv %[[FLOAT4_TYPE_ID]] %[[BITCAST]] %[[CONVERT]]
// CHECK: %[[GEP_SAMPLER_MASK:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} {{.*}} %[[UINT_1]] %[[UINT_0]]
// CHECK: %[[SAMPLER_MASK:[a-zA-Z0-9_]*]] = OpLoad %[[INT_TYPE_ID]] %[[GEP_SAMPLER_MASK]]
// CHECK: %[[AND:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[INT_TYPE_ID]] %[[SAMPLER_MASK]] %[[UINT_48]]
// CHECK: %[[CMP:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[AND]] %[[UINT_16]]
// CHECK: %[[INSERT:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[BOOL4_TYPE_ID]] %[[CMP]] {{.*}} 0
// CHECK: %[[SHUFFLE:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[BOOL4_TYPE_ID]] %[[INSERT]] {{.*}} 0 0 0 0
// CHECK: %[[SELECT:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT4_TYPE_ID]] %[[SHUFFLE]] %[[FDIV_NEAREST]] %[[FDIV_LINEAR]]
// CHECK: %[[AND:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[INT_TYPE_ID]] %[[SAMPLER_MASK]] %[[UINT_1]]
// CHECK: %[[CMP:[a-zA-Z0-9_]*]] = OpIEqual %[[BOOL_TYPE_ID]] %[[AND]] %[[UINT_1]]
// CHECK: %[[INSERT:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[BOOL4_TYPE_ID]] %[[CMP]] {{.*}} 0
// CHECK: %[[SHUFFLE:[a-zA-Z0-9_]*]] = OpVectorShuffle %[[BOOL4_TYPE_ID]] %[[INSERT]] {{.*}} 0 0 0 0
// CHECK: %[[OP_SELECT_ID:[a-zA-Z0-9_]*]] = OpSelect %[[FLOAT4_TYPE_ID]] %[[SHUFFLE]] %[[BITCAST]] %[[SELECT]]

// CHECK: %[[SAMPLED_IMAGE_ID:[a-zA-Z0-9_]*]] = OpSampledImage %[[SAMPLED_IMAGE_TYPE_ID]] %[[I_LOAD_ID]] %[[S_LOAD_ID]]
// CHECK: %[[OP_ID:[a-zA-Z0-9_]*]] = OpImageSampleExplicitLod %[[FLOAT4_TYPE_ID]] %[[SAMPLED_IMAGE_ID]] %[[OP_SELECT_ID]] Lod %[[FP_CONSTANT_0_ID]]
// CHECK: OpStore {{.*}} %[[OP_ID]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(sampler_t s, read_only image3d_t i, float4 c, global float4* a)
{
  *a = read_imagef(i, s, c);
}
