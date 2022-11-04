// RUN: clspv %target %s -o %t.spv -no-inline-single -no-dra
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
int baz(global int* x) { return x[0]; }

__attribute__((noinline))
int bar(global int* x) { return baz(x); }

kernel void foo(global int* data) {
  int x = bar(data);
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet 0
// CHECK: OpDecorate [[var]] Binding 0
// CHECK: OpDecorate [[var]] Coherent
// CHECK: OpDecorate [[param1:%[a-zA-Z0-9_]+]] Coherent
// CHECK: OpDecorate [[param2:%[a-zA-Z0-9_]+]] Coherent
// CHECK: [[baz:%[a-zA-Z0-9_]+]] = OpFunction
// CHECK: [[param1]] = OpFunctionParameter
// CHECK: = OpFunction
// CHECK: [[param2]] = OpFunctionParameter
// CHECK: OpFunctionCall {{.*}} [[baz]] [[param2]]

