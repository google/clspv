// RUN: clspv %s -o %t.spv -constant-args-ubo -inline-entry-points  -cl-single-precision-constant  -cl-kernel-arg-info   -rounding-mode-rte=16,32,64  -rewrite-packed-structs  -std430-ubo-layout  -decorate-nonuniform  -hack-convert-to-float  -arch=spir64  -physical-storage-buffers  --use-native-builtins=ceil,copysign,fabs,fdim,floor,fmax,fmin,half_cos,half_exp,half_exp10,half_exp2,half_rsqrt,half_sin,half_sqrt,half_tan,isequal,isfinite,isgreater,isgreaterequal,isinf,isless,islessequal,islessgreater,isnan,isnormal,isnotequal,isordered,isunordered,mad,rint,round,rsqrt,signbit,sqrt,trunc,  -spv-version=1.6  -max-pushconstant-size=128  -max-ubo-size=65536  -global-offset  -long-vector  -module-constants-in-storage-buffer  -cl-arm-non-uniform-work-group-size   -enable-printf  -printf-buffer-size=1048576
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.6

kernel void test_simple(global uint4* out, constant uint4* c_data)
{
    size_t gid = get_global_id(0);
    out[gid] = (uint4)(gid,gid,gid,gid) + c_data[gid];
}
