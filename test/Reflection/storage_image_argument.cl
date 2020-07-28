// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(write_only image2d_t data) {
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.1"
// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: [[foo_name:%[a-zA-Z0-9_]+]] = OpString "foo"
// CHECK-DAG: [[data_name:%[a-zA-Z0-9_]+]] = OpString "data"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[decl:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] [[import]] Kernel [[foo]] [[foo_name]]
// CHECK-DAG: [[info:%[a-zA-Z0-9_]+]] = OpExtInst [[void]] [[import]] ArgumentInfo [[data_name]]
// CHECK: OpExtInst [[void]] [[import]] ArgumentStorageImage [[decl]] [[uint_0]] [[uint_0]] [[uint_0]] [[info]]

