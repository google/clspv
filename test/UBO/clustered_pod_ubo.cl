// RUN: clspv %target %s -o %t.spv -pod-ubo -cluster-pod-kernel-args
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %target %s -o %t2.spv -pod-ubo -cluster-pod-kernel-args -int8=0
// RUN: spirv-dis %t2.spv -o %t2.spvasm
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t2.spv -o %t2.map
// RUN: FileCheck --check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t2.spv

typedef struct {
  int a, b, c, d;
} S;

kernel void foo(global int4* out, int a, S s) {
  out->x = a + s.a;
}

// MAP:      kernel,foo,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,a,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod_ubo,argSize,4
// MAP-NEXT: kernel,foo,arg,s,argOrdinal,2,descriptorSet,0,binding,1,offset,16,argKind,pod_ubo,argSize,16

// CHECK: OpMemberDecorate
// CHECK: OpMemberDecorate [[S:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[S]] 1 Offset 4
// CHECK: OpMemberDecorate [[S]] 2 Offset 8
// CHECK: OpMemberDecorate [[S]] 3 Offset 12
// CHECK: OpMemberDecorate [[cluster:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[cluster]] 1 Offset 4
// CHECK: OpMemberDecorate [[cluster]] 2 Offset 8
// CHECK: OpMemberDecorate [[cluster]] 3 Offset 12
// CHECK: OpMemberDecorate [[cluster]] 4 Offset 16
// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-NOT: OpTypeInt 8 0
// CHECK: [[S]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]]
// CHECK: [[cluster]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]] [[S]]
// CHECK: [[pod_var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[pod_var]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[cluster]] [[gep]]
// CHECK: [[a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[ld]] 0
// CHECK: [[s:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[S]] [[ld]] 4
// CHECK: [[s_a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[s]] 0
// CHECK: OpIAdd [[int]] [[s_a]] [[a]]
