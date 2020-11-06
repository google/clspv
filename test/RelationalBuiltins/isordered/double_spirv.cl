// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void foo(global int* out, double x, double y) {
  int i = 0;
  out[i++] = isordered(0.0, 0.0);
  out[i++] = isordered(as_double(0x7ff8000000000000), 0.0);
  out[i++] = isordered(0.0, as_double(0x7ff0000000000001));
  out[i++] = isordered(x, 0.0);
  out[i++] = isordered(x, as_double(0x7ff0000010000000));
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
// CHECK-DAG: [[double:%[a-zA-Z0-9_]+]] = OpTypeFloat 64
// CHECK: OpLabel
// CHECK-DAG: [[gep:%[a-zA-Z0-9_]+]] = OpAccessChain %{{.*}} %{{.*}} [[uint_0]] [[uint_0]]
// CHECK-DAG: OpStore [[gep]] [[uint_1]]
// CHECK-DAG: [[x:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[double]] {{.*}} 0
// CHECK-DAG: [[y:%[a-zA-Z0-9_]+]] = OpCompositeExtract [[double]] {{.*}} 1
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

