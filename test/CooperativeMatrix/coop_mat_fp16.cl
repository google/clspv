// RUN: clspv %target %s -o %t.spv --spv-version=1.6
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: spirv-val --target-env vulkan1.3 %t.spv
// RUN: FileCheck %s < %t2.spvasm

// CHECK-DAG: OpCapability CooperativeMatrixKHR{{$}}
// CHECK-DAG: OpCapability VulkanMemoryModel{{$}}
// CHECK-DAG: OpExtension "SPV_KHR_cooperative_matrix"
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[half:%[^ ]+]] = OpTypeFloat 16
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[subgroup:%[^ ]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[dim:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[mat_a:%[^ ]+]] = OpTypeCooperativeMatrixKHR [[half]] [[subgroup]] [[dim]] [[dim]] {{%[^ ]+}}
// CHECK-DAG: [[mat_c:%[^ ]+]] = OpTypeCooperativeMatrixKHR [[float]] [[subgroup]] [[dim]] [[dim]] {{%[^ ]+}}
// CHECK: OpCooperativeMatrixLoadKHR [[mat_a]]
// CHECK: OpCooperativeMatrixMulAddKHR [[mat_c]] {{%[^ ]+}} {{%[^ ]+}} {{%[^ ]+}}{{$|.*}} 
// CHECK: OpCooperativeMatrixStoreKHR

#define TILE_M 16
#define TILE_N 16
#define TILE_K 16

typedef half
    __attribute__((coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_M,
                            TILE_K, CLK_COOPERATIVE_MATRIX_A))) mat_a_t;
typedef half
    __attribute__((coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_K,
                            TILE_N, CLK_COOPERATIVE_MATRIX_B))) mat_b_t;
typedef float __attribute__((
    coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_M, TILE_N,
             CLK_COOPERATIVE_MATRIX_ACCUMULATOR))) mat_acc_t;

kernel void matmul_fp16(global half *a_buf, global half *b_buf,
                        global float *out_buf, const uint a_stride,
                        const uint b_stride, const uint out_stride) {
  mat_a_t a;
  mat_b_t b;
  mat_acc_t c;

  c = coop_mat_init(0.0f);

  a = coop_mat_load(a_buf, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR, a_stride);
  b = coop_mat_load(b_buf, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR, b_stride);

  c = coop_mat_mulAdd(a, b, c);

  coop_mat_store(out_buf, c, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR,
                 out_stride);
}
