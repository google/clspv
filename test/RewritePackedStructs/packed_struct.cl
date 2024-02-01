// RUN: clspv %s -o %t.spv -rewrite-packed-structs -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// TODO(#1292)
// XFAIL: *

struct S1{
    int x;
    char y;
} __attribute__((packed));

struct S2{
    char y;
    int x;
};

struct S3{
    int x;
    char a;
    char b;
    char y;
} __attribute__((packed));

struct S4{
    int x;
    char a;
    char b;
    char c;
    char y;
} __attribute__((packed));

__kernel void test1(__global struct S1 *a, __global struct S2* b) {
  b[0].x = a[0].x;
  b[0].y = a[0].y;
}

__kernel void test2(__global struct S1 *a, __global struct S2* b, __global struct S3* c) {
  b[0].y = a[0].y + c[0].y;
  b[0].x = a[0].x + c[0].x;

  c[0].a = a[0].y + b[0].y;
  c[0].b = c[0].a + c[0].y;
}

__kernel void test3(__global struct S3* a, __global struct S4* b) {
  a[0].a = b[0].a;
  a[0].b = b[0].b;
  a[0].x = b[0].x;
  a[0].y = b[0].y;

  b[0].c = b[0].a + b[0].b + b[0].y;
}

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint5:%[^ ]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[uint7:%[^ ]+]] = OpConstant [[uint]] 7
// CHECK-DAG: [[uint8:%[^ ]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0

// CHECK-DAG: [[arr_uchar5:%[^ ]+]] = OpTypeArray [[uchar]] [[uint5]]
// CHECK-DAG: [[struct_arr_uchar5:%[^ ]+]] = OpTypeStruct [[arr_uchar5]]
// CHECK-DAG: [[arr_struct_arr_uchar5:%[^ ]+]] = OpTypeRuntimeArray [[struct_arr_uchar5]]
// CHECK-DAG: [[S1:%[^ ]+]] = OpTypeStruct [[arr_struct_arr_uchar5]]
// CHECK-DAG: [[S1_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[S1]]

// CHECK-DAG: [[arr_uchar8:%[^ ]+]] = OpTypeArray [[uchar]] [[uint8]]
// CHECK-DAG: [[arr_arr_uchar8:%[^ ]+]] = OpTypeRuntimeArray [[arr_uchar8]]
// CHECK-DAG: [[S2_4:%[^ ]+]] = OpTypeStruct [[arr_arr_uchar8]]
// CHECK-DAG: [[S2_4_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[S2_4]]

// CHECK-DAG: [[arr_uchar7:%[^ ]+]] = OpTypeArray [[uchar]] [[uint7]]
// CHECK-DAG: [[struct_arr_uchar7:%[^ ]+]] = OpTypeStruct [[arr_uchar7]]
// CHECK-DAG: [[arr_struct_arr_uchar7:%[^ ]+]] = OpTypeRuntimeArray [[struct_arr_uchar7]]
// CHECK-DAG: [[S3:%[^ ]+]] = OpTypeStruct [[arr_struct_arr_uchar7]]
// CHECK-DAG: [[S3_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[S3]]

// CHECK-DAG: OpDecorate [[arr_uchar5]] ArrayStride 1
// CHECK-DAG: OpDecorate [[arr_uchar7]] ArrayStride 1
// CHECK-DAG: OpDecorate [[arr_uchar8]] ArrayStride 1

// CHECK-DAG: OpMemberDecorate [[struct_arr_uchar5]] 0 Offset 0
// CHECK-DAG: OpDecorate [[arr_struct_arr_uchar5]] ArrayStride 5
// CHECK-DAG: OpDecorate [[arr_arr_uchar8]] ArrayStride 8
// CHECK-DAG: OpMemberDecorate [[struct_arr_uchar7]] 0 Offset 0
// CHECK-DAG: OpDecorate [[arr_struct_arr_uchar7]] ArrayStride 7

// CHECK-DAG: [[a_S1:%[^ ]+]] = OpVariable [[S1_ptr]] StorageBuffer
// CHECK-DAG: [[b_S2_4:%[^ ]+]] = OpVariable [[S2_4_ptr]] StorageBuffer
// CHECK-DAG: [[c_S3:%[^ ]+]] = OpVariable [[S3_ptr]] StorageBuffer
// CHECK-DAG: [[a_S3:%[^ ]+]] = OpVariable [[S3_ptr]] StorageBuffer

// CHECK-DAG: OpDecorate [[a_S1]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[a_S1]] Binding 0
// CHECK-DAG: OpDecorate [[b_S2_4]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[b_S2_4]] Binding 1
// CHECK-DAG: OpDecorate [[c_S3]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[c_S3]] Binding 2
// CHECK-DAG: OpDecorate [[a_S3]] DescriptorSet 0
// CHECK-DAG: OpDecorate [[a_S3]] Binding 0
