// RUN: clspv %s -o %t.spv -rewrite-packed-structs -int8
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: clspv %s -o %t.psb.spv -rewrite-packed-structs -int8 --physical-storage-buffers --arch=spir64 -spv-version=1.5
// RUN: spirv-dis -o %t2.psb.spvasm %t.psb.spv
// RUN: FileCheck --check-prefix=PSB %s < %t2.psb.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.psb.spv

typedef struct __attribute__((packed)) {
  char pad[12];
  char2 vec;
  char3 vec2;
} myPackedStruct;

__kernel void test_vec_align_packed_struct_arr(__global myPackedStruct *source,
                                               __global uint *dest) {
  int tid = get_global_id(0);
  dest[tid] = (uint)((__global uchar *)(&(source[tid].vec)) -
                     (__global uchar *)&source[0]);
}

// Verify the packed struct with unaligned vector members is lowered away and
// not reconstructed by SimplifyPointerBitcastPass.
// CHECK-NOT: OpTypeVector %uchar 3
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: OpIMul [[uint]] {{.*}}

// PSB-NOT: OpTypeVector %uchar 3
// PSB-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// PSB-DAG: [[uint_18:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 18
// PSB-DAG: [[uint_12:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 12
// PSB-DAG: [[arr18:%[a-zA-Z0-9_]+]] = OpTypeArray [[uchar]] [[uint_18]]
// PSB-DAG: [[ptr_arr18:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[arr18]]
// PSB-DAG: [[ptr_uchar:%[a-zA-Z0-9_]+]] = OpTypePointer PhysicalStorageBuffer [[uchar]]
// PSB: [[base:%[a-zA-Z0-9_]+]] = OpConvertUToPtr [[ptr_arr18]]
// PSB: OpPtrAccessChain [[ptr_uchar]] [[base]] {{.*}} [[uint_12]]
