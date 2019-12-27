// https://github.com/google/clspv/issues/102

// RUN: clspv -c++ -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: spirv-val --target-env vulkan1.0 %t.spv

namespace {
    constant uint scalar = 42;

    constant float arr[3] = { 1.0f, 2.0f, 3.0f };

    typedef struct {
    float4 u;
    float v;
    } S;

    constant S structval[2] = {
        {(float4)(10.5f, 11.5f, 12.5f, 13.5f), 14.5f},
        {(float4)(20.5f, 21.5f, 22.5f, 23.5f), 24.5f},
    };

    // Same data as arr.  Should reuse the same underlying space as arr
    constant float arr2[3] = { 1.0f, 2.0f, 3.0f };
}

void kernel foo(global float *A, uint n)
{
  *A = arr[n] + arr[3-n] + structval[n].u.y + structval[n].v;
}