// RUN: clspv -cluster-pod-kernel-args -descriptormap=%t.map %s -o %t.spv
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test,arg,pod,argOrdinal,0,offset,0,argKind,pod_pushconstant,argSize,4

kernel void test(int pod)
{
}

