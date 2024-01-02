// RUN: clspv %target %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__ ((noinline))
static void test_func_inner(global void* in, global void* out, size_t i) {
  global int* in_ptr = (global int*) in;
  global int* out_ptr = (global int*) out;

  out_ptr[i] = in_ptr[i];
}

__attribute__ ((noinline))
static void test_func(global void* in, global void* out, size_t i) {
  test_func_inner(in, out, i);
}

void kernel test_a(global int* a, global int* b, int n) {
  test_func(&a[n], &b[n], get_global_id(0));
}

void kernel test_b(global short* a, global short* b, int n) {
  test_func(&a[n], &b[n], get_global_id(0));
}

void kernel test_c(global char* a, global char* b, int n) {
  test_func(&a[n], &b[n], get_global_id(0));
}

// Check that the right amount of data is being loaded and stored for each
// function

// CHECK-DAG: %[[uchar:[a-zA-Z0-9_]+]] = OpTypeInt 8
// CHECK-DAG: %[[ushort:[a-zA-Z0-9_]+]] = OpTypeInt 16
// CHECK-DAG: %[[uint:[a-zA-Z0-9_]+]] = OpTypeInt 32

// CHECK-DAG: %[[ptr_storage_buff_uchar:[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer %[[uchar]]
// CHECK-DAG: %[[ptr_storage_buff_ushort:[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer %[[ushort]]
// CHECK-DAG: %[[ptr_storage_buff_uint:[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer %[[uint]]


// CHECK: %[[ptr_ld_ushort_0:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_ushort]]
// CHECK: OpLoad %[[ushort]] %[[ptr_ld_ushort_0]]
// CHECK: %[[ptr_ld_ushort_1:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_ushort]]
// CHECK: OpLoad %[[ushort]] %[[ptr_ld_ushort_1]]

// CHECK: %[[ptr_st_ushort_0:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_ushort]]
// CHECK: OpStore %[[ptr_st_ushort_0]]
// CHECK: %[[ptr_st_ushort_1:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_ushort]]
// CHECK: OpStore %[[ptr_st_ushort_1]]


// CHECK: %[[ptr_ld_uchar_0:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpLoad %[[uchar]] %[[ptr_ld_uchar_0]]
// CHECK: %[[ptr_ld_uchar_1:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpLoad %[[uchar]] %[[ptr_ld_uchar_1]]
// CHECK: %[[ptr_ld_uchar_2:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpLoad %[[uchar]] %[[ptr_ld_uchar_2]]
// CHECK: %[[ptr_ld_uchar_3:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpLoad %[[uchar]] %[[ptr_ld_uchar_3]]

// CHECK: %[[ptr_st_uchar_0:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpStore %[[ptr_st_uchar_0]]
// CHECK: %[[ptr_st_uchar_1:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpStore %[[ptr_st_uchar_1]]
// CHECK: %[[ptr_st_uchar_2:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpStore %[[ptr_st_uchar_2]]
// CHECK: %[[ptr_st_uchar_3:[a-zA-Z0-9_]+]] = OpAccessChain %[[ptr_storage_buff_uchar]]
// CHECK: OpStore %[[ptr_st_uchar_3]]


// CHECK: %[[ptr_ld_uint:[a-zA-Z0-9_]+]] = OpPtrAccessChain %[[ptr_storage_buff_uint]]
// CHECK: OpLoad %[[uint]] %[[ptr_ld_uint]]
// CHECK: %[[ptr_st_uint:[a-zA-Z0-9_]+]] = OpPtrAccessChain %[[ptr_storage_buff_uint]]
// CHECK: OpStore %[[ptr_st_uint]]
