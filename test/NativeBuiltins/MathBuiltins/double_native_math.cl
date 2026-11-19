// RUN: clspv %target %s -o %t.spv --cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t3.spv --use-native-builtins=acos,acosh,acospi,asin,asinh,asinpi,atan,atan2,atan2pi,atanh,atanpi,cos,cosh,cospi,exp,exp2,exp10,expm1,log,log2,log10,log1p,pow,pown,powr,sin,sincos,sinh,sinpi,tan,tanh,tanpi
// RUN: spirv-dis -o %t4.spvasm %t3.spv
// RUN: FileCheck %s < %t4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t3.spv

// RUN: clspv %target %s -vec3-to-vec4 -o %t5.spv --cl-native-math
// RUN: spirv-val --target-env vulkan1.0 %t5.spv

// Verify that FP64 math builtins lacking 64-bit Vulkan SPIR-V GLSL.std.450
// support keep their libclc implementations under --cl-native-math and
// --use-native-builtins, including transitive callers (erf/erfc/gamma/rootn).

// CHECK: OpCapability Float64
// CHECK-NOT: OpExtInst %{{.*}} %{{.*}} {{(Acos|Acosh|Asin|Asinh|Atan|Atanh|Atan2|Sin|Sinh|Cos|Cosh|Tan|Tanh|Exp|Exp2|Log|Log2|Pow)($| )}}

kernel void test_fp64_scalar(global double *out, local double *loc, double x,
                             double y, int n) {
  double c_priv = 0.0;
  double s_priv = sincos(x, &c_priv);
  double s_loc = sincos(x, loc);
  int signp = 0;

  out[0] = sin(x) + cos(x) + tan(x) + asin(x) + acos(x) + atan(x) + atan2(x, y);
  out[1] = sinh(x) + cosh(x) + tanh(x) + asinh(x) + acosh(x) + atanh(x);
  out[2] = exp(x) + exp2(x) + exp10(x) + expm1(x) + log(x) + log2(x) + log10(x) +
           log1p(x);
  out[3] = pow(x, y) + powr(x, y) + pown(x, n) + sinpi(x) + cospi(x) + tanpi(x) +
           asinpi(x) + acospi(x) + atanpi(x) + atan2pi(x, y);
  out[4] = s_priv + c_priv + s_loc + *loc + erf(x) + erfc(x) + lgamma(x) +
           lgamma_r(x, &signp) + (double)signp + tgamma(x) + rootn(x, n);
}

kernel void test_fp64_vectors(global double2 *o2, global double3 *o3,
                              global double4 *o4, global double2 *a2,
                              global double3 *a3, global double4 *a4, int3 n3,
                              int4 n4) {
  double3 c3;
  *o2 = sin(*a2) + exp10(*a2) + powr(*a2, 2.0) + atan2pi(*a2, *a2);
  *o3 = cos(*a3) + tanpi(*a3) + sincos(*a3, &c3) + c3 + pown(*a3, n3);
  *o4 = exp(*a4) + log(*a4) + log1p(*a4) + pow(*a4, 2.0) + pown(*a4, n4);
}
