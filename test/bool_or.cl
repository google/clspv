// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global int *out, int m, int n)
{
  bool a = m < 100;
  bool b = n > 50;
  if (a || b)
  {
    *out = 1;
  }
}

// CHECK: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK: [[true:%[a-zA-Z0-9_]+]] = OpConstantTrue [[bool]]
// CHECK: [[less:%[a-zA-Z0-9_]+]] = OpSLessThan [[bool]]
// CHECK: [[greater:%[a-zA-Z0-9_]+]] = OpSGreaterThan [[bool]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpSelect [[bool]] [[less]] [[true]] [[greater]]
// CHECK: OpBranchConditional [[or]]
