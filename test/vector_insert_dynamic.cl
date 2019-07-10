// Test for https://github.com/google/clspv/issues/143
// Order of OpVectorInsertDynamic operands was incorrect.

// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global int4* in, global int4* out,
                global int* index) {
  size_t gid = get_global_id(0);
  out[gid][index[gid]] = 42;
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  OpLoad [[_uint]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[_36:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]]
// CHECK:  [[_37:%[0-9a-zA-Z_]+]] = OpVectorInsertDynamic [[_v4uint]] [[_36]] [[_uint_42]] [[_35]]
// CHECK:  OpStore {{.*}} [[_37]]
