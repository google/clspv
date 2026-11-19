// RUN: clspv %target %s --cl-std=CL2.0 --inline-entry-points -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target %s --cl-std=CL3.0 --inline-entry-points -enable-feature-macros=__opencl_c_generic_address_space -o %t.cl3.spv
// RUN: spirv-dis -o %t2.cl3.spvasm %t.cl3.spv
// RUN: FileCheck %s < %t2.cl3.spvasm --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.cl3.spv

// RUN: clspv %target %s --cl-std=CLC++ --inline-entry-points -o %t.cpp.spv
// RUN: spirv-dis -o %t2.cpp.spvasm %t.cpp.spv
// RUN: FileCheck %s < %t2.cpp.spvasm --implicit-check-not="OpCapability Float16"
// RUN: spirv-val --target-env vulkan1.0 %t.cpp.spv

static void store_half_vals(generic half *p, double v, double2 v2) {
  vstore_half(v, 0, p);
  vstorea_half2_rtn(v2, 1, p);
}

kernel void test_generic(global half *g, local half *l, double v, double2 v2) {
  store_half_vals(g, v, v2);
  store_half_vals(l, v, v2);
}

// CHECK-DAG: OpCapability Float64
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-COUNT-4: OpExtInst [[uint]] {{.*}} PackHalf2x16
