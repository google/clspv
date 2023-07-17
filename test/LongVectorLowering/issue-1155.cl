// RUN: clspv --cl-std=CLC++ --inline-entry-points --cl-native-math --long-vector %s -o %t.spv
// RUN: spirv-val --target-env spv1.0 %t.spv

__kernel void sqrtLongVecTest(__global float8* inout8,
                              __global float16* inout16)
{
  inout8[0] = sqrt(inout8[0]);
  inout16[0] = sqrt(inout16[0]);
}

__kernel void rsqrtLongVecTest(__global float8* inout8,
                               __global float16* inout16)
{
  inout8[0] = rsqrt(inout8[0]);
  inout16[0] = rsqrt(inout16[0]);
}

__kernel void atanLongVecTest(__global float8* inout8,
                              __global float16* inout16)
{
  inout8[0] = atan(inout8[0]);
  inout16[0] = atan(inout16[0]);
}

__kernel void atan2LongVecTest(__global float8* inout8,
                               __global float16* inout16)
{
  inout8[0] = atan2(inout8[0], inout8[1]);
  inout16[0] = atan2(inout16[0], inout16[1]);
}
