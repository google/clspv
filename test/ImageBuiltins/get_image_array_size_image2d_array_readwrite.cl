// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global size_t *out, read_write image2d_array_t img)
{
    *out = get_image_array_size(img);
}

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[v3uint:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[imgTy:%[^ ]+]] = OpTypeImage [[float]] 2D 0 1 0 2 Unknown
// CHECK:     [[load:%[^ ]+]] = OpLoad [[imgTy]]
// CHECK:     [[imgQuery:%[^ ]+]] = OpImageQuerySize [[v3uint]] [[load]]
// CHECK:     [[arraySize:%[^ ]+]] = OpCompositeExtract [[uint]] [[imgQuery]] 2
// CHECK:     OpStore {{.*}} [[arraySize]]
