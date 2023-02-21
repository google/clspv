// RUN: clspv %target --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that conversions from int8 to short8 is supported.

// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK:     OpUConvert %[[v2ushort]] %[[src_01:[0-9]+]]
// CHECK:     OpUConvert %[[v2ushort]] %[[src_23:[0-9]+]]
// CHECK:     OpUConvert %[[v2ushort]] %[[src_45:[0-9]+]]
// CHECK:     OpUConvert %[[v2ushort]] %[[src_67:[0-9]+]]

void kernel test(global int8 *in, global short8 *out) {
  *out = convert_short8(*in);
}
