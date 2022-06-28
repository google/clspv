// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global size_t *out, read_only image1d_array_t img)
{
    *out = get_image_array_size(img);
}

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[imgTy:%[^ ]+]] = OpTypeImage [[float]] 1D 0 1 0 1 Unknown
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK:     [[load:%[^ ]+]] = OpLoad [[imgTy]]
// CHECK:     [[imgQuery:%[^ ]+]] = OpImageQuerySizeLod [[v2uint]] [[load]] [[uint_0]]
// CHECK:     [[arraySize:%[^ ]+]] = OpCompositeExtract [[uint]] [[imgQuery]] 1
// CHECK:     OpStore {{.*}} [[arraySize]]
