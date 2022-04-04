// RUN: clspv %s -o %t.spv -no-16bit-storage=ssbo -uniform-workgroup-size
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[UINT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeInt 32 0
// CHECK-DAG: %[[FLOAT_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeFloat 32
// CHECK-DAG: %[[FLOAT2_TYPE_ID:[a-zA-Z0-9_]*]] = OpTypeVector %[[FLOAT_TYPE_ID]] 2
// CHECK-DAG: %[[CONSTANT_0_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 0
// CHECK: %[[UNDEF_ID:[a-zA-Z0-9_]*]] = OpUndef %[[FLOAT2_TYPE_ID]]
// CHECK-DAG: %[[CONSTANT_1_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 1
// CHECK-DAG: %[[CONSTANT_4_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 4
// CHECK-DAG: %[[CONSTANT_16_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 16
// CHECK-DAG: %[[CONSTANT_65535_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 65535
// CHECK-DAG: %[[CONSTANT_64_ID:[a-zA-Z0-9_]*]] = OpConstant %[[UINT_TYPE_ID]] 64
// CHECK: %[[N:[a-zA-Z0-9_]*]] = OpCompositeExtract %[[UINT_TYPE_ID]]
// CHECK: %[[B:[a-zA-Z0-9_]*]] = OpLoad %[[FLOAT_TYPE_ID]]
// CHECK: %[[INSERT_ID:[a-zA-Z0-9_]*]] = OpCompositeInsert %[[FLOAT2_TYPE_ID]] %[[B]] %[[UNDEF_ID]] 0
// CHECK: %[[PACKED_ID:[a-zA-Z0-9_]*]] = OpExtInst %[[UINT_TYPE_ID]] {{.*}} PackHalf2x16 %[[INSERT_ID]]
// CHECK: %[[INDEX_INTO_UINT:[a-zA-Z0-9_]*]] = OpShiftRightLogical %[[UINT_TYPE_ID]] %[[N]] %[[CONSTANT_1_ID]]
// CHECK: %[[OUT_PTR:[a-zA-Z0-9_]*]] = OpAccessChain {{.*}} %[[ARG0_ID:[a-zA-Z0-9_]+]] %[[CONSTANT_0_ID]] %[[INDEX_INTO_UINT]]
// CHECK: %[[PREV_VALUE:[a-zA-Z0-9_]*]] = OpLoad %[[UINT_TYPE_ID]] %[[OUT_PTR]]
// CHECK: %[[SHIFT_RAW:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[N]] %[[CONSTANT_4_ID]]
// CHECK: %[[SHIFT:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[SHIFT_RAW]] %[[CONSTANT_16_ID]]
// CHECK: %[[MASK_BITS_TO_WRITE:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[CONSTANT_65535_ID]] %[[SHIFT]]
// CHECK: %[[MASKED_PREV_VALUE:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[PREV_VALUE]] %[[MASK_BITS_TO_WRITE]]
// CHECK: %[[MASKED_NEW_VALUE:[a-zA-Z0-9_]*]] = OpBitwiseAnd %[[UINT_TYPE_ID]] %[[PACKED_ID]] %[[CONSTANT_65535_ID]]
// CHECK: %[[NEW_BITS_TO_WRITE:[a-zA-Z0-9_]*]] = OpShiftLeftLogical %[[UINT_TYPE_ID]] %[[MASKED_NEW_VALUE]] %[[SHIFT]]
// CHECK: %[[VALUE_TO_XOR:[a-zA-Z0-9_]*]] = OpBitwiseXor %[[UINT_TYPE_ID]] %[[MASKED_PREV_VALUE]] %[[NEW_BITS_TO_WRITE]]
// The 64 here is Relaxed consistency on Uniform memory (a.k.a. OpenCL global memory)
// TODO(dneto): Test vstore_half on local memory.
// CHECK: %[[XOR_RESULT:[a-zA-Z0-9_]*]] = OpAtomicXor %[[UINT_TYPE_ID]] %[[OUT_PTR]] %[[CONSTANT_1_ID]] %[[CONSTANT_64_ID]] %[[VALUE_TO_XOR]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int* a, global float* b, int n)
{
  vstore_half(*b, n, (global half *)a);
}
