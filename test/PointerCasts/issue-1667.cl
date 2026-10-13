// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

#define OPENCL_FORCE_INLINE __attribute__((always_inline))

typedef struct { float a[8]; float b[8]; } Matrix4x4;
typedef struct { Matrix4x4 m; } Transform;
typedef struct { float t; Transform start; } IT;

OPENCL_FORCE_INLINE void CopyFrom(__global const IT* restrict it, Matrix4x4 *result) {
    *result = it->start.m;
}

OPENCL_FORCE_INLINE void CopyTo(__global IT* restrict it, const Matrix4x4 *result) {
    it->start.m = *result;
}

__kernel void use_src(__global const IT* restrict src, __global float* out) {
    Matrix4x4 m;
    CopyFrom(src, &m);
    out[0] = m.a[0];
}

__kernel void use_dst(__global IT* restrict dst, __global float* in, int i) {
    Matrix4x4 m;
    m.a[i] = in[0];
    CopyTo(dst, &m);
}
