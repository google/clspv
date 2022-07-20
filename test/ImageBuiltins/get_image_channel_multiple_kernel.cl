// RUN: clspv %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

void kernel fct0(global int *dst, int off, image1d_t read_only image) { *dst = get_image_channel_order(image) + off; }

void kernel fct1(global int *dst, image1d_t read_only image, int off) { *dst = get_image_channel_data_type(image) + off; }

void kernel fct2(global int *dst, image1d_t read_only image1, image1d_t read_only image2, int off)
{
    *dst = get_image_channel_order(image1) + get_image_channel_order(image2) + get_image_channel_data_type(image1)
        + get_image_channel_data_type(image2) + off;
}

// CHECK: OpEntryPoint GLCompute [[fct0:%[^ ]+]] "fct0"
// CHECK: OpEntryPoint GLCompute [[fct1:%[^ ]+]] "fct1"
// CHECK: OpEntryPoint GLCompute [[fct2:%[^ ]+]] "fct2"

// CHECK: [[fct0_str:%[^ ]+]] = OpString "fct0"
// CHECK: [[fct1_str:%[^ ]+]] = OpString "fct1"
// CHECK: [[fct2_str:%[^ ]+]] = OpString "fct2"

// CHECK:  OpMemberDecorate [[off:%[^ ]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[pc_channel_struct:%[^ ]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[pc_channel_struct]] 1 Offset 4
// CHECK:  OpMemberDecorate [[pc_channel_struct]] 2 Offset 8
// CHECK:  OpMemberDecorate [[pc_channel_struct]] 3 Offset 12
// CHECK:  OpMemberDecorate [[pc_struct:%[^ ]+]] 0 Offset 0
// CHECK:  OpMemberDecorate [[pc_struct]] 1 Offset 4
// CHECK:  OpDecorate [[pc_struct]] Block

// CHECK:  [[off]] = OpTypeStruct %uint
// CHECK:  [[pc_channel_struct]] = OpTypeStruct %uint %uint %uint %uint
// CHECK:  [[pc_struct]] = OpTypeStruct [[off]] [[pc_channel_struct]]
// CHECK:  [[ptr_pc_struct:%[^ ]+]] = OpTypePointer PushConstant [[pc_struct]]
// CHECK:  [[ptr_pc_int:%[^ ]+]] = OpTypePointer PushConstant %uint

// CHECK:  [[pc_var:%[^ ]+]] = OpVariable [[ptr_pc_struct]] PushConstant

// CHECK:  [[fct0]] = OpFunction
// CHECK:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_0
// CHECK:  [[fct1]] = OpFunction
// CHECK:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_0
// CHECK:  [[fct2]] = OpFunction
// CHECK-DAG:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_0
// CHECK-DAG:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_1
// CHECK-DAG:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_2
// CHECK-DAG:  OpAccessChain [[ptr_pc_int]] [[pc_var]] %uint_1 %uint_3

// CHECK:  [[kernel0:%[^ ]+]] = OpExtInst %void {{.*}} Kernel [[fct0]] [[fct0_str]]
// CHECK:  ImageArgumentInfoChannelOrderPushConstant [[kernel0]] %uint_1 %uint_4 %uint_4
// CHECK:  [[kernel1:%[^ ]+]] = OpExtInst %void {{.*}} Kernel [[fct1]] [[fct1_str]]
// CHECK:  ImageArgumentInfoChannelDataTypePushConstant [[kernel1]] %uint_1 %uint_4 %uint_4
// CHECK:  [[kernel2:%[^ ]+]] = OpExtInst %void {{.*}} Kernel [[fct2]] [[fct2_str]]
// CHECK-DAG:  ImageArgumentInfoChannelOrderPushConstant [[kernel2]] %uint_1 %uint_4 %uint_4
// CHECK-DAG:  ImageArgumentInfoChannelOrderPushConstant [[kernel2]] %uint_2 %uint_8 %uint_4
// CHECK-DAG:  ImageArgumentInfoChannelDataTypePushConstant [[kernel2]] %uint_1 %uint_12 %uint_4
// CHECK-DAG:  ImageArgumentInfoChannelDataTypePushConstant [[kernel2]] %uint_2 %uint_16 %uint_4
