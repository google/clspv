// RUN: clspv %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv -arch=spir64
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-64-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-64-DAG: %[[ulong_1:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 1
// CHECK-64-DAG: %[[ulong_2:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 2
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3

// CHECK-DAG: %[[ptr_input_v3uint:[0-9a-zA-Z_]+]] = OpTypePointer Input %[[v3uint]]
// CHECK-DAG: %[[gl_LocalInvocationID:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_input_v3uint]] Input

// CHECK-DAG: %[[gl_WorkGroupSize:[0-9a-zA-Z_]+]] = OpSpecConstantComposite %[[v3uint]]

// CHECK: OpFunction

// CHECK-32-DAG: %[[lid0_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[uint_0]]
// CHECK-32-DAG: %[[lid1_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[uint_1]]
// CHECK-32-DAG: %[[lid2_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[uint_2]]
// CHECK-64-DAG: %[[lid0_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[uint_0]]
// CHECK-64-DAG: %[[lid1_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[ulong_1]]
// CHECK-64-DAG: %[[lid2_ptr:[0-9]+]] = OpAccessChain {{.*}} %[[gl_LocalInvocationID]] %[[ulong_2]]
// CHECK-DAG: %[[lid0:[0-9]+]] = OpLoad %[[uint]] %[[lid0_ptr]]
// CHECK-DAG: %[[lid1:[0-9]+]] = OpLoad %[[uint]] %[[lid1_ptr]]
// CHECK-DAG: %[[lid2:[0-9]+]] = OpLoad %[[uint]] %[[lid2_ptr]]

// CHECK-DAG: %[[work_group_size:[0-9]+]] = {{.*}} %[[gl_WorkGroupSize]]
// CHECK-DAG: %[[size0:[0-9]+]] = OpCompositeExtract %[[uint]] %[[work_group_size]] 0
// CHECK-DAG: %[[size1:[0-9]+]] = OpCompositeExtract %[[uint]] %[[work_group_size]] 1

// operands could be in either order, but we can say operations happen in this order
// CHECK:     %[[res0:[0-9]+]] = OpIMul %[[uint]]{{.*}}%[[size1]]
// CHECK:     %[[res1:[0-9]+]] = OpIAdd %[[uint]]{{.*}}%[[res0]]
// CHECK:     %[[res2:[0-9]+]] = OpIMul %[[uint]]{{.*}}%[[res1]]
// CHECK:     %[[linear_id_result:[0-9]+]] = OpIAdd %[[uint]]{{.*}}%[[res2]]
// CHECK:     OpStore {{.*}} %[[linear_id_result]]

void kernel test(global uint *out) {
    out[0] = get_local_linear_id();
}

