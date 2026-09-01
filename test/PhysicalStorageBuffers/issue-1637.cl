// RUN: clspv %s -o %t.spv --arch=spirv64 --physical-storage-buffers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// CHECK-DAG: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 1 Offset 4
// CHECK-DAG: OpMemberDecorate [[struct]] 0 Offset 0
// CHECK-DAG: OpMemberDecorate [[struct]] 2 Offset 9
// CHECK-DAG: OpDecorate [[ptr_struct:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK-DAG: [[ptr_struct]] = OpTypePointer PhysicalStorageBuffer [[struct]]
// CHECK-DAG: [[ptr_uchar:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer %uchar
// CHECK: [[bitcast:%[a-zA-Z0-9_]+]] = OpBitcast [[ptr_struct]]
// CHECK: OpPtrAccessChain [[ptr_struct]] [[bitcast]]

struct S12 {
    int a;
    char b[5];
    char c[7];
};

__kernel void test_kernel(__global void *buf, ulong gid, ulong lid)
{
    __global uchar *base = (__global uchar *)buf + (gid * 320);
    __global struct S12 *s_ptr = (__global struct S12 *)base + lid;
    struct S12 val = *s_ptr;

    __global struct S12 *w_ptr = (__global struct S12 *)buf + lid;
    __global uchar *w_byte = (__global uchar *)w_ptr + (gid * 320);
    *(__global uchar *)w_byte = val.b[0];
}
