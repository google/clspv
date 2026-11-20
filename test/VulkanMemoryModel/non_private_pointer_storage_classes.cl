// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 -constant-args-ubo -std430-ubo-layout
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 --uniform-buffer-standard-layout %t.spv

// RUN: clspv %s -o %t.spv -arch=spirv64 -physical-storage-buffers -vulkan-memory-model -spv-version=1.5 -DPSB_TEST
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=PSB < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 -DCOHERENT_SHARING_TEST
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=SHARING < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 %t.spv

// RUN: clspv %target %s -o %t.spv -vulkan-memory-model -spv-version=1.3 -DCONST_PHI_TEST
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=CONST_PHI < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.1 --relax-logical-pointer %t.spv

// CHECK: OpCapability VulkanMemoryModel
// CHECK: OpMemoryModel Logical Vulkan
// CHECK-NOT: OpDecorate {{.*}} Coherent

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[ptr_ssbo:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK-DAG: [[ptr_ubo:%[a-zA-Z0-9_]+]] = OpTypePointer Uniform [[uint]]
// CHECK-DAG: [[ptr_wg:%[a-zA-Z0-9_]+]] = OpTypePointer Workgroup [[uint]]
// CHECK-DAG: [[pc_var:%[a-zA-Z0-9_]+]] = OpVariable {{%[a-zA-Z0-9_]+}} PushConstant
// CHECK-DAG: [[ptr_priv:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CHECK-DAG: [[ptr_input:%[a-zA-Z0-9_]+]] = OpTypePointer Input [[uint]]

// PushConstant load must NOT have NonPrivatePointer
// CHECK: [[pc_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain {{%[a-zA-Z0-9_]+}} [[pc_var]]
// CHECK-NEXT: OpLoad {{.*}} [[pc_ptr]] Aligned 4{{$}}

// Input load must NOT have NonPrivatePointer
// CHECK: [[in_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_input]]
// CHECK-NEXT: OpLoad [[uint]] [[in_ptr]] Aligned 16{{$}}

// StorageBuffer load must have NonPrivatePointer
// CHECK: [[ssbo_in_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo]]
// CHECK-NEXT: OpLoad [[uint]] [[ssbo_in_ptr]] Aligned|NonPrivatePointer 4{{$}}

// Uniform (UBO) load must have NonPrivatePointer
// CHECK: [[ubo_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ubo]]
// CHECK-NEXT: OpLoad [[uint]] [[ubo_ptr]] Aligned|NonPrivatePointer 4{{$}}

// Workgroup store and load must have NonPrivatePointer
// CHECK: [[wg_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_wg]]
// CHECK: OpStore [[wg_ptr]] {{.*}} Aligned|NonPrivatePointer 4{{$}}
// CHECK: OpControlBarrier
// CHECK: [[wg_ptr2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_wg]]
// CHECK: OpLoad [[uint]] [[wg_ptr2]] Aligned|NonPrivatePointer 4{{$}}

// ModuleScopePrivate (__constant array) load must NOT have NonPrivatePointer
// CHECK: [[priv_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_priv]]
// CHECK-NEXT: OpLoad [[uint]] [[priv_ptr]] Aligned 4{{$}}

// StorageBuffer store must have NonPrivatePointer
// CHECK: [[ssbo_out_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr_ssbo]]
// CHECK: OpStore [[ssbo_out_ptr]] {{.*}} Aligned|NonPrivatePointer 4{{$}}

// PSB: OpCapability VulkanMemoryModel
// PSB: OpMemoryModel PhysicalStorageBuffer64 Vulkan
// PSB: OpLoad {{.*}} Aligned|NonPrivatePointer 4{{$}}
// PSB: OpStore {{.*}} Aligned|NonPrivatePointer 4{{$}}

// SHARING: OpCapability VulkanMemoryModel
// SHARING: OpMemoryModel Logical Vulkan
// SHARING-NOT: OpDecorate {{.*}} Coherent
// SHARING: OpDecorate [[b0:%[a-zA-Z0-9_]+]] Binding 0
// SHARING-NOT: OpDecorate {{.*}} Binding 0
// SHARING: OpDecorate [[b1:%[a-zA-Z0-9_]+]] Binding 1
// SHARING-NOT: OpDecorate {{.*}} Coherent
// SHARING-DAG: OpLoad {{.*}} Aligned|NonPrivatePointer 4{{$}}
// SHARING-DAG: OpStore {{.*}} Aligned|NonPrivatePointer 4{{$}}

// CONST_PHI: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CONST_PHI: [[ptr_priv:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[uint]]
// CONST_PHI: [[priv_phi:%[a-zA-Z0-9_]+]] = OpPhi [[ptr_priv]]
// CONST_PHI: OpLoad [[uint]] [[priv_phi]] Aligned 4{{$}}

#ifdef PSB_TEST
kernel void test_psb(global int *out, global const int *in) {
  *out = *in;
}
#elif defined(COHERENT_SHARING_TEST)
__attribute__((noinline))
int read_helper(global int *p) { return p[0]; }

__attribute__((noinline))
void write_helper(global int *p, int v) { *p = v; }

kernel void foo1(global int *data) {
  int x = read_helper(data);
  barrier(CLK_GLOBAL_MEM_FENCE);
  data[1] = x;
}

kernel void foo2(global int *x, global int *y, int c) {
  int z = read_helper(x);
  barrier(CLK_GLOBAL_MEM_FENCE);
  global int *ptr = c ? x : y;
  write_helper(ptr + 1, z);
}
#elif defined(CONST_PHI_TEST)
static __constant int kTable[4] = {10, 20, 30, 40};

kernel void test_const_phi(global int *out, local int *scratch, int c) {
  size_t gid = get_global_id(0);
  __constant int *cptr = &kTable[1];
  if (c > 0) {
    scratch[0] = c;
    cptr = &kTable[gid & 3];
  }
  out[gid] = *cptr;
}
#else
static __constant int kTable[4] = {10, 20, 30, 40};

kernel void test_storage_classes(global int *out,
                                 global const int *in,
                                 constant int *ubo,
                                 local int *scratch,
                                 int pod_scalar) {
  size_t gid = get_global_id(0);
  int v_in = in[gid];
  int v_ubo = ubo[gid];
  scratch[get_local_id(0)] = v_in + v_ubo + pod_scalar;
  barrier(CLK_LOCAL_MEM_FENCE);
  int v_wg = scratch[get_local_id(0)];
  int v_const = kTable[gid & 3];
  out[gid] = v_wg + v_const;
}
#endif
