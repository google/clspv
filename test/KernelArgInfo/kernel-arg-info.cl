// RUN: clspv %s -cl-kernel-arg-info -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global int4 *A, local float* SEC, constant short2* TER, int QUA, read_only image2d_t im0, write_only image2d_t im1, const volatile global int * restrict ptr){}

// CHECK: [[extinst:%[a-zA-A0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.1"

// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "A"
// CHECK-DAG: [[arg0typename:%[a-zA-Z0-9_]+]] = OpString "int4*"
// CHECK-DAG: [[arg1name:%[a-zA-Z0-9_]+]] = OpString "SEC"
// CHECK-DAG: [[arg1typename:%[a-zA-Z0-9_]+]] = OpString "float*"
// CHECK-DAG: [[arg2name:%[a-zA-Z0-9_]+]] = OpString "TER"
// CHECK-DAG: [[arg2typename:%[a-zA-Z0-9_]+]] = OpString "short2*"
// CHECK-DAG: [[arg3name:%[a-zA-Z0-9_]+]] = OpString "im0"
// CHECK-DAG: [[arg3typename:%[a-zA-Z0-9_]+]] = OpString "image2d_t"
// CHECK-DAG: [[arg4name:%[a-zA-Z0-9_]+]] = OpString "im1"
// CHECK-DAG: [[arg4typename:%[a-zA-Z0-9_]+]] = OpString "image2d_t"
// CHECK-DAG: [[arg5name:%[a-zA-Z0-9_]+]] = OpString "ptr"
// CHECK-DAG: [[arg5typename:%[a-zA-Z0-9_]+]] = OpString "int*"
// CHECK-DAG: [[arg6name:%[a-zA-Z0-9_]+]] = OpString "QUA"
// CHECK-DAG: [[arg6typename:%[a-zA-Z0-9_]+]] = OpString "int"

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0

// CHECK-DAG: [[aspace_global:%[a-zA-Z0-9_]+]] = OpConstant %uint 4507
// CHECK-DAG: [[qual_access_none:%[a-zA-Z0-9_]+]] = OpConstant %uint 4515
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant %uint 0
// CHECK-DAG: [[aspace_local:%[a-zA-Z0-9_]+]] = OpConstant %uint 4508
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant %uint 1
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant %uint 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant %uint 4
// CHECK-DAG: [[aspace_constant:%[a-zA-Z0-9_]+]] = OpConstant %uint 4509
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant %uint 2
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant %uint 5
// CHECK-DAG: [[uint_6:%[a-zA-Z0-9_]+]] = OpConstant %uint 6
// CHECK-DAG: [[uint_7:%[a-zA-Z0-9_]+]] = OpConstant %uint 7
// CHECK-DAG: [[aspace_private:%[a-zA-Z0-9_]+]] = OpConstant %uint 4510
// CHECK-DAG: [[qual_access_read_only:%[a-zA-Z0-9_]+]] = OpConstant %uint 4512
// CHECK-DAG: [[qual_access_write_only:%[a-zA-Z0-9_]+]] = OpConstant %uint 4513

// CHECK: [[kernelinfo:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_name]]
// CHECK-NEXT: [[arg0info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg0name]] [[arg0typename]] [[aspace_global]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer [[kernelinfo]] [[uint_0]] [[uint_0]] [[uint_0]] [[arg0info]]
// CHECK-NEXT: [[arg1info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg1name]] [[arg1typename]] [[aspace_local]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentWorkgroup  [[kernelinfo]] [[uint_1]] [[uint_3]] [[uint_4]] [[arg1info]]
// CHECK-NEXT: [[arg2info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg2name]] [[arg2typename]] [[aspace_constant]] [[qual_access_none]] [[uint_1]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer  [[kernelinfo]] [[uint_2]] [[uint_0]] [[uint_1]] [[arg2info]]
// CHECK-NEXT: [[arg3info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg3name]] [[arg3typename]] [[aspace_global]] [[qual_access_read_only]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentSampledImage  [[kernelinfo]] [[uint_4]] [[uint_0]] [[uint_2]] [[arg3info]]
// CHECK-NEXT: [[arg4info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg4name]] [[arg4typename]] [[aspace_global]] [[qual_access_write_only]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageImage  [[kernelinfo]] [[uint_5]] [[uint_0]] [[uint_3]] [[arg4info]]
// CHECK-NEXT: [[arg5info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg5name]] [[arg5typename]] [[aspace_global]] [[qual_access_none]] [[uint_7]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer  [[kernelinfo]] [[uint_6]] [[uint_0]] [[uint_4]] [[arg5info]]
// CHECK-NEXT: [[arg6info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg6name]] [[arg6typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentPodPushConstant  [[kernelinfo]] [[uint_3]] [[uint_0]] [[uint_4]] [[arg6info]]
