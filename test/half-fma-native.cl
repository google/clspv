// RUN: clspv %target  %s -o %t.spv --use-native-builtins=fma
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target  %s -o %t.spv -cl-mad-enable
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability Float16
// CHECK: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK: [[a:%[^ ]+]] = OpLoad [[half]]
// CHECK: [[b:%[^ ]+]] = OpLoad [[half]]
// CHECK: [[c:%[^ ]+]] = OpLoad [[half]]
// CHECK: [[fma:%[^ ]+]] = OpExtInst [[half]] {{.*}} Fma [[a]] [[b]] [[c]]
// CHECK: OpStore {{.*}} [[fma]]
#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global half *dst, global half *srcA, global half *srcB, global half *srcC) {
    int gid = get_global_id(0);
    dst[gid] = srcA[gid] * srcB[gid] + srcC[gid];
}
