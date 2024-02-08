// RUN: clspv %s -o %t.spv -rewrite-packed-structs -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

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

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[char_array:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[uchar]]
// CHECK-DAG: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[char_array]]
// CHECK-DAG: [[block_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK-DAG: OpDecorate [[char_array]] ArrayStride 1
// CHECK-DAG: OpVariable [[block_ptr]] StorageBuffer
// CHECK-DAG: OpVariable [[block_ptr]] StorageBuffer
// CHECK-DAG: OpVariable [[block_ptr]] StorageBuffer
