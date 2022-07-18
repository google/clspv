// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void foo( __global char* dst, __global char * src, const int n )
{
   size_t gid = get_global_id(0);
   int cond = 0;
   cond = n ? 1 : cond;
   cond = src[n] ? 2 : cond;

   switch(cond) {
   case 0:
      dst[gid] = src[gid];
   case 1:
      dst[gid + 7] = src[gid - 2];
   case 2:
      dst[gid + 3] = src[gid + 2];
   }
}

// CHECK-NOT: OpTypeInt 2 0
// CHECK: OpTypeInt 8 0
// CHECK-NOT: OpTypeInt 8 0
// CHECK-NOT: OpTypeInt 2 0
