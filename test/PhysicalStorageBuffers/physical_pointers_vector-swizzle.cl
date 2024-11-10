// RUN: clspv  %s -o %t.spv -cl-std=CL3.0 -no-8bit-storage=pushconstant -no-16bit-storage=pushconstant -spv-version=1.6 -arch=spir64 -physical-storage-buffers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.3spv1.6 %t.spv

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[v4uchar:%[a-zA-Z0-9_]+]] = OpTypeVector [[uchar]] 4
// CHECK-DAG: [[ptr_SB_v4uchar:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[v4uchar]]
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[var_ptr:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_SB_v4uchar]] %32
// CHECK: [[var_0:%[a-zA-Z0-9_]+]] = OpLoad [[v4uchar]] [[var_ptr]] Aligned 4
// CHECK: [[var_0_0:%[a-zA-Z0-9_]+]] = OpCompositeInsert [[v4uchar]] {{.*}} [[var_0]] 0
// CHECK: OpStore [[var_ptr]] [[var_0_0]] Aligned 4
// CHECK: [[var_1:%[a-zA-Z0-9_]+]] = OpPtrAccessChain [[ptr_SB_v4uchar]] [[var_ptr]] [[uint_1]]

__kernel void test_vector_swizzle_xyzw(char4 value, __global char4* dst)
{
    int index = 0;
    // lvalue swizzles
    dst[index++].x = value.x;
    dst[index++].xyzw = value;
}
