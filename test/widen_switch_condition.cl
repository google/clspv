// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


// Prove that we can widen narrow bit widths on a switch condition, which can
// be generated for the switch condition by SimplifyCFG followed by InstCombine.

// There is a special check not assertion in the pattern checks below.

kernel void foo(global float *out, float x, float y) {

  int first_result;

  if (y >= 1.25f) {
    if (x > 0) {
      first_result = 0;
    } else {
      first_result = 1;
    }
  } else if (y >= 1.5f) {
    if (x > 0) {
      first_result = 2;
    } else {
      first_result = 3;
    }
  } else {
    if (y + 1.0f > 0) {
      first_result = 4;
    } else {
      first_result = 5;
    }
  }

  float fr = (float)(first_result);

  float result = -1.0f;
  if (fr == 0)
    result = 1.0f;
  else if (fr == 1)
    result = 0.0f;
  else if (fr == 2)
    result = 2.0f;

  *out = result;
}

// CHECK-NOT: OpTypeInt
// CHECK:  OpTypeInt 32 0
// There is one one integer width declared.
// CHECK-NOT: OpTypeInt
