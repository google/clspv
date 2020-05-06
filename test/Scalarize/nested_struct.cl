// RUN: clspv %s -o %t.spv -hack-phis
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct { int arr[2]; } S1;
typedef struct { S1 s1; int a; S1 s2; } S2;

S2 make_s2(int n) {
  S2 s2;
  s2.s1.arr[0] = n;
  s2.s1.arr[1] = n+1;
  s2.a = n+2;
  s2.s2.arr[0] = n+3;
  s2.s2.arr[1] = n+4;
  return s2;
}

S2 choose(int n) {
  if (n > 0) return make_s2(n - 5);
  return make_s2(n + 10);
}

kernel void foo(global S2 *data, int n) {
  *data = choose(n);
}

// CHECK-DAG: [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK-DAG: [[__arr_uint_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_2]]
// CHECK-DAG: [[__struct_4:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_uint_uint_2]]
// CHECK-DAG: [[__struct_5:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__struct_4]] [[_uint]] [[__struct_4]]
// CHECK-NOT: OpPhi [[__struct_5]]
// CHECK-NOT: OpPhi [[__struct_4]]
// CHECK: [[_61:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]]
// CHECK: [[_62:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]]
// CHECK: [[_63:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]]
// CHECK: [[_66:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_63]]
// CHECK: [[_67:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_61]]
// CHECK: [[_65:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_67]] [[_62]] [[_66]]
// CHECK: [[_68:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_65]] 0
// CHECK: [[_69:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_68]] 0
// CHECK: [[_70:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[_uint]] [[_65]] 1
// CHECK: [[_71:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__struct_4]] [[_65]] 2
// CHECK: [[_72:%[0-9a-zA-Z_]+]] = OpCompositeExtract [[__arr_uint_uint_2]] [[_71]] 0
// CHECK: OpSelectionMerge [[_73:%[0-9a-zA-Z_]+]] None
// CHECK: [[_73]] = OpLabel
// CHECK-NOT: OpPhi [[__struct_5]]
// CHECK-NOT: OpPhi [[__struct_4]]
// CHECK: [[_74:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_69]]
// CHECK: [[_75:%[0-9a-zA-Z_]+]] = OpPhi [[_uint]] [[_70]]
// CHECK: [[_76:%[0-9a-zA-Z_]+]] = OpPhi [[__arr_uint_uint_2]] [[_72]]
// CHECK: [[_78:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_76]]
// CHECK: [[_79:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_4]] [[_74]]
// CHECK: [[_77:%[0-9a-zA-Z_]+]] = OpCompositeConstruct [[__struct_5]] [[_79]] [[_75]] [[_78]]
