// RUN: clspv  %s -S -o %t.spvasm -int8
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv  %s -o %t.spv -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* a, global char* b) {
  *a = any(*b);
}

// CHECK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK:     [[char_7:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 7
// CHECK:     [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[char]]
// CHECK:     [[shift:%[a-zA-Z0-9_]+]] = OpShiftRightLogical [[char]] [[ld]] [[char_7]]
// CHECK:     OpUConvert [[int]] [[shift]]
