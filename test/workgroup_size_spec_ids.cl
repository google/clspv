// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck --check-prefix=MAP %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void copy(global int* out, global int* in) {
  *out = *in;
}

// CHECK: OpDecorate [[wgsize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[wgx:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[wgy:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[wgz:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK: [[wgsize]] = OpSpecConstantComposite {{.*}} [[wgx]] [[wgy]] [[wgz]]

// MAP: spec_constant,workgroup_size_x,spec_id,0
// MAP: spec_constant,workgroup_size_y,spec_id,1
// MAP: spec_constant,workgroup_size_z,spec_id,2
