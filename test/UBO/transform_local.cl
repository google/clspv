// RUN: clspv -constant-args-ubo -inline-entry-points %s -S -o %t.spvasm -descriptormap=%t.map
// rUN: FileCheck %s < %t.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: clspv -constant-args-ubo -inline-entry-points %s -o %t.spv -descriptormap=%t2.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// rUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int x __attribute__((aligned(16)));
} data_type;

__kernel void foo(__global data_type* data, __constant data_type* c_arg, __local data_type* l_arg) {
  data->x = c_arg->x + l_arg->x;
}

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
// MAP-NEXT: kernel,foo,arg,l_arg,argOrdinal,2,argKind,local,arrayElemSize,16,arrayNumElemSpecId,3
