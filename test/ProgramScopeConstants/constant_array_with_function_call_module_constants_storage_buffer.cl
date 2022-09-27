// RUN: clspv %target %s -o %t.spv -module-constants-in-storage-buffer -no-inline-single -keep-unused-arguments
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck -check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv


constant uint b[4] = {42, 13, 0, 5};

__attribute__((noinline))
uint bar(constant uint* a)
{
  return a[get_local_id(0)];
}

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uint* a)
{
  *a = bar(b);
}


// MAP: constant,descriptorSet,1,binding,0,kind,buffer,hexbytes,2a0000000d0000000000000005000000
// MAP: kernel,foo,arg,a,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer


// CHECK:  OpDecorate [[_18:%[0-9a-zA-Z_]+]] DescriptorSet 1
// CHECK:  OpDecorate [[_18]] Binding 0
// CHECK:  OpDecorate [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] ArrayStride 4
// CHECK-DAG:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[_uint_4:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 4
// CHECK-DAG:  [[__arr_uint_uint_4:%[0-9a-zA-Z_]+]] = OpTypeArray [[_uint]] [[_uint_4]]
// CHECK-DAG:  [[__struct_10:%[0-9a-zA-Z_]+]] = OpTypeStruct [[__arr_uint_uint_4]]
// CHECK-DAG:  [[__ptr_StorageBuffer__struct_10:%[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer [[__struct_10]]
// CHECK-DAG:  [[__ptr_Input_uint:%[0-9a-zA-Z_]+]] = OpTypePointer Input [[_uint]]
// CHECK-DAG:  [[_18]] = OpVariable [[__ptr_StorageBuffer__struct_10]] StorageBuffer
// CHECK:  [[bar:%[0-9a-zA-Z_]+]] = OpFunction {{.*}}
// CHECK:  = OpFunction {{.*}}
// CHECK:  [[_30:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_18]]
// CHECK:  [[_31:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_uint]] [[bar]] [[_30]]
