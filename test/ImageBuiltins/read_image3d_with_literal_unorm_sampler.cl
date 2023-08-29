// RUN: clspv %s -o %t.spv --cl-native-math
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK-DAG:  [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG:  [[float:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG:  [[uint3:%[^ ]+]] = OpTypeVector [[uint]] 3
// CHECK-DAG:  [[uint4:%[^ ]+]] = OpTypeVector [[uint]] 4
// CHECK-DAG:  [[float4:%[^ ]+]] = OpTypeVector [[float]] 4
// CHECK-DAG:  [[float_0:%[^ ]+]] = OpConstant [[float]] 0
// CHECK-DAG:  [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
// CHECK-DAG:  [[uint_1:%[^ ]+]] = OpConstant [[uint]] 1
// CHECK-DAG:  [[uint_21:%[^ ]+]] = OpConstant [[uint]] 21
// CHECK-DAG:  [[vec:%[^ ]+]] = OpConstantComposite [[uint4]] [[uint_1]] [[uint_1]] [[uint_1]] [[uint_1]]

// CHECK:  [[sizes:%[^ ]+]] = OpImageQuerySizeLod [[uint3]] {{.*}} [[uint_0]]
// CHECK:  [[shuffle:%[^ ]+]] = OpVectorShuffle [[uint4]] [[sizes]] [[vec]] 0 1 2 4
// CHECK:  [[convert:%[^ ]+]] = OpConvertUToF [[float4]] [[shuffle]]
// CHECK:  [[div:%[^ ]+]] = OpFDiv [[float4]] %44 [[convert]]
// CHECK:  OpImageSampleExplicitLod [[float4]] {{.*}} [[div]] Lod [[float_0]]

// CHECK:  OpExtInst %void {{.*}} LiteralSampler [[uint_0]] [[uint_0]] [[uint_21]]

static const sampler_t my_sampler = CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST | CLK_NORMALIZED_COORDS_FALSE;

void kernel foo(read_only image3d_t img, global float4 *out, int i)
{
    *out = read_imagef(img, my_sampler, (int4)(2, 3, 4, 5));
}
