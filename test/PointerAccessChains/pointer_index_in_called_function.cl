// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// CHECK: OpDecorate [[rtarr_struct:%[a-zA-Z0-9_]+]] ArrayStride 48
// CHECK: OpDecorate [[rtarr_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// CHECK: OpDecorate [[arr_12_float:%[a-zA-Z0-9_]+]] ArrayStride 4
// This is the one we really want:
// CHECK: OpDecorate [[ptr_sb_float:%[a-zA-Z0-9_]+]] ArrayStride 4

// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct
// CHECK-DAG: [[ptr_sb_struct:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK-DAG: [[ptr_sb_float]] = OpTypePointer StorageBuffer [[float]]
// CHECK-DAG: [[rtarr_float]] = OpTypeRuntimeArray [[float]]

// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_7:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 7

typedef struct {
  float x[12];
} Thing;

float bar(global Thing* a, int n) {
  return a[n].x[7];
}

// CHECK: = OpFunction [[float]]
// CHECK-NEXT: [[param_a:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[ptr_sb_struct]]
// CHECK-NEXT: [[param_n:%[a-zA-Z0-9_]+]] = OpFunctionParameter [[uint]]
// CHECK-NEXT: OpLabel
// CHECK-NEXT: = OpPtrAccessChain [[ptr_sb_float]] [[param_a]] [[param_n]] [[uint_0]] [[uint_7]]

void kernel __attribute__((reqd_work_group_size(1, 1, 1)))
foo(global Thing* a, global float *b, int n) {
  *b = bar(a, n);
}
