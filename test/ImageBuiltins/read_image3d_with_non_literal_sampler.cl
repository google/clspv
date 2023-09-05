// RUN: clspv %s -o %t.spv -cl-native-math
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

// CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
// CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[bool4:%[^ ]+]] = OpTypeVector [[bool]] 4
// CHECK-DAG: [[uint3:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG: [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG: [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_16:%[^ ]+]] = OpConstant [[uint]] 16
// CHECK-DAG: [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_48:%[^ ]+]] = OpConstant [[uint]] 48
// CHECK-DAG: [[uint_4:%[^ ]+]] = OpConstant [[uint]] 4

// CHECK:  [[convert:%[^ ]+]] = OpConvertSToF [[float4]] {{.*}}
// CHECK:  [[image_sizes:%[^ ]+]] = OpImageQuerySizeLod [[uint3]] {{.*}} [[uint_0]]
// CHECK:  [[image_sizes4:%[^ ]+]] = OpCompositeConstruct [[uint4]] [[image_sizes]] [[uint_0]]
// CHECK:  [[image_sizes_float:%[^ ]+]] = OpConvertSToF [[float4]] [[image_sizes4]]
// CHECK:  [[floor:%[^ ]+]] = OpExtInst [[float4]] {{.*}} Floor [[convert]]
// CHECK:  [[fadd:%[^ ]+]] = OpFAdd [[float4]] [[floor]] {{.*}}
// CHECK:  [[fdix_nearest:%[^ ]+]] = OpFDiv [[float4]] [[fadd]] [[image_sizes_float]]
// CHECK:  [[fdiv_linear:%[^ ]+]] = OpFDiv [[float4]] [[convert]] [[image_sizes_float]]
// CHECK:  [[gep_sampler_mask:%[^ ]+]] = OpAccessChain
// CHECK:  [[sampler_mask:%[^ ]+]] = OpLoad [[uint]] [[gep_sampler_mask]]
// CHECK:  [[and:%[^ ]+]] = OpBitwiseAnd [[uint]] [[sampler_mask]] [[uint_48]]
// CHECK:  [[cmp:%[^ ]+]] = OpIEqual [[bool]] [[and]] [[uint_16]]
// CHECK:  [[insert:%[^ ]+]] = OpCompositeInsert [[bool4]] [[cmp]] {{.*}} 0
// CHECK:  [[shuffle:%[^ ]+]] = OpVectorShuffle [[bool4]] [[insert]] {{.*}} 0 0 0 0
// CHECK:  [[select:%[^ ]+]] = OpSelect [[float4]] [[shuffle]] [[fdix_nearest]] [[fdiv_linear]]
// CHECK:  [[and:%[^ ]+]] = OpBitwiseAnd [[uint]] [[sampler_mask]] [[uint_1]]
// CHECK:  [[cmp:%[^ ]+]] = OpIEqual [[bool]] [[and]] [[uint_1]]
// CHECK:  [[insert:%[^ ]+]] = OpCompositeInsert [[bool4]] [[cmp]] {{.*}} 0
// CHECK:  [[shuffle:%[^ ]+]] = OpVectorShuffle [[bool4]] [[insert]] {{.*}} 0 0 0 0
// CHECK:  OpSelect [[float4]] [[shuffle]] [[convert]] [[select]]

// CHECK:  [[kernel:%[^ ]+]] = OpExtInst %void {{.*}} Kernel
// CHECK:  OpExtInst %void {{.*}} NormalizedSamplerMaskPushConstant [[kernel]] [[uint_1]] [[uint_16]] [[uint_4]]

kernel void foo(read_only image3d_t img, sampler_t sampler, global float4 *out, int4 coord) {
    *out = read_imagef(img, sampler, coord);
}
