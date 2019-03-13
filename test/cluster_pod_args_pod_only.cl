// RUN: clspv -cluster-pod-kernel-args -descriptormap=%t.map %s -o %t.spv
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test,arg,pod,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,pod

kernel void test(int pod)
{
}

