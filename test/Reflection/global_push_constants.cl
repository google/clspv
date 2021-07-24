// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -inline-entry-points -global-offset
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* data) {
  *data = get_global_offset(0) + get_num_groups(0) +
          get_enqueued_local_size(0) + get_global_size(0) + get_global_id(0) +
          get_group_id(0);
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.2"
// CHECK: OpEntryPoint GLCompute [[foo:%[a-zA-Z0-9_]+]] "foo"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_12:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 12
// CHECK-DAG: [[uint_16:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_32:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 32
// CHECK-DAG: [[uint_48:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 48
// CHECK-DAG: [[uint_64:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 64
// CHECK-DAG: [[uint_80:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 80
//
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantGlobalOffset [[uint_0]] [[uint_12]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantEnqueuedLocalSize [[uint_16]] [[uint_12]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantGlobalSize [[uint_32]] [[uint_12]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantRegionOffset [[uint_48]] [[uint_12]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantNumWorkgroups [[uint_64]] [[uint_12]]
// CHECK-DAG: OpExtInst [[void]] [[import]] PushConstantRegionGroupOffset [[uint_80]] [[uint_12]]

