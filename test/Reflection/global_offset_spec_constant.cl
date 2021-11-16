// RUN: clspv %s -o %t.spv -global-offset
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* data) {
  *data = get_global_offset(0);
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.2"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK: OpExtInst [[void]] [[import]] SpecConstantGlobalOffset [[uint_3]] [[uint_4]] [[uint_5]]

