// RUN: clspv %target %s -o %t.spv
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: kernel_decl,with_args
// CHECK: kernel,with_args,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer

void kernel with_args(global int *out) { *out = 0; }

