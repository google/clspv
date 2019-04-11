// RUN: clspv %s -o %t.spv -constant-args-ubo
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

int4 c(constant int4* data) { return data[0]; }

int4 b(constant int4* data) { return c(data); }

int4 a(constant int4* data) { return b(data); }

kernel void k1(global int4* out, constant int4* in) {
  *out = a(in);
}

kernel void k2(global int4* out, constant int4* in) {
  *out = a(in + 1);
}

// CHECK: OpEntryPoint GLCompute [[k1:%[a-zA-Z0-9_]+]]
// CHECK: OpEntryPoint GLCompute [[k2:%[a-zA-Z0-9_]+]]
// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK-DAG: [[int0:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK-DAG: [[int1:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[k1]] = OpFunction
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[a1:%[a-zA-Z0-9_]+]]
// CHECK-NEXT: OpStore {{.*}} [[call]]
// CHECK-NEXT: OpReturn
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[k2]] = OpFunction
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[a2:%[a-zA-Z0-9_]+]]
// CHECK-NEXT: OpStore {{.*}} [[call]]
// CHECK-NEXT: OpReturn
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[a2]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[b2:%[a-zA-Z0-9_]+]]
// CHECK: ReturnValue [[call]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[a1]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[b1:%[a-zA-Z0-9_]+]]
// CHECK: ReturnValue [[call]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[b1]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[c1:%[a-zA-Z0-9_]+]]
// CHECK: ReturnValue [[call]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[b2]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[call:%[a-zA-Z0-9_]+]] = OpFunctionCall {{.*}} [[c2:%[a-zA-Z0-9_]+]]
// CHECK: ReturnValue [[call]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[c2]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[int1]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep]]
// CHECK: ReturnValue [[ld]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NEXT: [[c1]] = OpFunction
// CHECK-NOT: OpFunctionParameter
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] [[int0]] [[int0]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad {{.*}} [[gep]]
// CHECK: ReturnValue [[ld]]
// CHECK-NEXT: OpFunctionEnd
// CHECK-NOT: OpFunction
