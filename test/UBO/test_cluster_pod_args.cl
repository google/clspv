// RUN: clspv -constant-args-ubo -inline-entry-points -cluster-pod-kernel-args %s -o %t.spv -pod-ubo
// RUN: clspv-reflection %t.spv -o %2.map
// RUN: FileCheck -check-prefix=MAP %s < %t2.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct {
  int x __attribute__((aligned(16)));
} data_type;

__constant data_type c_var[2] = {{0}, {1}};

__kernel void foo(__global data_type *data, __constant data_type *c_arg,
                  int n) {
  data[n].x = c_arg[n].x + c_var[n].x;
}

// Just checking that the argument names are recorded correctly when clustering pod args.

//      MAP: kernel,foo,arg,data,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP-NEXT: kernel,foo,arg,c_arg,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer_ubo
// MAP-NEXT: kernel,foo,arg,n,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,pod_ubo

