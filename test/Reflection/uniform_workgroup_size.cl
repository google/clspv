// RUN: clspv %s -o %t.spv -cl-std=CLC++ -inline-entry-points -uniform-workgroup-size
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* out) {
  int gid = get_global_id(0);
  out[gid] = gid;
}

// CHECK-NOT: OpTypePointer PushConstant
// CHECK-NOT: PushConstantRegionOffset

