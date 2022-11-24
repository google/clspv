// RUN: clspv %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv -verify

kernel void not_constant(global int* out, global atomic_flag *flag, global int *test) {
  memory_order order = memory_order_relaxed;
  const memory_order const_order = memory_order_relaxed;
  const memory_order unknown_order =
      test[0] ? memory_order_release : memory_order_relaxed;

  memory_scope scope = memory_scope_work_group;
  const memory_scope const_scope = memory_scope_work_group;
  const memory_scope unknown_scope =
      test[0] ? memory_scope_work_group : memory_scope_device;

  *out = atomic_flag_test_and_set_explicit(flag, const_order, memory_scope_work_group);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  *out = atomic_flag_test_and_set_explicit(flag, order, memory_scope_work_group);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  *out = atomic_flag_test_and_set_explicit(flag, unknown_order, memory_scope_work_group);

  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, const_scope);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, scope);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, unknown_scope);

  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  *out = atomic_flag_test_and_set_explicit(flag, order, scope);



  atomic_flag_clear_explicit(flag, const_order, memory_scope_work_group);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  atomic_flag_clear_explicit(flag, order, memory_scope_work_group);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  atomic_flag_clear_explicit(flag, unknown_order, memory_scope_work_group);

  atomic_flag_clear_explicit(flag, memory_order_relaxed, const_scope);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, scope);
  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, unknown_scope);

  // expected-error@+1{{Memory order and scope must be constant expressions when using the SPIR-V shader capability.}}
  atomic_flag_clear_explicit(flag, order, scope);
}

kernel void illegal_scope_global(global int *out, global atomic_flag *flag) {
  // "Whilst the CrossDevice scope is defined in SPIR-V, it is disallowed in Vulkan"
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_all_svm_devices);
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_all_devices);

  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_all_svm_devices);
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_all_devices);


  // "memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE. Requires support for OpenCL C 2.0 or newer."
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_item);
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_item);

  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_item);
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_item);
}

kernel void illegal_scope_local(global int *out, local atomic_flag *flag) {
  // "Whilst the CrossDevice scope is defined in SPIR-V, it is disallowed in Vulkan"
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_all_svm_devices);
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_all_devices);

  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_all_svm_devices);
  // expected-error@+1{{memory_scope_all_svm_devices/memory_scope_all_devices is not supported.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_all_devices);


  // "memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE. Requires support for OpenCL C 2.0 or newer."
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_item);
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  *out = atomic_flag_test_and_set_explicit(flag, memory_order_relaxed, memory_scope_work_item);

  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_item);
  // expected-error@+1{{memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE.}}
  atomic_flag_clear_explicit(flag, memory_order_relaxed, memory_scope_work_item);
}

kernel void atomic_flag_clear_order_global(global atomic_flag *flag) {
  // expected-error@+1{{The order of atomic_flag_clear_explicit cannot be memory_order_acquire/memory_order_acq_rel.}}
  atomic_flag_clear_explicit(flag, memory_order_acquire, memory_scope_work_group);
  // expected-error@+1{{The order of atomic_flag_clear_explicit cannot be memory_order_acquire/memory_order_acq_rel.}}
  atomic_flag_clear_explicit(flag, memory_order_acq_rel, memory_scope_work_group);
}

kernel void atomic_flag_clear_order_local(local atomic_flag *flag) {
  // expected-error@+1{{The order of atomic_flag_clear_explicit cannot be memory_order_acquire/memory_order_acq_rel.}}
  atomic_flag_clear_explicit(flag, memory_order_acquire, memory_scope_work_group);
  // expected-error@+1{{The order of atomic_flag_clear_explicit cannot be memory_order_acquire/memory_order_acq_rel.}}
  atomic_flag_clear_explicit(flag, memory_order_acq_rel, memory_scope_work_group);
}

