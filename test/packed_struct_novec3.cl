// RUN: clspv -uniform-workgroup-size %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

struct S1{
    int3 x;
    int y;
} __attribute__((packed));

struct S2{
    int3 x;
    int y;
};

__kernel void test(__global int *a) {
    int gid = get_global_id(0);
    __local struct S1 s1[64];
    __local struct S2 s2[64];
    s1[gid].x[0] = a[gid + 0];
    s1[gid].x[1] = a[gid + 1];
    s1[gid].x[2] = a[gid + 2];
    s1[gid].y = a[gid + 3];

    s2[gid].x[0] = a[gid + 4];
    s2[gid].x[1] = a[gid + 5];
    s2[gid].x[2] = a[gid + 6];
    s2[gid].y = a[gid + 7];

    barrier(CLK_LOCAL_MEM_FENCE);

    a[gid + 0] = s1[gid].x[0];
    a[gid + 1] = s1[gid].x[1];
    a[gid + 2] = s1[gid].x[2];
    a[gid + 3] = s1[gid].y;

    a[gid + 4] = s2[gid].x[0];
    a[gid + 5] = s2[gid].x[1];
    a[gid + 6] = s2[gid].x[2];
    a[gid + 7] = s2[gid].y;
}


// CHECK-DAG: [[uchar:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uintv3:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[uintv4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[uintinput:%[^ ]+]] = OpTypePointer Input [[uint]]
// CHECK-DAG: [[uintv3input:%[^ ]+]] = OpTypePointer Input [[uintv3]]
// CHECK-DAG: [[uintworkgroup:%[^ ]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-DAG: [[uintv3workgroup:%[^ ]+]] = OpTypePointer Workgroup [[uintv3]]
// CHECK-DAG: [[uintv4workgroup:%[^ ]+]] = OpTypePointer Workgroup [[uintv4]]
// CHECK-DAG: [[uint12:%[^ ]+]] = OpConstant [[uint]] 12
// CHECK-DAG: [[uint64:%[^ ]+]] = OpConstant [[uint]] 64
// CHECK-DAG: [[uchararray12:%[^ ]+]] = OpTypeArray [[uchar]] [[uint12]]
// CHECK-DAG: [[S1:%[^ ]+]] = OpTypeStruct [[uintv3]] [[uint]]
// CHECK-DAG: [[S2:%[^ ]+]] = OpTypeStruct [[uintv4]] [[uint]] [[uchararray12]]
// CHECK-DAG: [[S1array:%[^ ]+]] = OpTypeArray [[S1]] [[uint64]]
// CHECK-DAG: [[S2array:%[^ ]+]] = OpTypeArray [[S2]] [[uint64]]
// CHECK-DAG: [[S1arrayptr:%[^ ]+]] = OpTypePointer Workgroup [[S1array]]
// CHECK-DAG: [[S2arrayptr:%[^ ]+]] = OpTypePointer Workgroup [[S2array]]
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK: [[s1:%[^ ]+]] = OpVariable [[S1arrayptr]] Workgroup
// CHECK: [[s2:%[^ ]+]] = OpVariable [[S2arrayptr]] Workgroup
// CHECK: [[gidptr:%[^ ]+]] = OpVariable [[uintv3input]] Input
// CHECK: [[gidgep:%[^ ]+]] = OpAccessChain [[uintinput]] [[gidptr]] [[uint0]]
// CHECK: [[gid:%[^ ]+]] = OpLoad [[uint]] [[gidgep]]
// CHECK: [[_0:%[^ ]+]] = OpAccessChain [[uintv3workgroup]] [[s1]] [[gid]] [[uint0]]
// CHECK: [[_1:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s1]] [[gid]] [[uint1]]
// CHECK: [[_2:%[^ ]+]] = OpAccessChain [[uintv4workgroup]] [[s2]] [[gid]] [[uint0]]
// CHECK: [[_3:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[gid]] [[uint1]]
