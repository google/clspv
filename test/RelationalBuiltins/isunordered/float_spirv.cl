// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* out, float x, float y) {
  int i = 0;
  out[i++] = isunordered(0.0f, 0.0f);
  out[i++] = isunordered(as_float(0x7ff00000), 0.0f);
  out[i++] = isunordered(0.0f, as_float(0x7f800001));
  out[i++] = isunordered(x, 0.0f);
  out[i++] = isunordered(x, as_float(0x7fc00000));
  out[i++] = isunordered(x, y);
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
// CHECK: OpLabel
// CHECK-DAG: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_0]]
// CHECK-DAG: OpStore [[gep]] [[uint_0]]
// CHECK-DAG: [[x:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[float]] {{.*}} 0
// CHECK-DAG: [[y:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[float]] {{.*}} 1
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_1]]
// CHECK: OpStore [[gep]] [[uint_1]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_2]]
// CHECK: OpStore [[gep]] [[uint_1]]
// CHECK: [[is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[x]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[is_nan]] [[uint_1]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_3]]
// CHECK: OpStore [[gep]] [[sel]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_4]]
// CHECK: OpStore [[gep]] [[uint_1]]
// CHECK: [[x_is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[x]]
// CHECK: [[y_is_nan:%[a-zA-Z0-9_]+]] = OpIsNan [[bool]] [[y]]
// CHECK: [[or:%[a-zA-Z0-9_]+]] = OpLogicalOr [[bool]] [[x_is_nan]] [[y_is_nan]]
// CHECK: [[sel:%[a-zA-Z0-9_]+]] = OpSelect [[uint]] [[or]] [[uint_1]] [[uint_0]]
// CHECK: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_5]]
// CHECK: OpStore [[gep]] [[sel]]
