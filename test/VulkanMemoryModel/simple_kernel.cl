// RUN: clspv %target -o %t.spv < %s -vulkan-memory-model -spv-version=1.5
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2spv1.5 %t.spv

// CHECK: OpCapability Shader
// CHECK: OpCapability VulkanMemoryModel
// CHECK: OpMemoryModel Logical Vulkan
void kernel foo()
{
}
