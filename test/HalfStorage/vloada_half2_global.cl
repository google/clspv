// RUN: clspv %target %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global float2* A, global uint* B, uint n) {
  A[0] = vloada_half2(n, (global half*)B);
  A[1] = vloada_half2(0, (global half*)B+2);
}

// CHECK-DAG: [[_half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK-DAG: [[_half2:%[a-zA-Z0-9_]+]] = OpTypeVector [[_half]] 2
// CHECK-DAG: [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: [[_v2float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 2
// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[_ulong:%[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK-DAG: [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK-64-DAG: [[_ulong_1:%[0-9a-zA-Z_]+]] = OpConstant [[_ulong]] 1
// CHECK: [[_31:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[A:%[0-9a-zA-Z_]+]] [[_uint_0]] [[_uint_0]]
// CHECK: [[_33:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]]

// CHECK-64: [[_33_ulong:%[0-9a-zA-Z_]+]] = OpUConvert [[_ulong]] [[_33]]
// CHECK-64: [[shl:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[_ulong]] [[_33_ulong]] [[_ulong_1]]
// CHECK-32: [[shl:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical [[_uint]] [[_33]] [[_uint_1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[B:%[a-zA-Z0-9_]+]] [[_uint_0]] [[shl]]
// CHECK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[_half]] [[gep]]

// CHECK-64: [[or:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[_ulong]] [[shl]] [[_ulong_1]]
// CHECK-32: [[or:%[a-zA-Z0-9_]+]] = OpBitwiseOr [[_uint]] [[shl]] [[_uint_1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]] [[or]]
// CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[_half]] [[gep]]

// CHECK: [[construct:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[_half2]] [[ld0]] [[ld1]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[_uint]] [[construct]]
// CHECK: [[unpack:%[a-zA-Z0-9_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[cast]]
// CHECK: OpStore {{.*}} [[unpack]]

// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]] [[_uint_2]]
// CHECK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[_half]] [[gep]]

// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[B]] [[_uint_0]] [[_uint_3]]
// CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[_half]] [[gep]]

// CHECK: [[construct:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[_half2]] [[ld0]] [[ld1]]
// CHECK: [[cast:%[a-zA-Z0-9_]+]] = OpBitcast [[_uint]] [[construct]]
// CHECK: [[unpack:%[a-zA-Z0-9_]+]] = OpExtInst [[_v2float]] {{.*}} UnpackHalf2x16 [[cast]]
// CHECK: OpStore {{.*}} [[unpack]]
