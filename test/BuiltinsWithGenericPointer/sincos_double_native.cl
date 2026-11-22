// RUN: clspv %target %s --cl-std=CL2.0 --inline-entry-points --use-native-builtins=sincos -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space --use-native-builtins=sincos -o %t.cl3.spv
// RUN: spirv-dis -o %t2.cl3.spvasm %t.cl3.spv
// RUN: FileCheck %s < %t2.cl3.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.cl3.spv

// RUN: clspv %target %s --cl-std=CLC++ --inline-entry-points --use-native-builtins=sincos -o %t.cpp.spv
// RUN: spirv-dis -o %t2.cpp.spvasm %t.cpp.spv
// RUN: FileCheck %s < %t2.cpp.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.cpp.spv

// CHECK: OpCapability Float64
// CHECK-NOT: OpExtInst %{{.*}} %{{.*}} {{(Sin|Cos)($| )}}

static double sincos_generic(double x, generic double *c) {
  return sincos(x, c);
}

static double2 sincos_generic2(double2 x, generic double2 *c) {
  return sincos(x, c);
}

kernel void test(global double *out, global double *cos_out,
                 local double *cos_local, global double2 *out2,
                 global double2 *cos_out2, double x) {
  out[0] = sincos_generic(x, cos_out);
  out[1] = sincos_generic(x, cos_local);
  cos_out[1] = *cos_local;
  out2[0] = sincos_generic2(out2[1], cos_out2);
}
