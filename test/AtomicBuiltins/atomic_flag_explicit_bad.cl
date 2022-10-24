// "memory_scope_work_item can only be used with atomic_work_item_fence with flags set to CLK_IMAGE_MEM_FENCE. Requires support for OpenCL C 2.0 or newer."
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_release -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_relaxed -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_acquire -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_release -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_relaxed -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_release -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_relaxed -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_acquire -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_release -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_relaxed -DSCOPE=memory_scope_work_item %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv

// "Whilst the CrossDevice scope is defined in SPIR-V, it is disallowed in Vulkan"
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_release -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=global -DORDER=memory_order_relaxed -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_acquire -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_release -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=1 -DADDR_SPACE=local  -DORDER=memory_order_relaxed -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_release -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_relaxed -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_seq_cst -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_acquire -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_release -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=local  -DORDER=memory_order_relaxed -DSCOPE=memory_scope_all_svm_devices %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv


// (when using atomic_flag_clear) "The order argument shall not be memory_order_acquire nor memory_order_acq_rel"
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_sub_group %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_work_group %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acquire -DSCOPE=memory_scope_device %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_sub_group %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_work_group %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv
// RUN: not clspv -DTEST_AND_SET=0 -DADDR_SPACE=global -DORDER=memory_order_acq_rel -DSCOPE=memory_scope_device %s --cl-std=CL3.0 --use-native-builtins=atomic_flag_test_and_set,atomic_flag_clear -o %t.spv


// all these tests are expected to cause the compiler to fatally error

#if TEST_AND_SET == 1
kernel void flag_set_full_explicit_global(global int *out, ADDR_SPACE atomic_flag *flag) {
  *out = atomic_flag_test_and_set_explicit(flag, ORDER, SCOPE);
}
#elif TEST_AND_SET == 0
kernel void flag_set_full_explicit_global(ADDR_SPACE atomic_flag *flag) {
  atomic_flag_clear_explicit(flag, ORDER, SCOPE);
}
#endif
