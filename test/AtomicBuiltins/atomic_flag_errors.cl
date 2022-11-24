// RUN: clspv %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv -verify

kernel void flag_global(global atomic_flag *flag, global int *test) {
  memory_order order = memory_order_relaxed;
  const memory_order const_order = memory_order_relaxed;
  const memory_order unknown_order =
      test[0] ? memory_order_release : memory_order_relaxed;

  memory_scope scope = memory_scope_work_group;
  const memory_scope const_scope = memory_scope_work_group;
  const memory_scope unknown_scope =
      test[0] ? memory_scope_work_group : memory_scope_device;

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
