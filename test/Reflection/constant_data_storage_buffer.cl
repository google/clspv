// RUN: clspv %target %s -o %t.spv -module-constants-in-storage-buffer
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

constant int x[] = {1,2,3,4};

kernel void foo(global int* data) {
  *data = x[get_global_id(0)];
}

// CHECK: [[import:%[a-zA-Z0-9_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"
// CHECK: [[x_data:%[a-zA-Z0-9_]+]] = OpString "01000000020000000300000004000000"
// CHECK-DAG: [[void:%[a-zA-Z0-9_]+]] = OpTypeVoid
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK: OpExtInst [[void]] [[import]] ConstantDataStorageBuffer [[uint_1]] [[uint_0]] [[x_data]]

