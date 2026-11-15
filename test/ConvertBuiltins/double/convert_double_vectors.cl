// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s --check-prefixes=CHECK,VEC3
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target -vec3-to-vec4 %s -o %t.novec3.spv
// RUN: spirv-dis %t.novec3.spv -o - | FileCheck %s --check-prefixes=CHECK,NOVEC3
// RUN: spirv-val --target-env vulkan1.0 %t.novec3.spv

// CHECK-DAG: [[DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: [[V2DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 2
// VEC3-DAG: [[V3DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 3
// CHECK-DAG: [[V4DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeVector [[DOUBLE]] 4

// CHECK: OpConvertUToF [[V2DOUBLE]]
// VEC3: OpConvertSToF [[V3DOUBLE]]
// NOVEC3: OpConvertSToF [[V4DOUBLE]]
// CHECK: OpConvertSToF [[V4DOUBLE]]
// CHECK: OpFConvert [[V4DOUBLE]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel test(global uint2 *u2, global int3 *i3,
                 global long4 *l4, global half4 *h4,
                 global double2 *out2, global double3 *out3,
                 global double4 *out4) {
  *out2 = convert_double2(*u2);
  *out3 = convert_double3(*i3);
  out4[0] = convert_double4(*l4);
  out4[1] = convert_double4(*h4);
}
