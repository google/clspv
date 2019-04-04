// RUN: clspv -descriptormap=%t.map %s -o %t.spv
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test,arg,arg,argOrdinal,0,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3

kernel void test(local int* arg) {}

