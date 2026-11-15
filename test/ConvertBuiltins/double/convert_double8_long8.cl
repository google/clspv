// RUN: clspv %target --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-COUNT-8: OpConvertSToF [[DOUBLE]]

void kernel test(global long8 *in, global double8 *out) {
  *out = convert_double8(*in);
}
