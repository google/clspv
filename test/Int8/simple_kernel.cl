// RUN: clspv %s -o %t.spv -int8 -no-inline-single
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
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
// CHECK-DAG: [[idx1:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[idx]] [[one]]
// CHECK-DAG: [[gepx:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx]]
// CHECK-DAG: [[gepy:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx1]]
// CHECK-DAG: [[ldx:%[a-zA-Z0-9_]+]] = OpLoad [[char]] [[gepx]]
// CHECK-DAG: [[ldy:%[a-zA-Z0-9_]+]] = OpLoad [[char]] [[gepy]]
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall [[char]] [[bar]] [[ldx]] [[ldy]]
// CHECK: [[out_gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[idx]]
// CHECK: OpStore [[out_gep]] [[call]]
