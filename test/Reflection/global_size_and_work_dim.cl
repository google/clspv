// RUN: clspv %target %s -o %t.spv -cl-std=CL2.0 -inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* data) {
  *data = get_global_size(0) + get_work_dim();
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.4"
// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_12:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 12
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
//
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantGlobalSize [[uint_0]] [[uint_12]]
// CHECK: OpExtInst [[void]] [[import]] SpecConstantWorkDim [[uint_3]]
