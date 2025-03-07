// RUN: clspv %s -o %t.spv -enable-printf -long-vector -spv-version=1.4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.2 %t.spv

kernel void test(char2 c, short2 s, int2 i, float8 f, long4 l) {
    printf("Vectors: %v2hhd %v2hd %v2d %v8hlf %v4ld", c, s, i, f, l);
}

// CHECK: %[[ReflectionImport:[0-9a-zA-Z_]+]] = OpExtInstImport "NonSemantic.ClspvReflection.5"

// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64
// CHECK-DAG: %[[float:[0-9a-zA-Z_]+]] = OpTypeFloat 32
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[zero:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[one:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1{{$}}
// CHECK-DAG: %[[two:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2{{$}}
// CHECK-DAG: %[[four:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 4{{$}}
// CHECK-DAG: %[[eight:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 8{{$}}
// CHECK-DAG: %[[const_32:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 32{{$}}
// CHECK-DAG: %[[string0:[0-9a-zA-Z_]+]] = OpString "Vectors: %v2hhd %v2hd %v2d %v8hlf %v4ld"

// CHECK: OpCopyLogical
// CHECK-DAG: %[[arg_c:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[v2uchar]]
// CHECK-DAG: %[[arg_s:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[v2ushort]]
// CHECK-DAG: %[[arg_i:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[v2uint]]
// CHECK-DAG: %[[arg_l:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[v4ulong]]

// char2 is bitcast to i16, extended to i32, and stored
// CHECK: %[[arg_c_bitcast:[0-9a-zA-Z_]+]] = OpBitcast %[[ushort]] %[[arg_c]]
// CHECK: %[[arg_c_int:[0-9a-zA-Z_]+]] = OpUConvert %[[uint]] %[[arg_c_bitcast]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_c_int]]

// short2 is bitcast to i32 and stored
// CHECK: %[[arg_s_bitcast:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_s]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_s_bitcast]]

// int2 is stored as two ints
// CHECK: %[[arg_i_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_i]] 0
// CHECK: %[[arg_i_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_i]] 1
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_i_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_i_1]]

// CHECK-DAG: %[[arg_f_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 0
// CHECK-DAG: %[[arg_f_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 1
// CHECK-DAG: %[[arg_f_2:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 2
// CHECK-DAG: %[[arg_f_3:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 3
// CHECK-DAG: %[[arg_f_4:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 4
// CHECK-DAG: %[[arg_f_5:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 5
// CHECK-DAG: %[[arg_f_6:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 6
// CHECK-DAG: %[[arg_f_7:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[float]] %{{[0-9a-zA-Z_]+}} 7

// float8 is a long vector; each component is bitcast to i32 and stored
// CHECK: %[[arg_f0_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f0_int]]
// CHECK: %[[arg_f1_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_1]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f1_int]]
// CHECK: %[[arg_f2_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_2]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f2_int]]
// CHECK: %[[arg_f3_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_3]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f3_int]]
// CHECK: %[[arg_f4_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_4]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f4_int]]
// CHECK: %[[arg_f5_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_5]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f5_int]]
// CHECK: %[[arg_f6_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_6]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f6_int]]
// CHECK: %[[arg_f7_int:[0-9a-zA-Z_]+]] = OpBitcast %[[uint]] %[[arg_f_7]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_f7_int]]

// long4 is split into two long2 vectors which are bitcast to int4 vectors,
// and then each component is stored
// CHECK: %[[arg_l_a:[0-9a-zA-Z_]+]] = OpVectorShuffle %[[v2ulong]] %[[arg_l]] %{{[0-9a-zA-Z_]+}} 0 1
// CHECK: %[[arg_l_b:[0-9a-zA-Z_]+]] = OpVectorShuffle %[[v2ulong]] %[[arg_l]] %{{[0-9a-zA-Z_]+}} 2 3
// CHECK: %[[arg_l_a_v4uint:[0-9a-zA-Z_]+]] = OpBitcast %[[v4uint]] %[[arg_l_a]]
// CHECK: %[[arg_l_b_v4uint:[0-9a-zA-Z_]+]] = OpBitcast %[[v4uint]] %[[arg_l_b]]
// CHECK: %[[arg_l_a_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_a_v4uint]] 0
// CHECK: %[[arg_l_a_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_a_v4uint]] 1
// CHECK: %[[arg_l_a_2:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_a_v4uint]] 2
// CHECK: %[[arg_l_a_3:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_a_v4uint]] 3
// CHECK: %[[arg_l_b_0:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_b_v4uint]] 0
// CHECK: %[[arg_l_b_1:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_b_v4uint]] 1
// CHECK: %[[arg_l_b_2:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_b_v4uint]] 2
// CHECK: %[[arg_l_b_3:[0-9a-zA-Z_]+]] = OpCompositeExtract %[[uint]] %[[arg_l_b_v4uint]] 3
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_a_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_a_1]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_a_2]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_a_3]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_b_0]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_b_1]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_b_2]]
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[arg_l_b_3]]

// Printf ID 0 is stored.
// CHECK: OpStore %{{[0-9a-zA-Z_]+}} %[[zero]]

// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfBufferStorageBuffer %[[zero]] %[[zero]] %[[one]]
// CHECK: OpExtInst %void %[[ReflectionImport]] PrintfInfo %[[zero]] %[[string0]] %[[four]] %[[four]] %[[eight]] %[[const_32]] %[[const_32]]
