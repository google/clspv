// RUN: clspv %target %s -cl-kernel-arg-info -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global intptr_t* buf)
{
}

// CHECK: [[extinst:%[a-zA-A0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: [[kernel_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[arg0name:%[a-zA-Z0-9_]+]] = OpString "buf"
// CHECK-DAG: [[arg0typename:%[a-zA-Z0-9_]+]] = OpString "intptr_t*"

// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0

// CHECK-DAG: [[qual_access_none:%[a-zA-Z0-9_]+]] = OpConstant %uint 4515
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant %uint 0
// CHECK-DAG: [[aspace_global:%[a-zA-Z0-9_]+]] = OpConstant %uint 4507
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant %uint 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant %uint 2

// CHECK: [[kernelinfo:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] Kernel {{.*}} [[kernel_name]]
// CHECK-NEXT: [[arg0info:%[a-zA-Z0-9_]+]] = OpExtInst %void [[extinst]] ArgumentInfo [[arg0name]] [[arg0typename]] [[aspace_global]] [[qual_access_none]] [[uint_0]]
// CHECK-NEXT: OpExtInst %void [[extinst]] ArgumentStorageBuffer  [[kernelinfo]] [[uint_0]] [[uint_0]] [[uint_0]] [[arg0info]]
