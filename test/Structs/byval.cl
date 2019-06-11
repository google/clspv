// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


struct test {
  int a[128];
};

void boo(struct test byval) {
}


void kernel __attribute__((reqd_work_group_size(1, 2, 3))) foo(void) {
  struct test byval;
  boo(byval);
}
// CHECK:  ; SPIR-V
// CHECK:  ; Version: 1.0
// CHECK:  ; Bound: 5
// CHECK:  ; Schema: 0
// CHECK:  OpCapability Shader
// CHECK:  OpExtension "SPV_KHR_storage_buffer_storage_class"
// CHECK:  OpMemoryModel Logical GLSL450
// CHECK:  OpEntryPoint GLCompute [[_4:%[0-9a-zA-Z_]+]] "foo"
// CHECK:  OpExecutionMode [[_4]] LocalSize 1 2 3
// CHECK:  OpSource OpenCL_C 120
// CHECK:  [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK:  [[_3:%[0-9a-zA-Z_]+]] = OpTypeFunction [[_void]]
// CHECK:  [[_4]] = OpFunction [[_void]] Const [[_3]]
// CHECK:  [[_5:%[0-9a-zA-Z_]+]] = OpLabel
// CHECK:  OpReturn
// CHECK:  OpFunctionEnd
