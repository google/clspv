// RUN: clspv %target %s -o %t.spv -constant-args-ubo -arch=spir
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val %t.spv --target-env vulkan1.0

// RUN: clspv %target %s -o %t.spv -constant-args-ubo -arch=spir64
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val %t.spv --target-env vulkan1.0

__attribute__((noinline))
int4 bar(constant int4* in1, constant int4* in2) {
  return in1[0] + in2[0];
}

kernel void k1(global int4* out, constant int4* in) {
  constant int4* x = in + in[0].x;
  constant int4* y = in + in[1].y;
  *out = bar(x, y);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-64: [[long:%[a-zA-Z0-9_]+]] = OpTypeInt 64 0
// CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[k1]] = OpFunction
// CHECK: [[ex0:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] {{.*}} 0
// CHECK-64: [[ex0_long:%[a-zA-Z0-9_]+]] = OpSConvert [[long]] [[ex0]]
// CHECK: [[ex1:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] {{.*}} 1
// CHECK-64: [[ex1_long:%[a-zA-Z0-9_]+]] = OpSConvert [[long]] [[ex1]]
// CHECK-64: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]] [[ex0_long]] [[ex1_long]]
// CHECK-32: OpFunctionCall {{.*}} [[bar:%[a-zA-Z0-9_]+]] [[ex0]] [[ex1]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[bar]] = OpFunction
// CHECK-64-NEXT: [[param0:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[long]]
// CHECK-64-NEXT: [[param1:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[long]]
// CHECK-32-NEXT: [[param0:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[int]]
// CHECK-32-NEXT: [[param1:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[int]]
// CHECK: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[param0]]
// CHECK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[param1]]
// CHECK: OpLoad {{.*}} [[gep0]]
// CHECK: OpLoad {{.*}} [[gep1]]
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
