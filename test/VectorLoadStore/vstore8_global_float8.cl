// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target --long-vector %s -o %t.spv -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that vstore for float8 is supported.

// CHECK-DAG: [[UINT:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[RUNTIME_UINT:%[^ ]+]] = OpTypeRuntimeArray [[UINT]]
// CHECK-DAG: [[STRUCT_RUNTIME_UINT:%[^ ]+]] = OpTypeStruct [[RUNTIME_UINT]]
// CHECK-DAG: [[PTR_UINT:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_UINT]]
//
// CHECK-64-DAG: [[ULONG:%[^ ]+]] = OpTypeInt 64 0
//
// CHECK-DAG: [[FLOAT:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[RUNTIME_FLOAT:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT]]
// CHECK-DAG: [[STRUCT_RUNTIME_FLOAT:%[^ ]+]] = OpTypeStruct [[RUNTIME_FLOAT]]
// CHECK-DAG: [[PTR_FLOAT:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_FLOAT]]
//
// CHECK-DAG: [[FLOAT8:%[^ ]+]] = OpTypeVector [[FLOAT]] 4
// CHECK-DAG: [[RUNTIME_FLOAT8:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT8]]
// CHECK-DAG: [[STRUCT_RUNTIME_FLOAT8:%[^ ]+]] = OpTypeStruct [[RUNTIME_FLOAT8]]
// CHECK-DAG: [[PTR_FLOAT8:%[^ ]+]] = OpTypePointer StorageBuffer [[STRUCT_RUNTIME_FLOAT8]]
//
// CHECK-DAG: [[INT_PTR:%[^ ]+]] = OpTypePointer StorageBuffer [[UINT]]
// CHECK-DAG: [[FLOAT_PTR_FLOAT8:%[^ ]+]] = OpTypePointer StorageBuffer [[FLOAT8]]
// CHECK-DAG: [[BUFFER_FLOAT_PTR:%[^ ]+]] = OpTypePointer StorageBuffer [[FLOAT]]
//
// CHECK-DAG: [[CST_0:%[^ ]+]] = OpConstant [[UINT]] 0
// CHECK-DAG: [[CST_1:%[^ ]+]] = OpConstant [[UINT]] 1
// CHECK-DAG: [[CST_2:%[^ ]+]] = OpConstant [[UINT]] 2
// CHECK-64-DAG: [[CST_1_LONG:%[^ ]+]] = OpConstant [[ULONG]] 1
// CHECK-64-DAG: [[CST_2_LONG:%[^ ]+]] = OpConstant [[ULONG]] 2
//
// CHECK-32-DAG: [[CST_3:%[^ ]+]] = OpConstant [[UINT]] 3
// CHECK-32-DAG: [[CST_4:%[^ ]+]] = OpConstant [[UINT]] 4
// CHECK-32-DAG: [[CST_5:%[^ ]+]] = OpConstant [[UINT]] 5
// CHECK-32-DAG: [[CST_6:%[^ ]+]] = OpConstant [[UINT]] 6
// CHECK-32-DAG: [[CST_7:%[^ ]+]] = OpConstant [[UINT]] 7
// CHECK-64-DAG: [[CST_3:%[^ ]+]] = OpConstant [[ULONG]] 3
// CHECK-64-DAG: [[CST_4:%[^ ]+]] = OpConstant [[ULONG]] 4
// CHECK-64-DAG: [[CST_5:%[^ ]+]] = OpConstant [[ULONG]] 5
// CHECK-64-DAG: [[CST_6:%[^ ]+]] = OpConstant [[ULONG]] 6
// CHECK-64-DAG: [[CST_7:%[^ ]+]] = OpConstant [[ULONG]] 7
//
// CHECK-DAG: [[OFFSET:%[^ ]+]] = OpVariable [[PTR_UINT]]   StorageBuffer
// CHECK-DAG: [[DST:%[^ ]+]]    = OpVariable [[PTR_FLOAT]]  StorageBuffer
// CHECK-DAG: [[VALUES:%[^ ]+]] = OpVariable [[PTR_FLOAT8]] StorageBuffer
//
// CHECK-DAG: [[PTR:%[^ ]+]]   = OpAccessChain [[INT_PTR]] [[OFFSET]] [[CST_0]]
// CHECK-DAG: [[VAL_0:%[^ ]+]] = OpLoad [[UINT]] [[PTR]]
//
// CHECK-DAG: [[PTR_1:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[VAL_1:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_1]]
// CHECK-DAG: [[A:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 0
// CHECK-DAG: [[B:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 1
// CHECK-DAG: [[C:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 2
// CHECK-DAG: [[D:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_1]] 3
//
// CHECK-DAG: [[PTR_0:%[^ ]+]] = OpAccessChain [[FLOAT_PTR_FLOAT8]] [[VALUES]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[VAL_2:%[^ ]+]] = OpLoad [[FLOAT8]] [[PTR_0]]
// CHECK-DAG: [[E:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 0
// CHECK-DAG: [[F:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 1
// CHECK-DAG: [[G:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 2
// CHECK-DAG: [[H:%[^ ]+]] = OpCompositeExtract [[FLOAT]] [[VAL_2]] 3
//
// CHECK-32-DAG: [[BASE_OFFSET:%[^ ]+]] = OpShiftLeftLogical [[UINT]] [[VAL_0]] [[CST_3]]
// CHECK-64-DAG: [[VAL_0_LONG:%[^ ]+]] = OpUConvert [[ULONG]] [[VAL_0]]
// CHECK-64-DAG: [[BASE_OFFSET:%[^ ]+]] = OpShiftLeftLogical [[ULONG]] [[VAL_0_LONG]] [[CST_3]]
// CHECK-DAG: [[PTR_A:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[BASE_OFFSET]]
// CHECK-DAG: OpStore [[PTR_A]] [[A]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_1_LONG]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_1]]
// CHECK-DAG: [[PTR_B:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_B]] [[B]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_2_LONG]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_2]]
// CHECK-DAG: [[PTR_C:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_C]] [[C]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_3]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_3]]
// CHECK-DAG: [[PTR_D:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_D]] [[D]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_4]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_4]]
// CHECK-DAG: [[PTR_E:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_E]] [[E]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_5]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_5]]
// CHECK-DAG: [[PTR_F:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_F]] [[F]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_6]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_6]]
// CHECK-DAG: [[PTR_G:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_G]] [[G]]
//
// CHECK-64-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[ULONG]] [[BASE_OFFSET]] [[CST_7]]
// CHECK-32-DAG: [[SHIFT:%[^ ]+]] = OpBitwiseOr [[UINT]] [[BASE_OFFSET]] [[CST_7]]
// CHECK-DAG: [[PTR_H:%[^ ]+]] = OpAccessChain [[BUFFER_FLOAT_PTR]] [[DST]] [[CST_0]] [[SHIFT]]
// CHECK-DAG: OpStore [[PTR_H]] [[H]]

kernel void test(global uint *offset, global float *dst,
                 global float4 *values) {
  // The following is optimised into 8 load/store pairs of instructions.
  float8 value = (float8)(values[0], values[1]);
  vstore8(value, *offset, dst);
}
