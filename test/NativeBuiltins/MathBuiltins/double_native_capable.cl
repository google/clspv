// RUN: clspv %target %s -o %t.spv --cl-native-math
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s -o %t3.spv --use-native-builtins=ceil,copysign,degrees,distance,fabs,fdim,floor,fma,fmax,fmin,fmod,fract,frexp,ldexp,length,mad,mix,normalize,radians,rint,round,rsqrt,sign,smoothstep,sqrt,step,trunc
// RUN: spirv-dis -o %t4.spvasm %t3.spv
// RUN: FileCheck %s < %t4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t3.spv

// RUN: clspv %target %s -vec3-to-vec4 -o %t5.spv --cl-native-math
// RUN: spirv-val --target-env vulkan1.0 %t5.spv

// Verify that 64-bit native-capable builtins still use native GLSL.std.450 /
// IR lowerings under --cl-native-math and --use-native-builtins.

// CHECK-DAG: [[double:%[^ ]+]] = OpTypeFloat 64
// CHECK-DAG: [[v3double:%[^ ]+]] = OpTypeVector [[double]] 3
// CHECK-DAG: [[v4double:%[^ ]+]] = OpTypeVector [[double]] 4
// CHECK-DAG: OpExtInst [[double]] {{.*}} Sqrt
// CHECK-DAG: OpExtInst [[double]] {{.*}} InverseSqrt
// CHECK-DAG: OpExtInst [[double]] {{.*}} Floor
// CHECK-DAG: OpExtInst [[double]] {{.*}} Ceil
// CHECK-DAG: OpExtInst [[double]] {{.*}} Trunc
// CHECK-DAG: OpExtInst [[double]] {{.*}} RoundEven
// CHECK-DAG: OpExtInst [[double]] {{.*}} Fma
// CHECK-DAG: OpExtInst [[double]] {{.*}} NMin
// CHECK-DAG: OpExtInst [[double]] {{.*}} NMax
// CHECK-DAG: OpExtInst [[double]] {{.*}} FSign
// CHECK-DAG: OpExtInst [[double]] {{.*}} Frexp
// CHECK-DAG: OpExtInst [[double]] {{.*}} Ldexp
// CHECK-DAG: OpExtInst [[double]] {{.*}} Fract
// CHECK-DAG: OpExtInst [[double]] {{.*}} Length
// CHECK-DAG: OpExtInst [[double]] {{.*}} Distance
// CHECK-DAG: OpExtInst [[v3double]] {{.*}} Cross
// CHECK-DAG: OpExtInst [[v3double]] {{.*}} Normalize
// CHECK-DAG: OpExtInst [[v4double]] {{.*}} FMix
// CHECK-DAG: OpExtInst [[v4double]] {{.*}} Step
// CHECK-DAG: OpExtInst [[v4double]] {{.*}} SmoothStep

kernel void test_native_fp64(global double *o1, global double3 *o3,
                             global double4 *o4, double s, global double3 *a3,
                             global double4 *a4) {
  int e = 0;
  double frac_i = 0.0;
  double r = sqrt(s) + rsqrt(s) + fabs(s) + floor(s) + ceil(s) + trunc(s) +
             rint(s) + round(s) + fma(s, s, 1.0) + mad(s, 2.0, 1.0) +
             fmin(s, 1.0) + fmax(s, 0.0) + fdim(s, 1.0) + copysign(s, -1.0) +
             fmod(s, 2.0) + sign(s) + ldexp(frexp(s, &e), e) +
             fract(s, &frac_i) + frac_i + degrees(radians(s));
  *o1 = r + length(*a3) + distance(*a3, *a3 * 2.0);
  *o3 = normalize(cross(*a3, *a3 * 3.0));
  *o4 = mix(*a4, *a4 * 2.0, 0.5) + step(0.5, *a4) + smoothstep(0.0, 1.0, *a4);
}
