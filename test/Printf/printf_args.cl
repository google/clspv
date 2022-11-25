// RUN: clspv %s -o %t.spv -enable-printf
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %s -o %t.spv -enable-printf -enable-opaque-pointers
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

kernel void test(char c, short s, int i, float f, long l) {
    printf("Argument: %f", f);
    printf("Arguments: %c %hd %d %f %ld", c, s, i, f, l);
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[double:[0-9a-zA-Z_]+]] = OpTypeFloat 64
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[zero:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[one:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1{{$}}
// CHECK-DAG: %[[two:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2{{$}}
// CHECK-DAG: %[[four:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4{{$}}
// CHECK-DAG: %[[eight:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 8{{$}}
// CHECK-DAG: %[[string0:[0-9a-zA-Z_]+]] = OpString "Argument: %f"
// CHECK-DAG: %[[string1:[0-9a-zA-Z_]+]] = OpString "Arguments: %c %hd %d %f %ld"
// CHECK-DAG: %[[arg_c:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uchar]]
// CHECK-DAG: %[[arg_s:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[ushort]]
// CHECK-DAG: %[[arg_f:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]]
// CHECK-DAG: %[[arg_i:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]]
// CHECK-DAG: %[[arg_l:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[ulong]]
// CHECK-DAG: %[[arg_f_double:[0-9a-zA-Z_]+]] = OpFConvert %[[double]] %[[arg_f]]

// Printf ID 0 is stored. Float argument is promoted to double, bitcast to an
// i64 and stored to the i32 printf buffer as a two component i32 vector
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[zero]]
// CHECK: %[[f_bitcast:[0-9a-zA-Z_]+]] = OpBitcast %[[v2uint]] %[[arg_f_double]]
// CHECK: %[[f_i32_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[f_bitcast]] 0
// CHECK: %[[f_i32_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[f_bitcast]] 1
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[f_i32_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[f_i32_1]]

// Printf ID 1 is stored. Char and short arguments are promoted to integer and stored.
// Int argument is stored as-is. Float argument is promoted to double and stored as 2x i32.
// Long argument is stored as 2x i32.
// CHECK-DAG: %[[arg_c_promoted:[0-9a-zA-Z_]+]] = OpSConvert %[[uint]] %[[arg_c]]
// CHECK-DAG: %[[arg_s_promoted:[0-9a-zA-Z_]+]] = OpSConvert %[[uint]] %[[arg_s]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[one]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_c_promoted]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_s_promoted]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_i]]
// CHECK: %[[arg_f_bitcast:[0-9a-zA-Z_]+]] = OpBitcast %[[v2uint]] %[[arg_f_double]]
// CHECK: %[[f_i32_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_f_bitcast]] 0
// CHECK: %[[f_i32_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_f_bitcast]] 1
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[f_i32_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[f_i32_1]]
// CHECK: %[[arg_l_bitcast:[0-9a-zA-Z_]+]] = OpBitcast %[[v2uint]] %[[arg_l]]
// CHECK: %[[l_i32_0:[0-9a-zA-Z_]+]] = OpUConvert %[[uint]] %[[arg_l]]
// CHECK: %[[l_i32_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_bitcast]] 1
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[l_i32_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[l_i32_1]]

// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[zero]] %[[string0]] %[[eight]]
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[one]] %[[string1]] %[[four]] %[[four]] %[[four]] %[[eight]] %[[eight]]
