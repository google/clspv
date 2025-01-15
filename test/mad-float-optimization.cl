// RUN: clspv %target %s -o %t.unsafe.spv --cl-unsafe-math-optimizations
// RUN: spirv-dis -o %t.unsafe.spvasm %t.unsafe.spv
// RUN: FileCheck %s < %t.unsafe.spvasm
// RUN: spirv-val --target-env spv1.0 %t.unsafe.spv

// RUN: clspv %target %s -o %t.mad.spv --cl-mad-enable
// RUN: spirv-dis -o %t.mad.spvasm %t.mad.spv
// RUN: FileCheck %s < %t.mad.spvasm
// RUN: spirv-val --target-env spv1.0 %t.mad.spv

// RUN: clspv %target %s -o %t.native.spv --use-native-builtins=fma
// RUN: spirv-dis -o %t.native.spvasm %t.native.spv
// RUN: FileCheck %s < %t.native.spvasm
// RUN: spirv-val --target-env spv1.0 %t.native.spv

// CHECK: OpExtInst {{.*}} Fma

// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s --check-prefix=NOOPT < %t.spvasm
// RUN: spirv-val --target-env spv1.0 %t.spv

// NOOPT-NOT: OpExtInst {{.*}} Fma

void kernel foo(global float* a) {
    a[0] = mad(a[1], a[2], a[3]);
}
