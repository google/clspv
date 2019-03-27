// RUN: clspv %s -S -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  for (uint i = 0; i < b; i++)
  {
    a[i]++;
  }
}

// CHECK: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[int]]
// CHECK: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0
// CHECK: [[one:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1
// CHECK: [[entry:%[a-zA-Z0-9_]+]] = OpLabel
// CHECK: OpBranchConditional {{.*}} [[loop:%[a-zA-Z0-9_]+]] [[ret:%[a-zA-Z0-9_]+]]
// CHECK: [[ret]] = OpLabel
// CHECK-NEXT: OpReturn
// CHECK: [[loop]] = OpLabel
// CHECK-NEXT: [[phi:%[a-zA-Z0-9_]+]] = OpPhi [[int]] [[inc:%[a-zA-Z0-9_]+]] [[loop]] [[zero]] [[entry]]
// CHECK-NEXT: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] {{.*}} [[zero]] [[phi]]
// CHECK-NEXT: [[ld:%[a-zA-Z0-9_]+]] = OpLoad [[int]] [[gep]]
// CHECK-NEXT: [[add:%[a-zA-Z0-9_]+]] = OpIAdd [[int]] [[ld]] [[one]]
// CHECK-NEXT: OpStore [[gep]] [[add]]
// CHECK-NEXT: [[inc]] = OpIAdd [[int]] [[phi]] [[one]]
// CHECK: OpLoopMerge [[merge:%[a-zA-Z0-9_]+]] [[loop]] None
// CHECK-NEXT: OpBranchConditional {{.*}} [[merge]] [[loop]]
// CHECK: [[merge]] = OpLabel
// CHECK-NEXT: OpBranch [[ret]]
