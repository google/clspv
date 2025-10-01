// RUN: clspv %s -o %t.spv -vec3-to-vec4 -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -vec3-to-vec4 -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
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


// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-64-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
// CHECK-DAG: [[uintv3:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[uintinput:%[^ ]+]] = OpTypePointer Input [[uint]]
// CHECK-DAG: [[uintv3input:%[^ ]+]] = OpTypePointer Input [[uintv3]]
// CHECK-DAG: [[uintworkgroup:%[^ ]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-DAG: [[uintv3workgroup:%[^ ]+]] = OpTypePointer Workgroup [[uintv3]]
// CHECK-DAG: [[uint64:%[^ ]+]] = OpConstant [[uint]] 64
// CHECK-DAG: [[uint512:%[^ ]+]] = OpConstant [[uint]] 512
// CHECK-DAG: [[S1:%[^ ]+]] = OpTypeStruct [[uintv3]] [[uint]]
// CHECK-DAG: [[S1array:%[^ ]+]] = OpTypeArray [[S1]] [[uint64]]
// CHECK-DAG: [[S2array:%[^ ]+]] = OpTypeArray [[uint]] [[uint512]]
// CHECK-DAG: [[S1arrayptr:%[^ ]+]] = OpTypePointer Workgroup [[S1array]]
// CHECK-DAG: [[S2arrayptr:%[^ ]+]] = OpTypePointer Workgroup [[S2array]]
// CHECK-DAG: [[uint0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint2:%[^ ]+]] = OpConstant [[uint]] 2
// CHECK-32-DAG: [[uint3:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-32-DAG: [[uint4:%[^ ]+]] = OpConstant [[uint]] 4
// CHECK-32-DAG: [[uint5:%[^ ]+]] = OpConstant [[uint]] 5
// CHECK-64-DAG: [[ulong1:%[^ ]+]] = OpConstant [[ulong]] 1
// CHECK-64-DAG: [[ulong2:%[^ ]+]] = OpConstant [[ulong]] 2
// CHECK-64-DAG: [[ulong3:%[^ ]+]] = OpConstant [[ulong]] 3
// CHECK-64-DAG: [[ulong4:%[^ ]+]] = OpConstant [[ulong]] 4
// CHECK-64-DAG: [[ulong5:%[^ ]+]] = OpConstant [[ulong]] 5
// CHECK: [[s1:%[^ ]+]] = OpVariable [[S1arrayptr]] Workgroup
// CHECK: [[s2:%[^ ]+]] = OpVariable [[S2arrayptr]] Workgroup
// CHECK: [[gidptr:%[^ ]+]] = OpVariable [[uintv3input]] Input
// CHECK: [[gidgep:%[^ ]+]] = OpAccessChain [[uintinput]] [[gidptr]] [[uint0]]
// CHECK: [[gid:%[^ ]+]] = OpLoad [[uint]] [[gidgep]]

// CHECK-64: [[gid_long:%[^ ]+]] = OpSConvert [[ulong]] [[gid]]
// CHECK-64: [[_0:%[^ ]+]] = OpAccessChain [[uintv3workgroup]] [[s1]] [[gid_long]] [[uint0]]
// CHECK-64: [[_1:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s1]] [[gid_long]] [[uint1]]
// CHECK-64: [[shl_5_long:%[^ ]+]] = OpShiftLeftLogical [[ulong]] [[gid_long]] [[ulong5]]
// CHECK-64: [[gid_times_8:%[^ ]+]] = OpShiftRightLogical [[ulong]] [[shl_5_long]] [[ulong2]]
// CHECK-64: [[_2:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[gid_times_8]]
// CHECK-64: [[id:%[^ ]+]] = OpIAdd [[ulong]] [[gid_times_8]] [[ulong1]]
// CHECK-64: [[_2:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]
// CHECK-64: [[id:%[^ ]+]] = OpIAdd [[ulong]] [[gid_times_8]] [[ulong2]]
// CHECK-64: [[_2:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]
// CHECK-64: [[id:%[^ ]+]] = OpIAdd [[ulong]] [[gid_times_8]] [[ulong4]]
// CHECK-64: [[_2:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]

// CHECK-32: [[_0:%[^ ]+]] = OpAccessChain [[uintv3workgroup]] [[s1]] [[gid]] [[uint0]]
// CHECK-32: [[_1:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s1]] [[gid]] [[uint1]]
// CHECK-32: [[shl_5:%[^ ]+]] = OpShiftLeftLogical [[uint]] [[gid]] [[uint5]]
// CHECK-32: [[gid_times_8:%[^ ]+]] = OpShiftRightLogical [[uint]] [[shl_5]] [[uint2]]
// CHECK-32: [[_2:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[gid_times_8]]
// CHECK-32: [[id:%[^ ]+]] = OpIAdd [[uint]] [[gid_times_8]] [[uint1]]
// CHECK-32: [[_3:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]
// CHECK-32: [[id:%[^ ]+]] = OpIAdd [[uint]] [[gid_times_8]] [[uint2]]
// CHECK-32: [[_4:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]
// CHECK-32: [[id:%[^ ]+]] = OpIAdd [[uint]] [[gid_times_8]] [[uint4]]
// CHECK-32: [[_5:%[^ ]+]] = OpAccessChain [[uintworkgroup]] [[s2]] [[id]]
