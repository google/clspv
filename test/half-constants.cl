// RUN: clspv  %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

//     CHECK: OpCapability Float16
// CHECK-DAG: %[[half:[0-9a-zA-Z_]+]] = OpTypeFloat 16
// CHECK-DAG: %[[half_0:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x0p+0
// CHECK-DAG: %[[half_1:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x1p+0
// CHECK-DAG: %[[half_1_25:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x1.4p+0
// CHECK-DAG: %[[half_n4_5:[0-9a-zA-Z_]+]] = OpConstant %[[half]] -0x1.2p+2
// CHECK-DAG: %[[half_0_025:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x1.998p-6
// CHECK-DAG: %[[half_16e2:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x1.9p+10
// CHECK-DAG: %[[half_2:[0-9a-zA-Z_]+]] = OpConstant %[[half]] 0x1p+1

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel test()
{
    volatile half a = 1.0h;
    volatile half b = 1.25h;
    volatile half c = -4.5h;
    volatile half d = 0.025h;
    volatile half e = 16e2h;
    volatile half f = 4.0h / 2.0h;
}

