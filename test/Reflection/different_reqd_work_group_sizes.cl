// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.4"
// CHECK-DAG: [[foo_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[bar_name:%[a-zA-Z0-9_]+]] = OpString "bar"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[uint_6:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 6
// CHECK-DAG: [[foo:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] [[import]] Kernel {{.*}} [[foo_name]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PropertyRequiredWorkgroupSize [[foo]] [[uint_1]] [[uint_2]] [[uint_3]]
// CHECK-DAG: [[bar:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] [[import]] Kernel {{.*}} [[bar_name]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PropertyRequiredWorkgroupSize [[bar]] [[uint_4]] [[uint_5]] [[uint_6]]

__attribute__((reqd_work_group_size(1,2,3)))
kernel void foo() { }

__attribute__((reqd_work_group_size(4,5,6)))
kernel void bar() { }

