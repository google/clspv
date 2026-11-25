// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 -inline-entry-points -DMEMORY_SCOPE_WORKGROUP_ONLY
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=WG_ONLY < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 -inline-entry-points -DDEVICE_ATOMIC
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=DEV_SCOPE < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 -inline-entry-points -DDEVICE_WG_BARRIER
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=DEV_SCOPE < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 --cl-std=CL2.0 -inline-entry-points -DDEVICE_FENCE
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=DEV_SCOPE < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 -no-16bit-storage=ssbo -DVSTORE_HALF
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=DEV_SCOPE < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -hack-psb-volatile-as-atomic -vulkan-memory-model -spv-version=1.5 -DPSB_VOLATILE
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=DEV_SCOPE < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// WG_ONLY: OpCapability VulkanMemoryModel
// WG_ONLY-NOT: OpCapability VulkanMemoryModelDeviceScope
// WG_ONLY: OpMemoryModel Logical Vulkan

// DEV_SCOPE-DAG: OpCapability VulkanMemoryModel
// DEV_SCOPE-DAG: OpCapability VulkanMemoryModelDeviceScope

#ifdef MEMORY_SCOPE_WORKGROUP_ONLY
kernel void test_wg(global int *out, local atomic_int *loc) {
  work_group_barrier(CLK_LOCAL_MEM_FENCE, memory_scope_work_group);
  *out = atomic_fetch_add_explicit(loc, 1, memory_order_relaxed, memory_scope_work_group);
}
#endif

#ifdef DEVICE_ATOMIC
kernel void test_dev_atomic(global atomic_int *a) {
  atomic_store_explicit(a, 42, memory_order_relaxed, memory_scope_device);
}
#endif

#ifdef DEVICE_WG_BARRIER
kernel void test_dev_barrier(global int *a) {
  work_group_barrier(CLK_GLOBAL_MEM_FENCE, memory_scope_device);
}
#endif

#ifdef DEVICE_FENCE
kernel void test_dev_fence(global int *a) {
  atomic_work_item_fence(CLK_GLOBAL_MEM_FENCE, memory_order_acq_rel, memory_scope_device);
}
#endif

#ifdef VSTORE_HALF
kernel void test_vstore_half(global int *out, float val, int n) {
  vstore_half(val, n, (global half *)out);
}
#endif

#ifdef PSB_VOLATILE
kernel void test_psb_volatile(global int *rw, global int *ro) {
  int b = rw[0];
  barrier(CLK_GLOBAL_MEM_FENCE);
  rw[1] = b + ro[0];
}
#endif
