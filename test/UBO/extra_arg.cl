// RUN: clspv %target %s -o %t.spv -constant-args-ubo -arch=spir
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val %t.spv --target-env vulkan1.0

// RUN: clspv %target %s -o %t.spv -constant-args-ubo -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val %t.spv --target-env vulkan1.0

__attribute__((noinline))
int4 bar(constant int4* in) { return in[0]; }

kernel void k1(global int4* out, constant int4* in) {
  constant int4* x = in + in[0].x;
  *out = bar(x);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-64: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[k1]] = OpFunction
// CHECK: [[ex:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] {{.*}} 0
// CHECK-64: [[ex_long:%[a-zA-Z0-9_]+]] = OpSConvert [[long]] [[ex]]
// CHECK-64: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]] [[ex_long]]
// CHECK-32: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]] [[ex]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[bar]] = OpFunction
// CHECK-64-NEXT: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[long]]
// CHECK-32-NEXT: [[param:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[int]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[param]]
// CHECK: OpLoad {{.*}} [[gep]]
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
