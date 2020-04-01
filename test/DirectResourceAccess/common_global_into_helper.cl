// RUN: clspv %s -o %t.spv -descriptormap=%t.map -keep-unused-arguments
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

//      MAP: kernel,foo,arg,A,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
//      MAP: kernel,foo,arg,n,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
//      MAP: kernel,bar,arg,B,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
//      MAP: kernel,bar,arg,m,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod,argSize,4
// MAP-NONE: kernel

float core(global float *arr, int n) {
  return arr[n];
}

float apple(global float *arr, int n) {
  return core(arr, n) + core(arr, n+1);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global float* A, int n)
{
  A[0] = apple(A, n);
}

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) bar(global float* B, uint m)
{
  B[0] = apple(B, m) + apple(B, m+2);
}

// CHECK:  OpEntryPoint GLCompute [[_33:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpEntryPoint GLCompute [[_39:%[0-9a-zA-Z_]+]] "bar"
// CHECK:  OpDecorate [[_16:%[0-9a-zA-Z_]+]] DescriptorSet 0
// CHECK:  OpDecorate [[_16]] Binding 0
// CHECK-DAG:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG:  [[_16]] = OpVariable {{.*}} StorageBuffer
// CHECK:  [[_18:%[0-9a-zA-Z_]+]] = OpFunction [[_float]]
// CHECK:  [[_22:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_16]]
// CHECK:  [[_24:%[0-9a-zA-Z_]+]] = OpFunction [[_float]]
// CHECK:  [[_28:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_16]]
// CHECK:  [[_29:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_18]] [[_28]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_18]] [[_28]]
// CHECK:  [[_33]] = OpFunction [[_void]]
// CHECK:  [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_16]]
// CHECK:  [[_38:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_35]]
// CHECK:  [[_39]] = OpFunction [[_void]]
// CHECK:  [[_41:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_16]]
// CHECK:  [[_44:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_41]]
// CHECK:  [[_46:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_float]] [[_24]] [[_41]]
