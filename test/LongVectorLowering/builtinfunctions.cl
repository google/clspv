// RUN: clspv %s --long-vector -verify
// RUN: clspv %s --long-vector -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Ensure all builtins are declared (i.e. there are no warnings about implicit
// declaration).
//
// expected-no-diagnostics

// Check that calling multiple overloads of a BIF is supported.

// CHECK: [[EXT:%[0-9]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK-DAG: [[UINT:%[a-zA-Z0-9_]+]]  = OpTypeInt 32 0
// CHECK-DAG: [[UINT4:%[a-zA-Z0-9_]+]] = OpTypeVector [[UINT]] 4

kernel void test(global int *in, global int *out) {
  {
    int8 a = vload8(0, in);
    int8 b = vload8(1, in);
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    // CHECK: OpExtInst [[UINT]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    int8 c = max(a, b);
    vstore8(c, 0, out);
  }

  {
    int4 a = vload4(0, in);
    int4 b = vload4(1, in);
    // CHECK: OpExtInst [[UINT4]] [[EXT]] SMax {{%[0-9]+}} {{%[0-9]+}}
    int4 c = max(a, b);
    vstore4(c, 2, out);
  }
}
