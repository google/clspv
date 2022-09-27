// Test for https://github.com/google/clspv/issues/143
// Order of OpVectorInsertDynamic operands was incorrect.

// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


kernel void foo(global int4* in, global int4* out,
                global int* index) {
  size_t gid = get_global_id(0);
  int4 result = in[gid];
  result[index[gid]] = 42;
  out[gid] = result;
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_v4uint:%[0-9a-zA-Z_]+]] = OpTypeVector [[_uint]] 4
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_uint_42:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 42
// CHECK:  OpLoad [[_uint]]
// CHECK:  [[val:%[0-9a-zA-Z_]+]] = OpLoad [[_v4uint]]
// CHECK:  [[idx:%[0-9a-zA-Z_]+]] = OpLoad [[_uint]]
// CHECK:  [[result:%[0-9a-zA-Z_]+]] = OpVectorInsertDynamic [[_v4uint]] [[val]] [[_uint_42]] [[idx]]
// CHECK:  OpStore {{.*}} [[result]]
