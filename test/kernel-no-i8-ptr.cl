// RUN: clspv %s -o %t.spv -cl-single-precision-constant -cl-kernel-arg-info -rounding-mode-rte=16,32,64 -rewrite-packed-structs -std430-ubo-layout -decorate-nonuniform -hack-convert-to-float -arch=spir --use-native-builtins=ceil,copysign,exp2,fdim,floor,fmax,fmin,frexp,half_exp,half_exp10,half_exp2,half_log,half_log10,half_log2,half_powr,half_rsqrt,half_sqrt,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,ldexp,log,log10,log2,mad,rint,round,rsqrt,signbit,sqrt,trunc, -spv-version=1.6 -max-pushconstant-size=256 -max-ubo-size=4294967295 -global-offset -long-vector -module-constants-in-storage-buffer -cl-arm-non-uniform-work-group-size -enable-printf -printf-buffer-size=1048576
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6
// RUN: FileCheck %s < %t.spvasm

// We should not need char type. If we have it, it means that we missed an optimization
// CHECK-NOT: OpTypeInt 8 0

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
MAIN_FUNCTION(__constant half4 *biases_buffer, __global half4 *dst_tensor_buffer, __constant half4 *weights_buffer,
    __read_only image1d_buffer_t src_tensor_image_buffer, int4 shared_int4_0, int4 shared_int4_1, int4 shared_int4_2,
    int4 shared_int4_3, half4 shared_half4_0)
{
    int DST_X = GLOBAL_ID_0;
    int DST_Y = GLOBAL_ID_1;
    int DST_S = GLOBAL_ID_2;
    DST_X *= 2;
    DST_Y *= 2;
    DST_S *= 4;
    if (DST_S >= shared_int4_0.w)
        return;
    if (DST_X >= shared_int4_1.x || DST_Y >= shared_int4_0.z || DST_S >= shared_int4_0.w) {
        return;
    }
    ACCUM_FLT4 r_w0_h0_s0 = INIT_ACCUM_FLT4(0.0f);
    int xc0 = (DST_X + 0) * shared_int4_3.y + shared_int4_1.w;
    int xc1 = (DST_X + 1) * shared_int4_3.y + shared_int4_1.w;
    int yc0 = (DST_Y + 0) * shared_int4_3.z + shared_int4_2.x;
    int yc1 = (DST_Y + 1) * shared_int4_3.z + shared_int4_2.x;
    __constant half4 *weights_cache;
    __constant half4 *filters_loc = weights_buffer + DST_S * 4 * shared_int4_2.w * shared_int4_1.y * shared_int4_1.z;
    for (int ky = 0; ky < shared_int4_1.z; ++ky) {
        int yck0 = ky * shared_int4_0.y + yc0;
        bool in_y0 = yck0 >= 0 && yck0 < shared_int4_2.y;
        int yck1 = ky * shared_int4_0.y + yc1;
        bool in_y1 = yck1 >= 0 && yck1 < shared_int4_2.y;
        for (int kx = 0; kx < shared_int4_1.y; ++kx) {
            int xck0 = kx * shared_int4_0.x + xc0;
            bool in_x0 = xck0 >= 0 && xck0 < shared_int4_3.x;
            int xck1 = kx * shared_int4_0.x + xc1;
            bool in_x1 = xck1 >= 0 && xck1 < shared_int4_3.x;
            int addr_w0_h0 = (((0) * shared_int4_2.y + (yck0)) * shared_int4_3.x + (xck0));
            addr_w0_h0 = select(-1, addr_w0_h0, (in_x0 && in_y0));
            int ds_w0_h0 = select(0, shared_int4_2.z, (in_x0 && in_y0));
            int addr_w1_h0 = (((0) * shared_int4_2.y + (yck0)) * shared_int4_3.x + (xck1));
            addr_w1_h0 = select(-1, addr_w1_h0, (in_x1 && in_y0));
            int ds_w1_h0 = select(0, shared_int4_2.z, (in_x1 && in_y0));
            int addr_w0_h1 = (((0) * shared_int4_2.y + (yck1)) * shared_int4_3.x + (xck0));
            addr_w0_h1 = select(-1, addr_w0_h1, (in_x0 && in_y1));
            int ds_w0_h1 = select(0, shared_int4_2.z, (in_x0 && in_y1));
            int addr_w1_h1 = (((0) * shared_int4_2.y + (yck1)) * shared_int4_3.x + (xck1));
            addr_w1_h1 = select(-1, addr_w1_h1, (in_x1 && in_y1));
            int ds_w1_h1 = select(0, shared_int4_2.z, (in_x1 && in_y1));
            int s = 0;
            do {
                half4 src_w0_h0;
                half4 src_w1_h0;
                half4 src_w0_h1;
                half4 src_w1_h1;
                weights_cache = filters_loc;
                src_w0_h0 = read_imageh(src_tensor_image_buffer, addr_w0_h0);
                addr_w0_h0 += ds_w0_h0;
                src_w1_h0 = read_imageh(src_tensor_image_buffer, addr_w1_h0);
                addr_w1_h0 += ds_w1_h0;
                src_w0_h1 = read_imageh(src_tensor_image_buffer, addr_w0_h1);
                addr_w0_h1 += ds_w0_h1;
                src_w1_h1 = read_imageh(src_tensor_image_buffer, addr_w1_h1);
                addr_w1_h1 += ds_w1_h1;
                s += 1;
                r_w0_h0_s0 = fma(weights_cache[0], src_w0_h0.x, r_w0_h0_s0);
                r_w0_h0_s0 = fma(weights_cache[1], src_w0_h0.y, r_w0_h0_s0);
                r_w0_h0_s0 = fma(weights_cache[2], src_w0_h0.z, r_w0_h0_s0);
                r_w0_h0_s0 = fma(weights_cache[3], src_w0_h0.w, r_w0_h0_s0);
                filters_loc += 16;
            } while (s < shared_int4_2.w);
        };
    };
    weights_cache = biases_buffer + DST_S;
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
}
