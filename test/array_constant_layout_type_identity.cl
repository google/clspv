// An initialized module-scope constant array must reuse the same SPIR-V
// array type id for the constant composite and the variable that carries it.
// When the type map handed out different ids for the layout variants, the
// variable ended up with one id and the initializer with another, and
// spirv-val rejected the module with "Initializer type must match the data
// type".

// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv

// CHECK: [[arr:%[a-zA-Z0-9_]+]] = OpTypeArray %uint %uint_4
// CHECK-NOT: OpTypeArray %uint %uint_4
// CHECK: OpConstantComposite [[arr]] %uint_0 %uint_16777216 %uint_65536 %uint_256
// CHECK: OpVariable %{{.*}} StorageBuffer %{{[0-9]+}}

constant uint tbl[4] = {0u, 16777216u, 65536u, 256u};

kernel void copy(global uint *out) {
  uint acc = 0;
  for (int i = 0; i < 4; i++) {
    acc += tbl[i] << (i & 3);
  }
  out[0] = acc;
}
