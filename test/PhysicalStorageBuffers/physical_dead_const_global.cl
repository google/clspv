// RUN: clspv %s -o %t.spv -arch=spir64 -physical-storage-buffers -module-constants-in-storage-buffer
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__constant float myconst[4] = {
    1.0000000000f, 0.0000000149f, -2.5000002384f, -0.0000000894f,
};

__kernel void test(__global float* a) {
    a[0] = myconst[2];
}

// CHECK: OpExtension "SPV_KHR_physical_storage_buffer"
// CHECK: [[ClspvReflection:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: OpMemoryModel PhysicalStorageBuffer64
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 8

// CHECK: [[KernelReflection:%[a-zA-Z0-9_]+]] = OpExtInst %void [[ClspvReflection]] Kernel
// CHECK-PC: OpExtInst %void [[ClspvReflection]] ArgumentPointerPushConstant [[KernelReflection]] [[uint_0]] [[uint_0]] [[uint_8]]
