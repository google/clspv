// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that select for float8/uint8 is supported.

// CHECK-DAG: [[BOOL:%[^ ]+]]  = OpTypeBool
// CHECK-DAG: [[UINT:%[^ ]+]]  = OpTypeInt 32
// CHECK-DAG: [[FLOAT:%[^ ]+]] = OpTypeFloat 32
//
// CHECK-DAG: [[ZERO:%[^ ]+]] = OpConstant [[UINT]] 0
//
// CHECK-NOT: DAG BARRIER
//
// CHECK-DAG: [[COND_0:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_1:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_2:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_3:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_4:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_5:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_6:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
// CHECK-DAG: [[COND_7:%[^ ]+]] = OpSLessThan [[BOOL]] {{%[^ ]+}} [[ZERO]]
//
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_0]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_1]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_2]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_3]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_4]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_5]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_6]] {{%[^ ]+}} {{%[^ ]+}}
// CHECK-DAG: OpSelect [[FLOAT]] [[COND_7]] {{%[^ ]+}} {{%[^ ]+}}

void kernel test(global float8 *out, global float8 *in, global uint8 *cond) {
  *out = select(in[0], in[1], *cond);
}
