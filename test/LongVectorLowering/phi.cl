// RUN: clspv %s --long-vector --output-format=ll -o %t.ll
// RUN: clspv-opt %t.ll --passes=long-vector-lowering -o %t.out.ll
// RUN: FileCheck %s < %t.out.ll

// CHECK: phi [8 x float]

kernel void foo(int x, global float4 *output) {
  float8 one = (float8)(1.f);
  float8 val = (x > 0 ? one : 0.f);
  *output = val.lo;
}

