// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv


void kernel foo(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}


void kernel bar(global uint* a)
{
  a[0] = get_local_size(0);
  a[1] = get_local_size(1);
  a[2] = get_local_size(2);
  a[3] = get_local_size(3);
}

// CHECK: OpEntryPoint GLCompute [[_20:%[a-zA-Z0-9_]+]] "foo"
// CHECK: OpEntryPoint GLCompute [[_32:%[a-zA-Z0-9_]+]] "bar"
// CHECK: OpDecorate [[_gl_WorkGroupSize:%[a-zA-Z0-9_]+]] BuiltIn WorkgroupSize
// CHECK: OpDecorate [[_14:%[a-zA-Z0-9_]+]] SpecId 0
// CHECK: OpDecorate [[_15:%[a-zA-Z0-9_]+]] SpecId 1
// CHECK: OpDecorate [[_16:%[a-zA-Z0-9_]+]] SpecId 2
// CHECK-DAG: [[_uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[_v3uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[_uint]] 3
// CHECK: [[_14]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_15]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_16]] = OpSpecConstant [[_uint]] 1
// CHECK: [[_gl_WorkGroupSize]] = OpSpecConstantComposite [[_v3uint]] [[_14]] [[_15]] [[_16]]
// CHECK-DAG: [[_uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[_uint]] 1
// CHECK: [[_20]] = OpFunction
// CHECK: [[_23:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_24:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_23]] 0
// CHECK: OpStore {{.*}} [[_24]]
// CHECK: [[_25:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_26:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_25]] 1
// CHECK: OpStore {{.*}} [[_26]]
// CHECK: [[_28:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_29:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_28]] 2
// CHECK: OpStore {{.*}} [[_29]]
// CHECK: OpStore {{.*}} [[_uint_1]]
// CHECK: [[_32]] = OpFunction
// CHECK: [[_35:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_36:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_35]] 0
// CHECK: OpStore {{.*}} [[_36]]
// CHECK: [[_37:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_38:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_37]] 1
// CHECK: OpStore {{.*}} [[_38]]
// CHECK: [[_40:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[_v3uint]] [[_gl_WorkGroupSize]] [[_gl_WorkGroupSize]]
// CHECK: [[_41:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[_uint]] [[_40]] 2
// CHECK: OpStore {{.*}} [[_41]]
// CHECK: OpStore {{.*}} [[_uint_1]]
