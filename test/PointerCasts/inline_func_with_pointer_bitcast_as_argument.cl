// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void boo(__global float* outDest) {
  *outDest = 1.0f;
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(__global uint* outDest) {
  boo(outDest);
}
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_1065353216:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1065353216
// CHECK:  OpStore {{.*}} [[_uint_1065353216]]
