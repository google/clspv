// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// This test used to involve an infinite loop

__kernel void test(__global int8 *output)
{ 
    int i = 0;
    __local int x[8];
    __local int8* xPtr;

    for (i = 0; i < 8; ++i)
    {
        x[i] = 8 - i;
    }
    
    xPtr = (__local int8 *)x;
    output[0].s0 = xPtr[0].s0;
    output[0].s1 = xPtr[0].s1;
    output[0].s2 = xPtr[0].s2;
    output[0].s3 = xPtr[0].s3;
    output[0].s4 = xPtr[0].s4;
    output[0].s5 = xPtr[0].s5;
    output[0].s6 = xPtr[0].s6;
    output[0].s7 = xPtr[0].s7;
}
