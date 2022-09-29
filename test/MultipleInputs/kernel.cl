// RUN: clspv -o %t.spv %s %s2
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpEntryPoint GLCompute [[entry_point:%[^ ]+]] "foo"
// CHECK: [[entry_point]] = OpFunction
// CHECK-NEXT: OpLabel
// CHECK-NEXT: OpAccessChain
// CHECK-NEXT: OpAccessChain
// CHECK-NEXT: OpLoad
// CHECK-NEXT: OpStore
// CHECK-NEXT: OpReturn
// CHECK-NEXT: OpFunctionEnd

extern void bar(global uint *dst, global uint *src);

kernel void foo(global uint *dst, global uint *src) {
    bar(dst, src);
}
