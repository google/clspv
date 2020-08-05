// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo() { }

kernel void bar() { }

kernel void baz() { }

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.1"
// CHECK-DAG: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: OpEntryPoint GLCompute [[bar:%[a-zA-Z0-9_]+]] "bar"
// CHECK-DAG: OpEntryPoint GLCompute [[baz:%[a-zA-Z0-9_]+]] "baz"
// CHECK-DAG: [[foo_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[bar_name:%[a-zA-Z0-9_]+]] = OpString "bar"
// CHECK-DAG: [[baz_name:%[a-zA-Z0-9_]+]] = OpString "baz"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: OpExtInst [[void]] [[import]] Kernel [[foo]] [[foo_name]]
// CHECK-DAG: OpExtInst [[void]] [[import]] Kernel [[bar]] [[bar_name]]
// CHECK-DAG: OpExtInst [[void]] [[import]] Kernel [[baz]] [[baz_name]]
