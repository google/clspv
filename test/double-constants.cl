// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[double:[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: %[[double_0:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 0
// CHECK-DAG: %[[double_1_2:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 1.2
// CHECK-DAG: %[[double_3_0303030303030303:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 3.0303030303030303
// CHECK-DAG: %[[double_n42_314:[0-9a-zA-Z_]+]] = OpConstant %[[double]] -42.314
// CHECK-DAG: %[[double_314_42000000000002:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 314.42000000000002
// CHECK-DAG: %[[double_3140000000:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 3140000000
// CHECK-DAG: %[[double_3_1399999999999998en05:[0-9a-zA-Z_]+]] = OpConstant %[[double]] 3.1399999999999998e-05

void kernel test()
{
    volatile double a = 1.2;
    volatile double b = 100.0 / 33.0;
    volatile double c = -42.314;
    volatile double d = 314.42;
    volatile double e = 314e7;
    volatile double f = 314e-7;
}

