// RUN: clspv %target %s -o %t.spv -no-inline-single -cluster-pod-kernel-args=0
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just for fun, swap arguments in the helpers.

const sampler_t s = CLK_NORMALIZED_COORDS_TRUE;

__attribute__((noinline))
float4 core(read_only image3d_t im, float4 coord) {
  return read_imagef(im, s, coord);
}

__attribute__((noinline))
void apple(read_only image3d_t im, float4 coord, global float4 *A) {
    *A = core(im, coord); }

kernel void foo(float4 coord, read_only image3d_t im, global float4* A) {
    apple(im, 2 * coord, A); }
kernel void bar(float4 coord, read_only image3d_t im, global float4* A) {
    apple(im, 3 * coord, A); }
// CHECK:  OpEntryPoint GLCompute [[_55:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_64:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_32:%[0-9a-zA-Z_]+]] Binding 0
// CHECK:  OpDecorate [[_33:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_32]] = OpVariable {{.*}} UniformConstant
// CHECK-DAG:  [[_33]] = OpVariable {{.*}} UniformConstant
// CHECK:  [[_55]] = OpFunction [[_void]]
// CHECK:  [[_64]] = OpFunction [[_void]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpFunction
// CHECK-DAG:  [[_41:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_32]]
// CHECK-DAG:  [[_42:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_33]]
// CHECK:  [[_45:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
