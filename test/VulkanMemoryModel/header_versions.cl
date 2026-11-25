// RUN: not clspv %target %s -o %t.spv -vulkan-memory-model 2>&1 | FileCheck %s --check-prefix=ERR
// RUN: not clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.0 2>&1 | FileCheck %s --check-prefix=ERR

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV13 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV14 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV15 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.6
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV16 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.3 %t.spv

// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=PSB < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// ERR: error: -vulkan-memory-model requires SPIR-V 1.3 or higher

// CHECK-DAG: OpCapability Shader
// CHECK-DAG: OpCapability VulkanMemoryModel
// CHECK-NOT: OpCapability VulkanMemoryModelDeviceScope
// SPV13: OpExtension "SPV_KHR_vulkan_memory_model"
// SPV14: OpExtension "SPV_KHR_vulkan_memory_model"
// SPV15-NOT: OpExtension "SPV_KHR_vulkan_memory_model"
// SPV16-NOT: OpExtension "SPV_KHR_vulkan_memory_model"
// CHECK: OpMemoryModel Logical Vulkan

// PSB-DAG: OpCapability Shader
// PSB-DAG: OpCapability PhysicalStorageBufferAddresses
// PSB-DAG: OpCapability VulkanMemoryModel
// PSB-NOT: OpCapability VulkanMemoryModelDeviceScope
// PSB: OpMemoryModel PhysicalStorageBuffer64 Vulkan

kernel void test_header(global int *out, int x) {
  *out = x;
}
