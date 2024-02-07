// RUN: clspv %s -o %t.spv -cl-std=CL2.0 -inline-entry-points -cl-single-precision-constant -cl-kernel-arg-info -rounding-mode-rte=16,32 -fp64=0 -rewrite-packed-structs -std430-ubo-layout -decorate-nonuniform -hack-mul-extended -hack-convert-to-float -hack-image1d-buffer-bgra -arch=spir --use-native-builtins=ceil,copysign,exp2,floor,fma,fmax,fmin,half_exp,half_exp10,half_exp2,half_log,half_log10,half_log2,half_powr,half_rsqrt,half_sqrt,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,mad,rint,round,rsqrt,signbit,sqrt,trunc, -spv-version=1.6 -max-pushconstant-size=128 -max-ubo-size=1073741824 -global-offset -long-vector -module-constants-in-storage-buffer -cl-arm-non-uniform-work-group-size -enable-printf -printf-buffer-size=1048576
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6

__constant sampler_t smp_none = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;
__constant sampler_t smp_zero = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST;
#define FLT16_0123(V) V.s0123
#define FLT16_4567(V) V.s4567
#define FLT16_89ab(V) V.s89ab
#define FLT16_cdef(V) V.scdef
#define GLOBAL_ID_0 get_global_id(0)
#define GLOBAL_ID_1 get_global_id(1)
#define GLOBAL_ID_2 get_global_id(2)
#define LOCAL_ID_0 get_local_id(0)
#define LOCAL_ID_1 get_local_id(1)
#define LOCAL_ID_2 get_local_id(2)
#define GROUP_ID_0 get_group_id(0)
#define GROUP_ID_1 get_group_id(1)
#define GROUP_ID_2 get_group_id(2)
#define GROUP_SIZE_0 get_local_size(0)
#define GROUP_SIZE_1 get_local_size(1)
#define GROUP_SIZE_2 get_local_size(2)
#define SUB_GROUP_LOCAL_ID get_sub_group_local_id()
#define SUB_GROUP_BROADCAST(V, ID) sub_group_broadcast(V, ID)
#define SIMD_LOCAL_MEM_BARRIER barrier(CLK_LOCAL_MEM_FENCE)
#define LOCAL_MEM_BARRIER barrier(CLK_LOCAL_MEM_FENCE)
#define MAIN_FUNCTION __kernel void main_function
#define INIT_FLOAT(value) (float)(value)
#define INIT_FLOAT2(value) (float2)(value)
#define INIT_FLOAT2v2(v0, v1) (float2)(v0, v1)
#define INIT_FLOAT3(value) (float3)(value)
#define INIT_FLOAT3v3(v0, v1, v2) (float3)(v0, v1, v2)
#define INIT_FLOAT4(value) (float4)(value)
#define INIT_FLOAT4v4(v0, v1, v2, v3) (float4)(v0, v1, v2, v3)
#define INIT_INT(value) (int)(value)
#define INIT_INT2v2(v0, v1) (int2)(v0, v1)
#define INIT_INT4v4(v0, v1, v2, v3) (int4)(v0, v1, v2, v3)
#define CONVERT_TO_INT4(value) convert_int4(value)
#pragma OPENCL EXTENSION cl_khr_3d_image_writes : enable
#pragma OPENCL EXTENSION cl_khr_fp16 : enable
#define ACCUM_FLT4 half4
#define INIT_ACCUM_FLT4(value) (half4)(value)
#define FLT half
#define FLT2 half2
#define FLT3 half3
#define FLT4 half4
#define TO_FLT4 convert_half4
#define TO_ACCUM_TYPE convert_half4
#define TO_ACCUM_FLT convert_half
#define TO_ACCUM_FLT2 convert_half2
#define TO_ACCUM_FLT3 convert_half3
#define TO_ACCUM_FLT4 convert_half4
#define INIT_FLT(value) (half)(value)
#define INIT_FLT4(value) (half4)(value)
#define INIT_FLT4v4(v0, v1, v2, v3) (half4)(v0, v1, v2, v3)
#define bool2 uchar2
#define bool3 uchar3
#define bool4 uchar4
__attribute__((reqd_work_group_size(16, 1, 1))) __attribute__((intel_reqd_sub_group_size(16))) MAIN_FUNCTION(
    __global half4 *biases_buffer, __global half4 *dst_tensor_buffer, __global half4 *src_tensor_buffer,
    __global half4 *weights_buffer, int4 shared_int4_0, int4 shared_int4_1, int4 shared_int4_2, int4 shared_int4_3,
    int4 shared_int4_4, half4 shared_half4_0)
{
    int linear_spatial = GLOBAL_ID_0;
    int DST_X = linear_spatial % shared_int4_3.w;
    linear_spatial = linear_spatial / shared_int4_3.w;
    int DST_Y = linear_spatial % shared_int4_4.x;
    linear_spatial = linear_spatial / shared_int4_4.x;
    int DST_S = GLOBAL_ID_1;
    DST_S *= 4;
    if (DST_S >= shared_int4_0.w)
        return;
    int simd_id = SUB_GROUP_LOCAL_ID;
    ACCUM_FLT4 r_w0_h0_s0 = INIT_ACCUM_FLT4(0.0f);
    ACCUM_FLT4 r_w0_h0_s1 = INIT_ACCUM_FLT4(0.0f);
    ACCUM_FLT4 r_w0_h0_s2 = INIT_ACCUM_FLT4(0.0f);
    ACCUM_FLT4 r_w0_h0_s3 = INIT_ACCUM_FLT4(0.0f);
    int xc0 = (DST_X + 0) * shared_int4_3.y + shared_int4_1.w;
    int yc0 = (DST_Y + 0) * shared_int4_3.z + shared_int4_2.x;
    __global half4 *weights_cache;
    __global half4 *filters_loc = weights_buffer + DST_S * 4 * shared_int4_2.w * shared_int4_1.y * shared_int4_1.z;
    for (int ky = 0; ky < shared_int4_1.z; ++ky) {
        int yck0 = ky * shared_int4_0.y + yc0;
        bool in_y0 = yck0 >= 0 && yck0 < shared_int4_2.y;
        yck0 = clamp(yck0, 0, shared_int4_2.y - 1);
        for (int kx = 0; kx < shared_int4_1.y; ++kx) {
            int xck0 = kx * shared_int4_0.x + xc0;
            bool in_x0 = xck0 >= 0 && xck0 < shared_int4_3.x;
            xck0 = clamp(xck0, 0, shared_int4_3.x - 1);
            int addr_w0_h0 = (((0) * shared_int4_2.y + (yck0)) * shared_int4_3.x + (xck0));
            int ds = shared_int4_2.z;
            int s = 0;
            do {
                half4 src_w0_h0;
                FLT4 simd_w0 = filters_loc[simd_id + 0];
                FLT4 simd_w1 = filters_loc[simd_id + 16];
                src_w0_h0 = src_tensor_buffer[addr_w0_h0] * INIT_FLT(in_x0 && in_y0);
                addr_w0_h0 += ds;
                s += 1;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w0.x, 0u) * src_w0_h0.x;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w0.y, 0u) * src_w0_h0.x;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w0.z, 0u) * src_w0_h0.x;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w0.w, 0u) * src_w0_h0.x;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w0.x, 1u) * src_w0_h0.y;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w0.y, 1u) * src_w0_h0.y;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w0.z, 1u) * src_w0_h0.y;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w0.w, 1u) * src_w0_h0.y;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w0.x, 2u) * src_w0_h0.z;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w0.y, 2u) * src_w0_h0.z;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w0.z, 2u) * src_w0_h0.z;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w0.w, 2u) * src_w0_h0.z;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w0.x, 3u) * src_w0_h0.w;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w0.y, 3u) * src_w0_h0.w;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w0.z, 3u) * src_w0_h0.w;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w0.w, 3u) * src_w0_h0.w;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w0.x, 4u) * src_w0_h0.x;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w0.y, 4u) * src_w0_h0.x;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w0.z, 4u) * src_w0_h0.x;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w0.w, 4u) * src_w0_h0.x;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w0.x, 5u) * src_w0_h0.y;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w0.y, 5u) * src_w0_h0.y;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w0.z, 5u) * src_w0_h0.y;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w0.w, 5u) * src_w0_h0.y;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w0.x, 6u) * src_w0_h0.z;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w0.y, 6u) * src_w0_h0.z;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w0.z, 6u) * src_w0_h0.z;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w0.w, 6u) * src_w0_h0.z;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w0.x, 7u) * src_w0_h0.w;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w0.y, 7u) * src_w0_h0.w;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w0.z, 7u) * src_w0_h0.w;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w0.w, 7u) * src_w0_h0.w;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w0.x, 8u) * src_w0_h0.x;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w0.y, 8u) * src_w0_h0.x;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w0.z, 8u) * src_w0_h0.x;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w0.w, 8u) * src_w0_h0.x;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w0.x, 9u) * src_w0_h0.y;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w0.y, 9u) * src_w0_h0.y;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w0.z, 9u) * src_w0_h0.y;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w0.w, 9u) * src_w0_h0.y;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w0.x, 10u) * src_w0_h0.z;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w0.y, 10u) * src_w0_h0.z;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w0.z, 10u) * src_w0_h0.z;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w0.w, 10u) * src_w0_h0.z;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w0.x, 11u) * src_w0_h0.w;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w0.y, 11u) * src_w0_h0.w;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w0.z, 11u) * src_w0_h0.w;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w0.w, 11u) * src_w0_h0.w;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w0.x, 12u) * src_w0_h0.x;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w0.y, 12u) * src_w0_h0.x;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w0.z, 12u) * src_w0_h0.x;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w0.w, 12u) * src_w0_h0.x;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w0.x, 13u) * src_w0_h0.y;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w0.y, 13u) * src_w0_h0.y;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w0.z, 13u) * src_w0_h0.y;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w0.w, 13u) * src_w0_h0.y;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w0.x, 14u) * src_w0_h0.z;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w0.y, 14u) * src_w0_h0.z;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w0.z, 14u) * src_w0_h0.z;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w0.w, 14u) * src_w0_h0.z;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w0.x, 15u) * src_w0_h0.w;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w0.y, 15u) * src_w0_h0.w;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w0.z, 15u) * src_w0_h0.w;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w0.w, 15u) * src_w0_h0.w;
                src_w0_h0 = src_tensor_buffer[addr_w0_h0] * INIT_FLT(in_x0 && in_y0);
                addr_w0_h0 += ds;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w1.x, 0u) * src_w0_h0.x;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w1.y, 0u) * src_w0_h0.x;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w1.z, 0u) * src_w0_h0.x;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w1.w, 0u) * src_w0_h0.x;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w1.x, 1u) * src_w0_h0.y;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w1.y, 1u) * src_w0_h0.y;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w1.z, 1u) * src_w0_h0.y;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w1.w, 1u) * src_w0_h0.y;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w1.x, 2u) * src_w0_h0.z;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w1.y, 2u) * src_w0_h0.z;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w1.z, 2u) * src_w0_h0.z;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w1.w, 2u) * src_w0_h0.z;
                r_w0_h0_s0.x += SUB_GROUP_BROADCAST(simd_w1.x, 3u) * src_w0_h0.w;
                r_w0_h0_s0.y += SUB_GROUP_BROADCAST(simd_w1.y, 3u) * src_w0_h0.w;
                r_w0_h0_s0.z += SUB_GROUP_BROADCAST(simd_w1.z, 3u) * src_w0_h0.w;
                r_w0_h0_s0.w += SUB_GROUP_BROADCAST(simd_w1.w, 3u) * src_w0_h0.w;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w1.x, 4u) * src_w0_h0.x;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w1.y, 4u) * src_w0_h0.x;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w1.z, 4u) * src_w0_h0.x;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w1.w, 4u) * src_w0_h0.x;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w1.x, 5u) * src_w0_h0.y;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w1.y, 5u) * src_w0_h0.y;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w1.z, 5u) * src_w0_h0.y;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w1.w, 5u) * src_w0_h0.y;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w1.x, 6u) * src_w0_h0.z;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w1.y, 6u) * src_w0_h0.z;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w1.z, 6u) * src_w0_h0.z;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w1.w, 6u) * src_w0_h0.z;
                r_w0_h0_s1.x += SUB_GROUP_BROADCAST(simd_w1.x, 7u) * src_w0_h0.w;
                r_w0_h0_s1.y += SUB_GROUP_BROADCAST(simd_w1.y, 7u) * src_w0_h0.w;
                r_w0_h0_s1.z += SUB_GROUP_BROADCAST(simd_w1.z, 7u) * src_w0_h0.w;
                r_w0_h0_s1.w += SUB_GROUP_BROADCAST(simd_w1.w, 7u) * src_w0_h0.w;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w1.x, 8u) * src_w0_h0.x;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w1.y, 8u) * src_w0_h0.x;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w1.z, 8u) * src_w0_h0.x;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w1.w, 8u) * src_w0_h0.x;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w1.x, 9u) * src_w0_h0.y;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w1.y, 9u) * src_w0_h0.y;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w1.z, 9u) * src_w0_h0.y;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w1.w, 9u) * src_w0_h0.y;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w1.x, 10u) * src_w0_h0.z;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w1.y, 10u) * src_w0_h0.z;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w1.z, 10u) * src_w0_h0.z;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w1.w, 10u) * src_w0_h0.z;
                r_w0_h0_s2.x += SUB_GROUP_BROADCAST(simd_w1.x, 11u) * src_w0_h0.w;
                r_w0_h0_s2.y += SUB_GROUP_BROADCAST(simd_w1.y, 11u) * src_w0_h0.w;
                r_w0_h0_s2.z += SUB_GROUP_BROADCAST(simd_w1.z, 11u) * src_w0_h0.w;
                r_w0_h0_s2.w += SUB_GROUP_BROADCAST(simd_w1.w, 11u) * src_w0_h0.w;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w1.x, 12u) * src_w0_h0.x;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w1.y, 12u) * src_w0_h0.x;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w1.z, 12u) * src_w0_h0.x;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w1.w, 12u) * src_w0_h0.x;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w1.x, 13u) * src_w0_h0.y;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w1.y, 13u) * src_w0_h0.y;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w1.z, 13u) * src_w0_h0.y;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w1.w, 13u) * src_w0_h0.y;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w1.x, 14u) * src_w0_h0.z;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w1.y, 14u) * src_w0_h0.z;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w1.z, 14u) * src_w0_h0.z;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w1.w, 14u) * src_w0_h0.z;
                r_w0_h0_s3.x += SUB_GROUP_BROADCAST(simd_w1.x, 15u) * src_w0_h0.w;
                r_w0_h0_s3.y += SUB_GROUP_BROADCAST(simd_w1.y, 15u) * src_w0_h0.w;
                r_w0_h0_s3.z += SUB_GROUP_BROADCAST(simd_w1.z, 15u) * src_w0_h0.w;
                r_w0_h0_s3.w += SUB_GROUP_BROADCAST(simd_w1.w, 15u) * src_w0_h0.w;
                s += 1;
                filters_loc += 32;
            } while (s < shared_int4_2.w);
        };
    };
    weights_cache = biases_buffer + DST_S;
    if (DST_Y >= shared_int4_0.z || DST_S >= shared_int4_0.w) {
        return;
    }
    if (DST_S + 0 >= shared_int4_0.w)
        return;
    {
        FLT4 bias_val = TO_FLT4(weights_cache[0]);
        {
            FLT4 res = TO_FLT4(r_w0_h0_s0) + bias_val;
            {

                half4 res_final;
                {
                    {
                        res_final = max(res, INIT_FLT4(shared_half4_0.x));
                    }
                }
                dst_tensor_buffer[(((DST_S + 0) * shared_int4_0.z + (DST_Y + 0)) * shared_int4_1.x + (DST_X + 0))]
                    = res_final;
            };
        }
    }
    if (DST_S + 1 >= shared_int4_0.w)
        return;
    {
        FLT4 bias_val = TO_FLT4(weights_cache[1]);
        {
            FLT4 res = TO_FLT4(r_w0_h0_s1) + bias_val;
            {

                half4 res_final;
                {
                    {
                        res_final = max(res, INIT_FLT4(shared_half4_0.x));
                    }
                }
                dst_tensor_buffer[(((DST_S + 1) * shared_int4_0.z + (DST_Y + 0)) * shared_int4_1.x + (DST_X + 0))]
                    = res_final;
            };
        }
    }
    if (DST_S + 2 >= shared_int4_0.w)
        return;
    {
        FLT4 bias_val = TO_FLT4(weights_cache[2]);
        {
            FLT4 res = TO_FLT4(r_w0_h0_s2) + bias_val;
            {

                half4 res_final;
                {
                    {
                        res_final = max(res, INIT_FLT4(shared_half4_0.x));
                    }
                }
                dst_tensor_buffer[(((DST_S + 2) * shared_int4_0.z + (DST_Y + 0)) * shared_int4_1.x + (DST_X + 0))]
                    = res_final;
            };
        }
    }
    if (DST_S + 3 >= shared_int4_0.w)
        return;
    {
        FLT4 bias_val = TO_FLT4(weights_cache[3]);
        {
            FLT4 res = TO_FLT4(r_w0_h0_s3) + bias_val;
            {

                half4 res_final;
                {
                    {
                        res_final = max(res, INIT_FLT4(shared_half4_0.x));
                    }
                }
                dst_tensor_buffer[(((DST_S + 3) * shared_int4_0.z + (DST_Y + 0)) * shared_int4_1.x + (DST_X + 0))]
                    = res_final;
            };
        }
    }
}
