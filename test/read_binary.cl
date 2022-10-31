// RUN: clspv %s --output-format=bc -o %t.bc
// RUN: clspv -x ir %t.bc -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm

void kernel foo(global int *out, global int *in)
{
    *out = *in;
}

// CHECK: OpFunction
// CHECK-NEXT: OpLabel
// CHECK-NEXT: OpAccessChain
// CHECK-NEXT: OpAccessChain
// CHECK-NEXT: OpLoad
// CHECK-NEXT: OpStore
// CHECK-NEXT: OpReturn
// CHECK-NEXT: OpFunctionEnd

