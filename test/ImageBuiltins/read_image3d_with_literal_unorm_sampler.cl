// RUN: clspv %s -o %t.spv --cl-native-math
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG:  [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG:  [[uint3:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG:  [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG:  [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG:  [[float_0_5:%[^ ]+]] = OpConstant [[float]] 0.5
// CHECK-DAG:  [[float_0:%[^ ]+]] = OpConstant [[float]] 0
// CHECK-DAG:  [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG:  [[uint_21:%[^ ]+]] = OpConstant [[uint]] 21

// CHECK:  [[sizes:%[^ ]+]] = OpImageQuerySizeLod [[uint3]] {{.*}} [[uint_0]]
// CHECK:  [[shuffle:%[^ ]+]] = OpCompositeConstruct [[uint4]] [[sizes]] [[uint_0]]
// CHECK:  [[convert:%[^ ]+]] = OpConvertSToF [[float4]] [[shuffle]]
// CHECK:  [[floor:%[^ ]+]] = OpExtInst [[float4]] {{.*}} Floor {{.*}}
// CHECK:  [[add:%[^ ]+]] = OpFAdd [[float4]] [[floor]] {{.*}}
// CHECK:  [[div:%[^ ]+]] = OpFDiv [[float4]] [[add]] [[convert]]
// CHECK:  OpImageSampleExplicitLod [[float4]] {{.*}} [[div]] Lod [[float_0]]

// CHECK:  OpExtInst %void {{.*}} LiteralSampler [[uint_0]] [[uint_0]] [[uint_21]]

static const sampler_t my_sampler = CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE;

void kernel foo(read_only image3d_t img, global float4 *out, int i)
{
    *out = read_imagef(img, my_sampler, (int4)(2, 3, 4, 5));
}
