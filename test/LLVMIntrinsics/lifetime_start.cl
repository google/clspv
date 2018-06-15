// Remove @llvm.lifetime.start.*
// Fixes https://github.com/google/clspv/issues/142


// RUN: clspv %s -S -o %t.spvasm -cluster-pod-kernel-args
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv %s -o %t.spv -cluster-pod-kernel-args
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Just check that the compiler works at all.

// CHECK: ; SPIR-V
// CHECK: ; Version: 1.0
// CHECK: OpEntryPoint
// CHECK: OpFunctionEnd

#define CHUNK_SIZE 32

kernel void cfc(global const int *in, global int *out, int limit) {
  size_t x = get_global_id(0);

  int temp[CHUNK_SIZE];
  for (int i = 0; i < CHUNK_SIZE; ++i) {
    temp[i] = in[i];
  }

  if (x < limit) {
    out[x] = x;
  } else {
    out[x] = temp[x % CHUNK_SIZE];
  }
}
