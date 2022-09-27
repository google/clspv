// RUN: clspv %target %s -o %t.spv -long-vector
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct S{
    int8 x;
    int y;
};

__kernel void test(__global int *a) {
    size_t gid = get_global_id(0);
    __local struct S s[64];
    s[gid].x[0] = a[gid + 0];
    s[gid].x[1] = a[gid + 1];
    s[gid].x[2] = a[gid + 2];
    s[gid].x[3] = a[gid + 3];
    s[gid].x[4] = a[gid + 4];
    s[gid].x[5] = a[gid + 5];
    s[gid].x[6] = a[gid + 6];
    s[gid].x[7] = a[gid + 7];
    s[gid].y = a[gid + 8];

    barrier(CLK_LOCAL_MEM_FENCE);

    a[gid + 0] = s[gid].x[0];
    a[gid + 1] = s[gid].x[1];
    a[gid + 2] = s[gid].x[2];
    a[gid + 3] = s[gid].x[3];
    a[gid + 4] = s[gid].x[4];
    a[gid + 5] = s[gid].x[5];
    a[gid + 6] = s[gid].x[6];
    a[gid + 7] = s[gid].x[7];
    a[gid + 8] = s[gid].y;
}


// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint8:%[^ ]+]] = OpConstant [[uint]] 8
// CHECK-DAG: [[uint28:%[^ ]+]] = OpConstant [[uint]] 28
// CHECK-DAG: [[uint64:%[^ ]+]] = OpConstant [[uint]] 64
// CHECK-DAG: [[arrayuint8:%[^ ]+]] = OpTypeArray [[uint]] [[uint8]]
// CHECK-DAG: [[padding:%[^ ]+]] = OpTypeArray [[uchar]] [[uint28]]
// CHECK-DAG: [[S:%[^ ]+]] = OpTypeStruct [[arrayuint8]] [[uint]] [[padding]]
// CHECK-DAG: [[Sarray:%[^ ]+]] = OpTypeArray [[S]] [[uint64]]
// CHECK-DAG: [[Sarrayptr:%[^ ]+]] = OpTypePointer Workgroup [[Sarray]]
// CHECK: [[s:%[^ ]+]] = OpVariable [[Sarrayptr]] Workgroup
