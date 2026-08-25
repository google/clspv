// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

struct S16 { float4 v; };

__kernel void kern(__global struct S16 *in, __global long *out) {
    size_t lid = get_local_id(0);
    size_t gid = get_group_id(0);
    __global struct S16 *s1 = in + lid;
    __global uchar *s2 = (__global uchar *)s1 + gid;
    long v = *(__global long *)s2;
    out[lid] = v;
}
