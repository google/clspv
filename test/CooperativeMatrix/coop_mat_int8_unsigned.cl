// RUN: clspv %target %s -o %t.spv -int8 --spv-version=1.6
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: spirv-val --target-env vulkan1.3 %t.spv
// RUN: FileCheck %s < %t2.spvasm

// CHECK-DAG: [[u8:%[^ ]+]] = OpTypeInt 8 0
// CHECK-DAG: [[i32:%[^ ]+]] = OpTypeInt 32 1
// CHECK-DAG: OpTypeCooperativeMatrixKHR [[u8]]
// CHECK-DAG: [[acc_ty:%[^ ]+]] = OpTypeCooperativeMatrixKHR [[i32]]
// CHECK: OpCooperativeMatrixMulAddKHR [[acc_ty]] {{%[^ ]+}} {{%[^ ]+}} {{%[^ ]+}} MatrixCSignedComponentsKHR|MatrixResultSignedComponentsKHR

#define TILE_M 16
#define TILE_N 16
#define TILE_K 16

typedef uchar
    __attribute__((coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_M,
                            TILE_K, CLK_COOPERATIVE_MATRIX_A))) mat_a_t;
typedef uchar
    __attribute__((coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_K,
                            TILE_N, CLK_COOPERATIVE_MATRIX_B))) mat_b_t;
typedef int __attribute__((
    coop_mat(CLK_COOPERATIVE_MATRIX_SCOPE_SUBGROUP, TILE_M, TILE_N,
             CLK_COOPERATIVE_MATRIX_ACCUMULATOR))) mat_acc_t;

kernel void matmul_u8(global uchar *a_buf, global uchar *b_buf,
                      global int *out_buf, const uint a_stride,
                      const uint b_stride, const uint out_stride) {
  mat_a_t a;
  mat_b_t b;
  mat_acc_t c;

  c = coop_mat_init(0);

  a = coop_mat_load(a_buf, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR, a_stride);
  b = coop_mat_load(b_buf, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR, b_stride);

  c = coop_mat_mulAdd(a, b, c);

  coop_mat_store(out_buf, c, CLK_COOPERATIVE_MATRIX_LAYOUT_ROW_MAJOR,
                 out_stride);
}
