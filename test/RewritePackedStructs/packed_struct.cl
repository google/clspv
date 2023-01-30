// RUN: clspv %s -o %t.spv -rewrite-packed-structs -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// TODO(#1005): pass needs fixed
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

// CHECK: OpCapability Int8

// argument types with packed structs

// CHECK: OpMemberDecorate [[S3_transformed:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[S3_buffer_runtime_arr:%[a-zA-Z0-9_]+]] ArrayStride 7
// CHECK: OpMemberDecorate [[S3_buffer_runtime_arr_struct:%[a-zA-Z0-9_]+]] 0 Offset 0

// CHECK: OpMemberDecorate [[S4:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[S4]] 1 Offset 4
// CHECK: OpMemberDecorate [[S4]] 2 Offset 5
// CHECK: OpMemberDecorate [[S4]] 3 Offset 6
// CHECK: OpMemberDecorate [[S4]] 4 Offset 7
// CHECK: OpDecorate [[S4_buffer_runtime_arr:%[a-zA-Z0-9_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[S4_buffer_runtime_arr_struct:%[a-zA-Z0-9_]+]] 0 Offset 0

// CHECK: OpMemberDecorate [[S1_transformed:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpDecorate [[S1_buffer_runtime_arr:%[a-zA-Z0-9_]+]] ArrayStride 5
// CHECK: OpMemberDecorate [[S1_buffer_runtime_arr_struct:%[a-zA-Z0-9_]+]] 0 Offset 0

// CHECK: OpMemberDecorate [[S2:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[S2]] 1 Offset 4
// CHECK: OpDecorate [[S2_buffer_runtime_arr:%[a-zA-Z0-9_]+]] ArrayStride 8
// CHECK: OpMemberDecorate [[S2_buffer_runtime_arr_struct:%[a-zA-Z0-9_]+]] 0 Offset 0

// declarations 

// CHECK: OpDecorate [[arr_uchar_uint_7:%[a-zA-Z0-9_]+]] ArrayStride 1
// CHECK: OpDecorate [[arr_uchar_uint_5:%[a-zA-Z0-9_]+]] ArrayStride 1

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[uint_7:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 7

// CHECK: [[arr_uchar_uint_7]] = OpTypeArray [[uchar]] [[uint_7]]
// CHECK: [[S3_transformed]] = OpTypeStruct [[arr_uchar_uint_7]]
// CHECK: [[S3_buffer_runtime_arr]] = OpTypeRuntimeArray [[S3_transformed]]
// CHECK: [[S3_buffer_runtime_arr_struct]] = OpTypeStruct [[S3_buffer_runtime_arr]]

// CHECK: [[S4]] = OpTypeStruct [[uint]] [[uchar]] [[uchar]] [[uchar]] [[uchar]]
// CHECK: [[S4_buffer_runtime_arr]] = OpTypeRuntimeArray [[S4]]
// CHECK: [[S4_buffer_runtime_arr_struct]] = OpTypeStruct [[S4_buffer_runtime_arr]]

// CHECK: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5

// CHECK: [[arr_uchar_uint_5]] = OpTypeArray [[uchar]] [[uint_5]]
// CHECK: [[S1_transformed]] = OpTypeStruct [[arr_uchar_uint_5]]
// CHECK: [[S1_buffer_runtime_arr]] = OpTypeRuntimeArray [[S1_transformed]]
// CHECK: [[S1_buffer_runtime_arr_struct]] = OpTypeStruct [[S1_buffer_runtime_arr]]

// CHECK: [[S2]] = OpTypeStruct [[uchar]] [[uint]]
// CHECK: [[S2_buffer_runtime_arr]] = OpTypeRuntimeArray [[S2]]
// CHECK: [[S2_buffer_runtime_arr_struct]] = OpTypeStruct [[S2_buffer_runtime_arr]]

// CHECK: [[ptr_StorageBuffer_uchar:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uchar]]
// CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK: [[ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: [[v4uchar:%[a-zA-Z0-9_]+]] = OpTypeVector [[uchar]] 4
// CHECK: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK: [[uint_6:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 6
// CHECK: [[ptr_StorageBuffer_arr_uchar_uint_5:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[arr_uchar_uint_5]]
// CHECK: [[ptr_StorageBuffer_arr_uchar_uint_7:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[arr_uchar_uint_7]]

// In functions
// CHECK: {{.*}} = OpFunction %void None {{.*}}
// CHECK: {{.*}} = OpFunction %void None {{.*}}
// CHECK: {{.*}} = OpFunction %void None {{.*}}
// CHECK: [[a_0_x_new_type:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_StorageBuffer_arr_uchar_uint_5]] {{.*}} [[uint_0]] [[uint_0]] [[uint_0]]
// CHECK: [[a_0_x_loaded:%[a-zA-Z0-9_]+]] = OpLoad [[arr_uchar_uint_5]] [[a_0_x_new_type]]
// CHECK: [[first_uchar_from_v4uchar:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uchar]] [[a_0_x_loaded]] 0
// CHECK: [[second_uchar_from_v4uchar:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uchar]] [[a_0_x_loaded]] 1
// CHECK: [[third_uchar_from_v4uchar:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uchar]] [[a_0_x_loaded]] 2
// CHECK: [[forth_uchar_from_v4uchar:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[uchar]] [[a_0_x_loaded]] 3
// CHECK: {{.*}} = OpCompositeInsert [[v4uchar]] [[first_uchar_from_v4uchar]] {{.*}} 0
// CHECK: {{.*}} = OpCompositeInsert [[v4uchar]] [[second_uchar_from_v4uchar]] {{.*}} 1
// CHECK: {{.*}} = OpCompositeInsert [[v4uchar]] [[third_uchar_from_v4uchar]] {{.*}} 2
// CHECK: {{.*}} = OpCompositeInsert [[v4uchar]] [[forth_uchar_from_v4uchar]] {{.*}} 3
// CHECK: [[a_0_x:%[a-zA-Z0-9_]+]] = OpBitcast [[uint]] {{.*}}
// CHECK: [[b_0_x:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_StorageBuffer_uint]] {{.*}} [[uint_0]] [[uint_0]] [[uint_1]]
// CHECK: OpStore [[b_0_x]] [[a_0_x]]
