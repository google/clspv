// RUN: clspv %s -o %t.spv -hack-image1d-buffer-bgra -spv-version=1.4 --print-before=fixup-builtins &> %t.ll
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.4

// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[CL_BGRA:%[^ ]+]] = OpConstant [[uint]] 4278

// CHECK:  [[fetch:%[^ ]+]] = OpImageFetch [[float4]]
// CHECK:  [[shuffle:%[^ ]+]] = OpVectorShuffle [[float4]] [[fetch]] {{.*}} 2 1 0 3
// CHECK:  [[gep_channel_image_order:%[^ ]+]] = OpAccessChain {{.*}} {{.*}} [[uint_0]] [[uint_0]]
// CHECK:  [[channel_image_order:%[^ ]+]] = OpLoad %uint [[gep_channel_image_order]]
// CHECK:  [[cmp:%[^ ]+]] = OpIEqual %bool [[channel_image_order]] [[CL_BGRA]]
// CHECK:  OpSelect %v4float [[cmp]] [[shuffle]] [[fetch]]

__kernel void sample_kernel( read_only image1d_buffer_t inputA, read_only image1d_t inputB, sampler_t sampler, __global int *results )
{
   int tidX = get_global_id(0);
   int offset = tidX;
   float4 clr = read_imagef( inputA, tidX );
   int4 test = (clr != read_imagef( inputB, sampler, tidX ));
   if ( test.x || test.y || test.z || test.w )
      results[offset] = -1;
   else
      results[offset] = 0;
}

