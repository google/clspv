// RUN: clspv %target -int8 %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env vulkan1.0

// #288
// This kernel will produce a conversion from bool to char to satisfy the x = 1
// assignment.
kernel void foo(__global char* out, int a, int b) {
  char x;
  if (a == 10 || b == 2)
    x = 2;
  else if (b == 12 && a == 4)
    x = 3;
  else if (b != 3 || a != 5)
    x = 1;
  else
    x = 0;
  *out = x;
}

// The zext from i1 to i8 is translated as a selection between 1 and 0.
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[one:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 1
// CHECK-DAG: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[char]] 0
// CHECK: OpSelect [[char]] {{.*}} [[one]] [[zero]]
