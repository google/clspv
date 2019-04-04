// RUN: clspv %s -o %t.spv -constant-args-ubo -no-dra
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

int4 bar(constant int4* data) { return data[0]; }

kernel void foo(global int4* out, constant int4* in) {
  *out = bar(in);
}

// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK-DAG: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[foo]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]]
// CHECK: [[bar]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[int0]]
// CHECK: OpLoad {{.*}} [[gep]]
