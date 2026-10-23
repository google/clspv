// RUN: clspv %target --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Verify that dynamic element insertion into a long vector (vec8/vec16)
// stores the modified element into a Function-scope array and reloads the
// updated array elements before storing the result to global memory.

// CHECK: [[VAR:%[0-9a-zA-Z_]+]] = OpVariable {{%[0-9a-zA-Z_]+}} Function
// CHECK: OpStore {{%[0-9a-zA-Z_]+}} %float_42
// CHECK-NEXT: [[ELEM0:%[0-9a-zA-Z_]+]] = OpAccessChain {{%[0-9a-zA-Z_]+}} [[VAR]] %uint_0
// CHECK-NEXT: OpLoad %float [[ELEM0]]

void kernel test_vec8_dynamic_insert(global float8 *in, global float8 *out,
                                     uint idx) {
  float8 v = *in;
  v[idx] = 42.0f;
  *out = v;
}
