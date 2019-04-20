// RUN: clspv %s -o %t.spv -descriptormap=%t.map -pod-ubo -cluster-pod-kernel-args
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int a __attribute__((aligned(16)));
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
// CHECK: OpMemberDecorate [[cluster:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[cluster]] 1 Offset 4
// CHECK: OpMemberDecorate [[cluster]] 2 Offset 8
// CHECK: OpMemberDecorate [[cluster]] 3 Offset 12
// CHECK: OpMemberDecorate [[cluster]] 4 Offset 16
// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[S]] = OpTypeStruct [[int]] [[char]]
// CHECK: [[cluster]] = OpTypeStruct [[int]] [[int]] [[int]] [[int]] [[S]]
// CHECK: [[pod_var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} Uniform
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[pod_var]]
// CHECK: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[cluster]] [[gep]]
// CHECK: [[a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[ld]] 0
// CHECK: [[s:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[S]] [[ld]] 4
// CHECK: [[s_a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[int]] [[s]] 0
// CHECK: OpIAdd [[int]] [[s_a]] [[a]]

