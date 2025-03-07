// RUN: clspv %target  %s -o %t.spv -int8 -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK:     %[[a_struct:[0-9a-zA-Z_]+]] = OpLoad {{.*}} {{.*}}
// CHECK:     %[[copy:[0-9a-zA-Z_]+]] = OpCopyLogical {{.*}} %[[a_struct]]
// CHECK:     %[[a:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uchar]] %[[copy]] 0
// CHECK:     OpStore {{.*}} %[[a]]

kernel void test_rotate(global uchar* out, uchar a)
{
    *out = rotate(a, (uchar)64);
}


