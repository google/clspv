// RUN: clspv %target %s -o %t.spv -no-inline-single -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

__attribute__((noinline))
float4 core(read_only image2d_t im, float2 coord, sampler_t s) {
  return read_imagef(im, s, coord);
}

__attribute__((noinline))
void apple(read_only image2d_t im, sampler_t s, float2 coord, global float4 *A) {
    *A = core(im, coord, s); }

kernel void foo(float2 coord, sampler_t s, read_only image2d_t im, global float4* A) {
    apple(im, s, 2 * coord, A); }
kernel void bar(float2 coord, sampler_t s, read_only image2d_t im, global float4* A) {
    apple(im, s, 3 * coord, A); }
// CHECK:  OpEntryPoint GLCompute [[_57:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_66:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_34:%[0-9a-zA-Z_]+]] Binding 1
// CHECK:  OpDecorate [[_35:%[0-9a-zA-Z_]+]] Binding 2
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_34]] = OpVariable {{.*}} UniformConstant
// CHECK-DAG:  [[_35]] = OpVariable {{.*}} UniformConstant
// CHECK:  [[_57]] = OpFunction [[_void]]
// CHECK:  [[_66]] = OpFunction [[_void]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_34]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_35]]
// CHECK:  [[_47:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
