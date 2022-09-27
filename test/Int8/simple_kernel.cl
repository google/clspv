// RUN: clspv %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
char bar(char a, char b) { return a + b; }

kernel void foo(global char* in, global char* out, int idx) {
  char x = in[idx];
  char y = in[idx + 1];
  out[idx] = bar(x, y);
}

// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[char]]
// CHECK-DAG: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[one:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[bar:%[a-zA-Z0-9_]+]] = OpFunction [[char]]
// CHECK: [[a:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[char]]
// CHECK: [[b:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[char]]
// CHECK: [[add:%[a-zA-Z0-9_]+]] = OpIAdd [[char]] [[b]] [[a]]
// CHECK: OpReturnValue [[add]]
// CHECK: OpFunction
// CHECK: [[idx:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]]
// CHECK-64: [[idx_long:%[a-zA-Z0-9_]+]] = OpSConvert [[long]] [[idx]]
// CHECK-DAG: [[idx1:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[idx]] [[one]]
// CHECK-64-DAG: [[gepx:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx_long]]
// CHECK-32-DAG: [[gepx:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx]]
// CHECK-64-DAG: [[idx1_long:%[a-zA-Z0-9_]+]] = OpSConvert [[long]] [[idx1]]
// CHECK-64-DAG: [[gepy:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx1_long]]
// CHECK-32-DAG: [[gepy:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx1]]
// CHECK-DAG: [[ldx:%[a-zA-Z0-9_]+]] = OpLoad [[char]] [[gepx]]
// CHECK-DAG: [[ldy:%[a-zA-Z0-9_]+]] = OpLoad [[char]] [[gepy]]
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall [[char]] [[bar]] [[ldx]] [[ldy]]
// CHECK-64: [[out_gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx_long]]
// CHECK-32: [[out_gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx]]
// CHECK: OpStore [[out_gep]] [[call]]
