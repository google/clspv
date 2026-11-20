// RUN: clspv %target %s -o %t.spv --cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: FileCheck %s < %t2.spvasm --check-prefix=FP64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t3.spv --use-native-builtins=sin,cos,tan,exp,exp2,exp10,expm1,log,log2,log10,log1p,pow,pown,sinpi,cospi,tanpi,sincos
// RUN: spirv-dis -o %t4.spvasm %t3.spv
// RUN: FileCheck %s < %t4.spvasm
// RUN: FileCheck %s < %t4.spvasm --check-prefixes=FP64,FP64-V3
// RUN: spirv-val --target-env vulkan1.0 %t3.spv

// RUN: clspv %target %s -vec3-to-vec4 -o %t5.spv --cl-native-math
// RUN: spirv-val --target-env vulkan1.0 %t5.spv

// Verify that float math builtins still lower to GLSL.std.450 while the same
// builtins overloaded on double stay in software libclc form.

// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: OpExtInst [[float]] {{.*}} Sin
// CHECK-DAG: OpExtInst [[float]] {{.*}} Cos
// CHECK-DAG: OpExtInst [[float]] {{.*}} Tan
// CHECK-DAG: OpExtInst [[float]] {{.*}} Exp
// CHECK-DAG: OpExtInst [[float]] {{.*}} Exp2
// CHECK-DAG: OpExtInst [[float]] {{.*}} Log
// CHECK-DAG: OpExtInst [[float]] {{.*}} Log2
// CHECK-DAG: OpExtInst [[float]] {{.*}} Pow

// Run FP64-NOT in a separate FileCheck invocation from the type section so it
// covers every function in the module.
// FP64-DAG: [[fp64_double:%[^ ]+]] = OpTypeFloat 64
// FP64-V3-DAG: [[fp64_v3double:%[^ ]+]] = OpTypeVector [[fp64_double]] 3
// FP64-DAG: [[fp64_v4double:%[^ ]+]] = OpTypeVector [[fp64_double]] 4
// FP64-NOT: OpExtInst [[fp64_double]] {{.*}} {{(Acos|Acosh|Asin|Asinh|Atan|Atanh|Atan2|Sin|Sinh|Cos|Cosh|Tan|Tanh|Exp|Exp2|Log|Log2|Pow)($| )}}
// FP64-V3-NOT: OpExtInst [[fp64_v3double]] {{.*}} {{(Acos|Acosh|Asin|Asinh|Atan|Atanh|Atan2|Sin|Sinh|Cos|Cosh|Tan|Tanh|Exp|Exp2|Log|Log2|Pow)($| )}}
// FP64-NOT: OpExtInst [[fp64_v4double]] {{.*}} {{(Acos|Acosh|Asin|Asinh|Atan|Atanh|Atan2|Sin|Sinh|Cos|Cosh|Tan|Tanh|Exp|Exp2|Log|Log2|Pow)($| )}}

kernel void test_mixed(global float *fo, global double *do_,
                       global double3 *do3, global double4 *do4, float f1,
                       float f2, double d, global double3 *di3,
                       global double4 *di4) {
  double dc;
  double4 dc4;
  *fo = sin(f1) + cos(f2) + tan(f1) + exp(f1) + exp2(f1) + exp10(f1) +
        expm1(f1) + log(f1) + log2(f1) + log10(f1) + log1p(f1) +
        pow(f1, 2.0f) + pown(f1, 3) + sinpi(f1) + cospi(f2);
  *do_ = sin(d) + cos(d) + tan(d) + exp(d) + exp2(d) + exp10(d) + expm1(d) +
         log(d) + log2(d) + log10(d) + log1p(d) + pow(d, 2.0) + pown(d, 3) +
         sinpi(d) + cospi(d) + tanpi(d) + sincos(d, &dc) + dc;
  *do3 = sin(*di3) + exp2(*di3) + cospi(*di3);
  *do4 = sin(*di4) + cos(*di4) + exp(*di4) + log(*di4) + log10(*di4) +
         pow(*di4, 2.0) + pown(*di4, 3) + tanpi(*di4) + sincos(*di4, &dc4) +
         dc4;
}
