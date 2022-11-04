// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck --check-prefix=ON %s < %t.spvasm
// RUN: clspv %target %s -o %t2.spv -int8=0
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck --check-prefix=OFF %s < %t2.spvasm

kernel void foo(global int* out, char a) {
  *out = a;
}

// ON: OpTypeInt 8 0
// OFF-NOT: OpTypeInt 8 0
