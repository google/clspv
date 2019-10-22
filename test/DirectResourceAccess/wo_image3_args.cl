// RUN: clspv %s -o %t.spv -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable

void core(float4 a, write_only image3d_t im, int4 coord) {
  write_imagef(im, coord, a);
}

void apple(write_only image3d_t im, int4 coord, float4 a) {
   core(a, im, coord);
}

kernel void foo(int4 coord, write_only image3d_t im, float4 a) {
  apple(im, 2 * coord, a);
}

kernel void bar(int4 coord, write_only image3d_t im, float4 a) {
  apple(im, 3 * coord, a);
}

// CHECK:  OpEntryPoint GLCompute [[_45:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_54:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_29:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_29]] Binding 1
// CHECK:  OpDecorate [[_29]] NonReadable
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_29]] = OpVariable {{.*}} UniformConstant
// CHECK:  [[_32:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_29]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunction [[_void]]
// CHECK:  [[_43:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_29]]
// CHECK:  [[_45]] = OpFunction [[_void]]
// CHECK:  [[_49:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_29]]
// CHECK:  [[_54]] = OpFunction [[_void]]
// CHECK:  [[_58:%[0-9a-zA-Z_]+]] = OpLoad {{.*}} [[_29]]
