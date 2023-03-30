// RUN: clspv %target %s -cl-kernel-arg-info -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct
{
    int i;
    float f;
} structArg;

__kernel void clone_kernel_test0(int iarg, float farg, structArg sarg, __local int* localbuf, __global int* outbuf)
{
}

// CHECK: [[extinst:%[a-zA-A0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "clone_kernel_test0"
// CHECK-DAG: [[arg3name:%[a-zA-Z0-9_]+]] = OpString "localbuf"
// CHECK-DAG: [[arg3typename:%[a-zA-Z0-9_]+]] = OpString "int*"
// CHECK-DAG: [[arg4name:%[a-zA-Z0-9_]+]] = OpString "outbuf"
// CHECK-DAG: [[arg4typename:%[a-zA-Z0-9_]+]] = OpString "int*"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "iarg"
// CHECK-DAG: [[arg0typename:%[a-zA-Z0-9_]+]] = OpString "int"
// CHECK-DAG: [[arg1name:%[a-zA-Z0-9_]+]] = OpString "farg"
// CHECK-DAG: [[arg1typename:%[a-zA-Z0-9_]+]] = OpString "float"
// CHECK-DAG: [[arg2name:%[a-zA-Z0-9_]+]] = OpString "sarg"
// CHECK-DAG: [[arg2typename:%[a-zA-Z0-9_]+]] = OpString "structArg"

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0

// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant %uint 5
// CHECK-DAG: [[aspace_local:%[a-zA-Z0-9_]+]] = OpConstant %uint 4508
// CHECK-DAG: [[qual_access_none:%[a-zA-Z0-9_]+]] = OpConstant %uint 4515
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant %uint 0
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant %uint 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant %uint 4
// CHECK-DAG: [[aspace_global:%[a-zA-Z0-9_]+]] = OpConstant %uint 4507
// CHECK-DAG: [[aspace_private:%[a-zA-Z0-9_]+]] = OpConstant %uint 4510
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant %uint 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant %uint 2
// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant %uint 8

// CHECK: [[kernelinfo:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_name]]
// CHECK-NEXT: [[arg3info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg3name]] [[arg3typename]] [[aspace_local]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentWorkgroup [[kernelinfo]] [[uint_3]] [[uint_3]] [[uint_4]] [[arg3info]]
// CHECK-NEXT: [[arg4info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg4name]] [[arg4typename]] [[aspace_global]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer  [[kernelinfo]] [[uint_4]] [[uint_0]] [[uint_0]] [[arg4info]]
// CHECK-NEXT: [[arg0info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg0name]] [[arg0typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentPodPushConstant  [[kernelinfo]] [[uint_0]] [[uint_0]] [[uint_4]] [[arg0info]]
// CHECK-NEXT: [[arg1info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg1name]] [[arg1typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentPodPushConstant  [[kernelinfo]] [[uint_1]] [[uint_4]] [[uint_4]] [[arg1info]]
// CHECK-NEXT: [[arg2info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg2name]] [[arg2typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentPodPushConstant  [[kernelinfo]] [[uint_2]] [[uint_8]] [[uint_8]] [[arg2info]]
