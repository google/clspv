// RUN: clspv %target %s -o %t.spv -constant-args-ubo
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

__attribute__((noinline))
int4 bar(constant int4* data) { return data[0]; }

kernel void k1(global int4* out, constant int4* in) {
  *out = bar(in);
}

kernel void k2(global int4* out, constant int4* in) {
  *out = bar(in + 1);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: OpEntryPoint GLCompute [[k2:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK-DAG: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[k1]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar1:%[a-zA-Z0-9_]+]]
// CHECK: [[k2]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar2:%[a-zA-Z0-9_]+]]
// CHECK: [[bar2]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[int1]]
// CHECK: OpLoad {{.*}} [[gep]]
// CHECK: [[bar1]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[int0]]
// CHECK: OpLoad {{.*}} [[gep]]
