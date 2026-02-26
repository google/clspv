// RUN: clspv %target %s -o %t.spv --hack-logical-ptrtoint -cl-kernel-arg-info -spv-version=1.6
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.3 %t.spv

// CHECK: [[uint:%[a-zA-Z]+]] = OpTypeInt 32 0
// CHECK: [[uint0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK: [[nullptr:%[0-9]+]] = OpConstantNull %{{[a-zA-Z0-9_]+}}
// CHECK: [[bool:%[a-zA-Z]+]] = OpTypeBool
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} [[uint0]] [[uint0]]
// CHECK: [[cmp:%[a-zA-Z0-9_]+]] = OpPtrNotEqual [[bool]] [[ptr]] [[nullptr]]

kernel void test_kernel(global float *src, global long *dst)
{
    uint tid = get_global_id(0);
    dst[tid] = (long)(src != 0);
}
