// RUN: clspv %target %s -o %t.spv -inline-entry-points -cl-std=CL3.0 -no-8bit-storage=pushconstant -no-16bit-storage=pushconstant
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void test_kernel(char2 c, uchar2 uc, short2 s, int2 i, __global float2 *result)
{
    result[0] = convert_float2(c);
    result[1] = convert_float2(uc);
    result[2] = convert_float2(s);
    result[3] = convert_float2(i);
}

// CHECK-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK-DAG: [[ushort:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
// CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
// CHECK-DAG: [[int_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
// CHECK-DAG: [[int_1:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 1
// CHECK-DAG: [[int_2:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 2
// CHECK-DAG: [[int_3:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 3
// CHECK-DAG: [[int_4:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 4
// CHECK-DAG: [[v4uchar:%[a-zA-Z0-9_]+]] = OpTypeVector [[uchar]] 4
// CHECK-DAG: [[v2uchar:%[a-zA-Z0-9_]+]] = OpTypeVector [[uchar]] 2
// CHECK-DAG: [[v2ushort:%[a-zA-Z0-9_]+]] = OpTypeVector [[ushort]] 2
// CHECK-DAG: [[v2int:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 2
// CHECK-DAG: [[v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
// CHECK-DAG: [[undef_var:%[a-zA-Z0-9_]+]] = OpUndef [[v4uchar]]
// CHECK-DAG: [[struct_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant {{.*}}
// CHECK-DAG: [[v2float_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[v2float]]
// CHECK-DAG: [[int_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer PushConstant [[uint]]
// CHECK-DAG: [[varLoad:%[a-zA-Z0-9_]+]] = OpVariable [[struct_ptr]] PushConstant
// CHECK-DAG: [[varStore:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} StorageBuffer

// CHECK: OpLabel
// CHECK-DAG: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[varLoad]] [[int_0]] [[int_0]]
// CHECK-DAG: [[char_int:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gep0]]
// CHECK-DAG: [[char4_var:%[a-zA-Z0-9_]+]] = OpBitcast [[v4uchar]] [[char_int]]

// CHECK-DAG: [[char2_var0:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[v2uchar]] [[char4_var]] [[undef_var]] 0 1
// CHECK-DAG: [[float2_var0:%[a-zA-Z0-9_]+]] = OpConvertSToF [[v2float]] [[char2_var0]]
// CHECK-DAG: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain [[v2float_ptr]] [[varStore]] [[int_0]] [[int_0]]
// CHECK-DAG: OpStore [[gep1]] [[float2_var0]]

// CHECK-DAG: [[char2_var1:%[a-zA-Z0-9_]+]] = OpVectorShuffle [[v2uchar]] [[char4_var]] [[undef_var]] 2 3
// CHECK-DAG: [[float2_var1:%[a-zA-Z0-9_]+]] = OpConvertUToF [[v2float]] [[char2_var1]]
// CHECK-DAG: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[v2float_ptr]] [[varStore]] [[int_0]] [[int_1]]
// CHECK-DAG: OpStore [[gep2]] [[float2_var1]]

// CHECK-DAG: [[gep3:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[varLoad]] [[int_0]] [[int_1]]
// CHECK-DAG: [[short_int:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gep3]]
// CHECK-DAG: [[short2_var0:%[a-zA-Z0-9_]+]] = OpBitcast [[v2ushort]] [[short_int]]
// CHECK-DAG: [[float2_var2:%[a-zA-Z0-9_]+]] = OpConvertSToF [[v2float]] [[short2_var0]]
// CHECK-DAG: [[gep4:%[a-zA-Z0-9_]+]] = OpAccessChain [[v2float_ptr]] [[varStore]] [[int_0]] [[int_2]]
// CHECK-DAG: OpStore [[gep4]] [[float2_var2]]

// CHECK-DAG: [[gep5:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[varLoad]] [[int_0]] [[int_2]]
// CHECK-DAG: [[int_var1:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gep5]]
// CHECK-DAG: [[gep6:%[a-zA-Z0-9_]+]] = OpAccessChain [[int_ptr]] [[varLoad]] [[int_0]] [[int_3]]
// CHECK-DAG: [[int_var2:%[a-zA-Z0-9_]+]] = OpLoad [[uint]] [[gep6]]
// CHECK-DAG: [[int2_var0:%[a-zA-Z0-9_]+]] = OpCompositeConstruct [[v2int]] [[int_var1]] [[int_var2]]
// CHECK-DAG: [[float2_var3:%[a-zA-Z0-9_]+]] = OpConvertSToF [[v2float]] [[int2_var0]]
// CHECK-DAG: [[gep7:%[a-zA-Z0-9_]+]] = OpAccessChain [[v2float_ptr]] [[varStore]] [[int_0]] [[int_3]]
// CHECK-DAG: OpStore [[gep7]] [[float2_var3]]
