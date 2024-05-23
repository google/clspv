// RUN: clspv %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck  --check-prefixes=CHECK %s < %t2.spvasm
// RUN: FileCheck --check-prefix=NO-OFFSET %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL2.0 -inline-entry-points -global-offset=1 %s -o %t.spv -arch=spir
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK
// RUN: FileCheck --check-prefix=CHECK-OFFSET %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3

// CHECK-DAG: %[[ptr_input_uint:[0-9a-zA-Z_]+]] = OpTypePointer Input %[[uint]]

// CHECK-DAG: %[[push:[0-9a-zA-Z_]+]] = OpVariable {{.*}} PushConstant
// CHECK-DAG: %[[push_ptr_int:[0-9a-zA-Z_]+]] = OpTypePointer PushConstant %[[uint]]

// CHECK-DAG: %[[ptr_input_v3uint:[0-9a-zA-Z_]+]] = OpTypePointer Input %[[v3uint]]
// CHECK-DAG: %[[gl_GlobalInvocationID:[0-9a-zA-Z_]+]] = OpVariable %[[ptr_input_v3uint]] Input

// CHECK: OpFunction

// CHECK-DAG: %[[gid0_ptr:[0-9]+]] = OpAccessChain %[[ptr_input_uint]] %[[gl_GlobalInvocationID]] %[[uint_0]]
// CHECK-DAG: %[[gid1_ptr:[0-9]+]] = OpAccessChain %[[ptr_input_uint]] %[[gl_GlobalInvocationID]] %[[uint_1]]
// CHECK-DAG: %[[gid2_ptr:[0-9]+]] = OpAccessChain %[[ptr_input_uint]] %[[gl_GlobalInvocationID]] %[[uint_2]]

// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[gid0_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[gid1_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[gid2_ptr]]

// can't tell which is global offset and which is global size
// CHECK-DAG: %[[goff0_ptr:[0-9]+]] = OpAccessChain %[[push_ptr_int]] %[[push]] {{.*}} %[[uint_0]]
// CHECK-DAG: %[[goff1_ptr:[0-9]+]] = OpAccessChain %[[push_ptr_int]] %[[push]] {{.*}} %[[uint_1]]
// CHECK-DAG: %[[goff2_ptr:[0-9]+]] = OpAccessChain %[[push_ptr_int]] %[[push]] {{.*}} %[[uint_2]]
// CHECK-DAG: %[[gsize0_ptr:[0-9]+]] = OpAccessChain %[[push_ptr_int]] %[[push]] {{.*}} %[[uint_0]]
// CHECK-DAG: %[[gsize1_ptr:[0-9]+]] = OpAccessChain %[[push_ptr_int]] %[[push]] {{.*}} %[[uint_1]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[goff0_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[goff1_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[goff2_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[gsize0_ptr]]
// CHECK-DAG: %{{[0-9]+}} = OpLoad %[[uint]] %[[gsize1_ptr]]

// operands could be in either order, but we can say operations happen in this order
// CHECK:     %[[res1:[0-9]+]] = OpIMul %[[uint]]
// CHECK:     %[[res2:[0-9]+]] = OpIAdd %[[uint]]{{.*}}%[[res1]]
// CHECK:     %[[res3:[0-9]+]] = OpIMul %[[uint]]{{.*}}%[[res2]]
// CHECK:     %[[linear_id_result:[0-9]+]] = OpIAdd %[[uint]]{{.*}}%[[res3]]
// CHECK:     OpStore {{.*}} %[[linear_id_result]]

// when offset is enabled we expect three subtractions
// CHECK-OFFSET: OpISub
// CHECK-OFFSET: OpISub
// CHECK-OFFSET: OpISub

// otherwise we do not expect subtractions
// NO-OFFSET-NOT: OpISub

void kernel test(global uint *out) {
    out[0] = get_global_linear_id();
}

