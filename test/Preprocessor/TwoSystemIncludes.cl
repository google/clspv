// RUN: clspv %target -I %S/SomeIncludeDirectory -I %S/AnotherIncludeDirectory %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute %[[FOO_ID:[a-zA-Z0-9_]*]] "foo"
// CHECK: OpEntryPoint GLCompute %[[BAR_ID:[a-zA-Z0-9_]*]] "bar"
// CHECK: OpExecutionMode %[[FOO_ID]] LocalSize 4 2 1
// CHECK: OpExecutionMode %[[BAR_ID]] LocalSize 5 3 2

#include <SomeHeader.h>

#include <AnotherHeader.h>
