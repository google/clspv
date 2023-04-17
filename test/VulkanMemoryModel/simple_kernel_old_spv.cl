// RUN: clspv %target -o %t.spv < %s -vulkan-memory-model
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpCapability Shader
// CHECK: OpCapability VulkanMemoryModel
// CHECK: OpExtension "SPV_KHR_vulkan_memory_model"
// CHECK: OpMemoryModel Logical Vulkan
void kernel foo()
{
}
