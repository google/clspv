// RUN: clspv %target %s -cl-std=CL2.0 -inline-entry-points -cl-kernel-arg-info -cluster-pod-kernel-args=0 -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel foo(global int4 *A, local float* SEC, constant ushort2* TER, int QUA, read_only image2d_t im0, write_only image2d_t im1, read_write image3d_t im2, sampler_t smp) {
}

// CHECK: [[extinst:%[a-zA-A0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "A"
// CHECK-DAG: [[arg0typename:%[a-zA-Z0-9_]+]] = OpString "int4*"
// CHECK-DAG: [[arg1name:%[a-zA-Z0-9_]+]] = OpString "SEC"
// CHECK-DAG: [[arg1typename:%[a-zA-Z0-9_]+]] = OpString "float*"
// CHECK-DAG: [[arg2name:%[a-zA-Z0-9_]+]] = OpString "TER"
// CHECK-DAG: [[arg2typename:%[a-zA-Z0-9_]+]] = OpString "ushort2*"
// CHECK-DAG: [[arg3name:%[a-zA-Z0-9_]+]] = OpString "im0"
// CHECK-DAG: [[arg3typename:%[a-zA-Z0-9_]+]] = OpString "image2d_t"
// CHECK-DAG: [[arg4name:%[a-zA-Z0-9_]+]] = OpString "im1"
// CHECK-DAG: [[arg4typename:%[a-zA-Z0-9_]+]] = OpString "image2d_t"
// CHECK-DAG: [[arg5name:%[a-zA-Z0-9_]+]] = OpString "im2"
// CHECK-DAG: [[arg5typename:%[a-zA-Z0-9_]+]] = OpString "image3d_t"
// CHECK-DAG: [[arg6name:%[a-zA-Z0-9_]+]] = OpString "smp"
// CHECK-DAG: [[arg6typename:%[a-zA-Z0-9_]+]] = OpString "sampler_t"
// CHECK-DAG: [[arg7name:%[a-zA-Z0-9_]+]] = OpString "QUA"
// CHECK-DAG: [[arg7typename:%[a-zA-Z0-9_]+]] = OpString "int"

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0

// CHECK-DAG: [[uint_8:%[a-zA-Z0-9_]+]] = OpConstant %uint 8
// CHECK-DAG: [[aspace_global:%[a-zA-Z0-9_]+]] = OpConstant %uint 4507
// CHECK-DAG: [[qual_access_none:%[a-zA-Z0-9_]+]] = OpConstant %uint 4515
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant %uint 0
// CHECK-DAG: [[aspace_constant:%[a-zA-Z0-9_]+]] = OpConstant %uint 4509
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant %uint 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant %uint 2
// CHECK-DAG: [[aspace_private:%[a-zA-Z0-9_]+]] = OpConstant %uint 4510
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant %uint 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant %uint 4
// CHECK-DAG: [[qual_access_read_only:%[a-zA-Z0-9_]+]] = OpConstant %uint 4512
// CHECK-DAG: [[qual_access_write_only:%[a-zA-Z0-9_]+]] = OpConstant %uint 4513
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant %uint 5
// CHECK-DAG: [[qual_access_read_write:%[a-zA-Z0-9_]+]] = OpConstant %uint 4514
// CHECK-DAG: [[uint_6:%[a-zA-Z0-9_]+]] = OpConstant %uint 6
// CHECK-DAG: [[uint_7:%[a-zA-Z0-9_]+]] = OpConstant %uint 7
// CHECK-DAG: [[aspace_local:%[a-zA-Z0-9_]+]] = OpConstant %uint 4508

// CHECK: [[kernelinfo:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_name]]
// CHECK-NEXT: [[arg0info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg0name]] [[arg0typename]] [[aspace_global]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer [[kernelinfo]] [[uint_0]] [[uint_0]] [[uint_0]] [[arg0info]]
// CHECK-NEXT: [[arg2info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg2name]] [[arg2typename]] [[aspace_constant]] [[qual_access_none]] [[uint_1]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer  [[kernelinfo]] [[uint_2]] [[uint_0]] [[uint_1]] [[arg2info]]
// CHECK-NEXT: [[arg7info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg7name]] [[arg7typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentPodUniform  [[kernelinfo]] [[uint_3]] [[uint_0]] [[uint_2]] [[uint_0]] [[uint_4]] [[arg7info]]
// CHECK-NEXT: [[arg3info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg3name]] [[arg3typename]] [[aspace_global]] [[qual_access_read_only]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentSampledImage  [[kernelinfo]] [[uint_4]] [[uint_0]] [[uint_3]] [[arg3info]]
// CHECK-NEXT: [[arg4info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg4name]] [[arg4typename]] [[aspace_global]] [[qual_access_write_only]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageImage  [[kernelinfo]] [[uint_5]] [[uint_0]] [[uint_4]] [[arg4info]]
// CHECK-NEXT: [[arg5info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg5name]] [[arg5typename]] [[aspace_global]] [[qual_access_read_write]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageImage  [[kernelinfo]] [[uint_6]] [[uint_0]] [[uint_5]] [[arg5info]]
// CHECK-NEXT: [[arg6info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg6name]] [[arg6typename]] [[aspace_private]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentSampler  [[kernelinfo]] [[uint_7]] [[uint_0]] [[uint_6]] [[arg6info]]
// CHECK-NEXT: [[arg1info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg1name]] [[arg1typename]] [[aspace_local]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentWorkgroup  [[kernelinfo]] [[uint_1]] [[uint_3]] [[uint_4]] [[arg1info]]
