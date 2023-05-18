// RUN: clspv -cl-std=CL2.0 -inline-entry-points -cl-single-precision-constant  -cl-kernel-arg-info   -fp16=0  -rewrite-packed-structs  -std430-ubo-layout  -decorate-nonuniform    -arch=spir64  -physical-storage-buffers  --use-native-builtins=acos,acosh,acospi,asin,asinh,asinpi,atan,atan2,atan2pi,atanh,atanpi,ceil,copysign,fabs,fdim,floor,fma,fmax,fmin,frexp,half_rsqrt,half_sqrt,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,ldexp,mad,rint,round,rsqrt,signbit,sqrt,tanh,trunc,  -spv-version=1.6  -max-pushconstant-size=256  -max-ubo-size=65536  -global-offset  -long-vector  -module-constants-in-storage-buffer  -cl-arm-non-uniform-work-group-size %s -o %t.spv
// RUN: spirv-val --target-env spv1.6 %t.spv

kernel void foo(global uintptr_t *dst, const global uintptr_t *src)
{
    const int gid = get_global_id(0);
    const uchar *s = (uchar *)(src[gid]);
    uchar *d = (uchar *)(dst[gid]);
    *d = *s;
}
