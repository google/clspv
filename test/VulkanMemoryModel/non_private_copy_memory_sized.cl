// RUN: clspv %target %s -o %t.spv -vulkan-memory-model --untyped-pointers -spv-version=1.3
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV13 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model --untyped-pointers -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefixes=CHECK,SPV14 < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

// CHECK: OpCapability VulkanMemoryModel
// CHECK: OpMemoryModel Logical Vulkan

// Copy from Private (__constant) to StorageBuffer is lowered to load/store so
// the store to StorageBuffer gets NonPrivatePointer while the load from Private
// does not.
// CHECK: OpLoad {{.*}} Aligned 4{{$}}
// CHECK: OpStore {{.*}} Aligned|NonPrivatePointer 4{{$}}

// Copy from StorageBuffer to StorageBuffer:
// Both SPV 1.3 and SPV 1.4 have NonPrivatePointer on StorageBuffer operands.
// SPV13: OpCopyMemorySized {{.*}} Aligned|NonPrivatePointer 4{{$}}
// SPV14: OpCopyMemorySized {{.*}} Aligned|NonPrivatePointer 4 Aligned|NonPrivatePointer 4{{$}}

struct S {
  int data[16];
};

static __constant struct S kConstS = {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}};

kernel void test_memcpy(global struct S *dst1, global struct S *dst2, global const struct S *src) {
  *dst1 = kConstS;
  *dst2 = *src;
}
