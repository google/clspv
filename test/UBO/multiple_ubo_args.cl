// RUN: clspv %s -o %t.spv -constant-args-ubo
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

int4 bar(constant int4* in1, constant int4* in2) {
  return in1[0] + in2[0];
}

kernel void k1(global int4* out, constant int4* in1, constant int4* in2) {
  *out = bar(in1, in2);
}

kernel void k2(global int4* out, constant int4* in1, constant int4* in2) {
  *out = bar(in2, in1);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: OpEntryPoint GLCompute [[k2:%[a-zA-Z0-9_]+]]
// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[var1:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[var2:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[k1]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar1:%[a-zA-Z0-9_]+]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[k2]] = OpFunction
// CHECK: OpFunctionCall {{.*}} [[bar2:%[a-zA-Z0-9_]+]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[bar2]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var2]] [[int0]] [[int0]]
// CHECK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var1]] [[int0]] [[int0]]
// CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep1]]
// CHECK: [[ld2:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep2]]
// CHECK: OpIAdd {{.*}} [[ld2]] [[ld1]]
// CHECK: OpFunctionEnd
// CHECK-NEXT: [[bar1]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var1]] [[int0]] [[int0]]
// CHECK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var2]] [[int0]] [[int0]]
// CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep1]]
// CHECK: [[ld2:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep2]]
// CHECK: OpIAdd {{.*}} [[ld2]] [[ld1]]
// CHECK: OpFunctionEnd
// CHECK-NOT: OpFunction
