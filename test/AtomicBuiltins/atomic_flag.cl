// RUN: clspv %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: spirv-dis %t.spv | FileCheck %s

// CHECK-DAG: OpEntryPoint GLCompute %[[flag_global:[a-zA-Z0-9_]+]] "flag_global"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_local:[a-zA-Z0-9_]+]] "flag_local"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_set_partial_explicit_global:[a-zA-Z0-9_]+]] "flag_set_partial_explicit_global"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_set_partial_explicit_local:[a-zA-Z0-9_]+]] "flag_set_partial_explicit_local"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_clear_partial_explicit_global:[a-zA-Z0-9_]+]] "flag_clear_partial_explicit_global"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_clear_partial_explicit_local:[a-zA-Z0-9_]+]] "flag_clear_partial_explicit_local"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_set_full_explicit_global:[a-zA-Z0-9_]+]] "flag_set_full_explicit_global"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_set_full_explicit_local:[a-zA-Z0-9_]+]] "flag_set_full_explicit_local"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_clear_full_explicit_global:[a-zA-Z0-9_]+]] "flag_clear_full_explicit_global"
// CHECK-DAG: OpEntryPoint GLCompute %[[flag_clear_full_explicit_local:[a-zA-Z0-9_]+]] "flag_clear_full_explicit_local"

// CHECK-DAG: %[[UINT:[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[BOOL:[a-zA-Z0-9_]+]] = OpTypeBool

// CHECK-DAG: %[[UINT_0:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 0

// 1 = Device Scope
// CHECK-DAG: %[[UINT_1:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 1
// 2 = Workgroup Scope
// CHECK-DAG: %[[UINT_2:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 2

// dec 64 = hex 40 = UniformMemory
// CHECK-DAG: %[[UINT_64:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 64
// dec 66 = hex 42 = Acquire & UniformMemory
// CHECK-DAG: %[[UINT_66:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 66
// dec 68 = hex 44 = Release & UniformMemory
// CHECK-DAG: %[[UINT_68:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 68
// dec 72 = hex 48 = AcquireRelease & UniformMemory
// CHECK-DAG: %[[UINT_72:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 72

// dec 256 = hex 100 WorkgroupMemory
// CHECK-DAG: %[[UINT_256:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 256
// dec 258 = hex 102 Acquire & WorkgroupMemory
// CHECK-DAG: %[[UINT_258:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 258
// dec 260 = hex 104 Release & WorkgroupMemory
// CHECK-DAG: %[[UINT_260:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 260 
// dec 264 = hex 108 AcquireRelease & WorkgroupMemory
// CHECK-DAG: %[[UINT_264:[a-zA-Z0-9_]+]] = OpConstant %[[UINT]] 264

// Note: Device Scope is the default scope
// Note: SequentiallyConsistent is the default order

// CHECK: %[[flag_global]] = OpFunction %void
kernel void flag_global(global int *out, global atomic_flag *flag) {
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set(flag);

// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear(flag);
}

// CHECK: %[[flag_local]] = OpFunction %void
kernel void flag_local(global int *out, local atomic_flag *flag) {
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set(flag);

// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear(flag);
}

// explicit scope

// CHECK: %[[flag_set_partial_explicit_global]] = OpFunction %void
kernel void flag_set_partial_explicit_global(global int *out, global atomic_flag *flag) {

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_66]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_64]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed);
}

// CHECK: %[[flag_set_partial_explicit_local]] = OpFunction %void
kernel void flag_set_partial_explicit_local(global int *out, local atomic_flag *flag) {
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_258]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed);
}

// CHECK: %[[flag_clear_partial_explicit_global]] = OpFunction %void
kernel void flag_clear_partial_explicit_global(global atomic_flag *flag) {
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst);

// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release);

// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_64]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed);
}

// CHECK: %[[flag_clear_partial_explicit_local]] = OpFunction %void
kernel void flag_clear_partial_explicit_local(local atomic_flag *flag) {
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst);

// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release);

// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed);
}

// explicit order and scope

// CHECK: %[[flag_set_full_explicit_global]] = OpFunction %void
kernel void flag_set_full_explicit_global(global int *out, global atomic_flag *flag) {

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_66]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_64]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_sub_group);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_66]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_64]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_group);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_72]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_66]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_64]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_device);

}

// CHECK: %[[flag_set_full_explicit_local]] = OpFunction %void
kernel void flag_set_full_explicit_local(global int *out, local atomic_flag *flag) {

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_258]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_sub_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_sub_group);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_258]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_work_group);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_group);

// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_seq_cst, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_264]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acq_rel, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_258]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_acquire, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_260]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_release, memory_scope_device);
// CHECK: %[[previous_value:[a-zA-Z0-9_]+]] = OpAtomicExchange %[[UINT]] {{.*}} %[[UINT_1]] %[[UINT_256]] %[[UINT_1]]
// CHECK: OpIEqual %bool %[[previous_value]] %[[UINT_1]]
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_device);

}

// CHECK: %[[flag_clear_full_explicit_global]] = OpFunction %void
 kernel void flag_clear_full_explicit_global(global atomic_flag *flag) {
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_sub_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_sub_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_64]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_sub_group);
  
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_work_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_work_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_64]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_group);
  
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_device);
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_68]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_device);
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_64]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_device);
  
}

// CHECK: %[[flag_clear_full_explicit_local]] = OpFunction %void
 kernel void flag_clear_full_explicit_local(local atomic_flag *flag) {

// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_sub_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_sub_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_sub_group);
  
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_work_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_work_group);
// CHECK: OpAtomicStore {{.*}} %[[UINT_2]] %[[UINT_256]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_group);
  
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_seq_cst, memory_scope_device);
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_260]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_release, memory_scope_device);
// CHECK: OpAtomicStore {{.*}} %[[UINT_1]] %[[UINT_256]] %[[UINT_0]]
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_device);
}
