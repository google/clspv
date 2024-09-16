// RUN: clspv -int8=0 %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant uchar b[4] = {[0]=42, [1]=13, [2]=0, [3]=5};

void kernel __attribute__((reqd_work_group_size(4, 1, 1))) foo(global uchar* a)
{
  *a = b[get_local_id(0)];
}

// CHECK-DAG:  [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG:  OpTypePointer StorageBuffer [[struct:%[^ ]+]]
// CHECK-DAG:  [[struct]] = OpTypeStruct [[runtimearr:%[^ ]+]]
// CHECK-DAG:  OpDecorate [[runtimearr]] ArrayStride 4