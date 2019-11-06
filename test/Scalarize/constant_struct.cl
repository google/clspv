// RUN: clspv %s -o %t.spv -hack-phis -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { int arr[2]; } S1;
typedef struct { S1 s1; int a; S1 s2; } S2;

S2 make_s2(int n) {
  S2 s2;
  s2.s1.arr[0] = n;
  s2.s1.arr[1] = n;
  s2.a = n;
  s2.s2.arr[0] = n;
  s2.s2.arr[1] = n;
  return s2;
}

S2 choose(int n) {
  if (n > 0) return make_s2(n - 5);
  return make_s2(0);
}

kernel void foo(global S2 *data, int n) {
  *data = choose(n);
}

// CHECK: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK: [[__arr_uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_2]]
// CHECK: [[__struct_4:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_uint_uint_2]]
// CHECK: [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__struct_4]] [[_uint]] [[__struct_4]]
// CHECK-NOT: OpPhi [[__struct_5]]
// CHECK-NOT: OpPhi [[__struct_4]]
// CHECK: OpPhi [[__arr_uint_uint_2]]
// CHECK: OpPhi [[_uint]]
// CHECK: OpPhi [[__arr_uint_uint_2]]
