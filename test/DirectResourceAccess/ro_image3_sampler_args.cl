// RUN: clspv %target %s -o %t.spv -no-inline-single -keep-unused-arguments -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

__attribute__((noinline))
float4 core(read_only image3d_t im, float4 coord, sampler_t s) {
  return read_imagef(im, s, coord);
}

__attribute__((noinline))
void apple(read_only image3d_t im, sampler_t s, float4 coord, global float4 *A) {
    *A = core(im, coord, s); }

kernel void foo(float4 coord, sampler_t s, read_only image3d_t im, global float4* A) {
    apple(im, s, 2 * coord, A); }
kernel void bar(float4 coord, sampler_t s, read_only image3d_t im, global float4* A) {
    apple(im, s, 3 * coord, A); }
// CHECK:  OpEntryPoint GLCompute [[_55:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_64:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_32]] Binding 1
// CHECK:  OpDecorate [[_33:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_33]] Binding 2
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_32]] = OpVariable {{.*}} UniformConstant
// CHECK-DAG:  [[_33]] = OpVariable {{.*}} UniformConstant
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_32]]
// CHECK:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_33]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_52:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_32]]
// CHECK:  [[_53:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_33]]
// CHECK:  [[_55]] = OpFunction [[_void]]
// CHECK:  [[_59:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_32]]
// CHECK:  [[_60:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_33]]
// CHECK:  [[_64]] = OpFunction [[_void]]
// CHECK:  [[_68:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_32]]
// CHECK:  [[_69:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_33]]
