// RUN: clspv %target %s -o %t.spv -spv-version=1.4
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

kernel void foo(global int* out, float a, float b) {
  half x = a;
  half y = b;
  int i = 0;
  out[i++] = isordered((half)0.0f, (half)0.0f);
  out[i++] = isordered(as_half((ushort)0x7e00), (half)0.0f);
  out[i++] = isordered((half)0.0f, as_half((ushort)0x7c01));
  out[i++] = isordered(x, (half)0.0f);
  out[i++] = isordered(x, as_half((ushort)0x7c10));
  out[i++] = isordered(x, y);
}

// CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[uint_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[uint_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[uint_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[uint_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[uint_5:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 5
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
// CHECK: OpLabel
// CHECK-DAG: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_0]]
// CHECK-DAG: OpStore [[gep]] [[uint_1]]
// CHECK-DAG: [[a:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK-DAG: [[b:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[float]] {{.*}} 1
// CHECK-DAG: [[x:%[a-zA-Z0-9_]+]] = OpFConvert [[half]] [[a]]
// CHECK-DAG: [[y:%[a-zA-Z0-9_]+]] = OpFConvert [[half]] [[b]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_1]]
// CHECK: OpStore [[gep]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_2]]
// CHECK: OpStore [[gep]] [[uint_0]]
// CHECK: [[is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[x]]
// CHECK: [[not:%[a-zA-Z0-9_]+]] = OpLogicalNot [[bool]] [[is_nan]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[not]] [[uint_1]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_3]]
// CHECK: OpStore [[gep]] [[sel]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_4]]
// CHECK: OpStore [[gep]] [[uint_0]]
// CHECK: [[x_is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[x]]
// CHECK: [[y_is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[y]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpLogicalOr [[bool]] [[x_is_nan]] [[y_is_nan]]
// CHECK: [[not:%[a-zA-Z0-9_]+]] = OpLogicalNot [[bool]] [[or]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[not]] [[uint_1]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_5]]
// CHECK: OpStore [[gep]] [[sel]]

