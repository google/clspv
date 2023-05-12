// RUN: clspv --cl-std=CLC++ --inline-entry-points %s -o %t.spv --long-vector --vec3-to-vec4
// RUN: spirv-val --target-env spv1.0 %t.spv

__kernel void vloadstoreHalfTest(__global half* inout, __local half* storage)
{
  const float k = 2.0f;
  // scalar
  {
    const float v1 = vload_half(0, inout);
    vstore_half(v1 * k, 0, storage);
    const float v2 = vload_half(0, storage);
    vstore_half(v2 * k, 0, inout);
  }
  // vector2
  {
    const float2 v1 = vload_half2(0, inout);
    vstore_half2(v1 * k, 0, storage);
    const float2 v2 = vload_half2(0, storage);
    vstore_half2(v2 * k, 0, inout);
  }
  // vector3
  {
    const float3 v1 = vload_half3(0, inout);
    vstore_half3(v1 * k, 0, storage);
    const float3 v2 = vload_half3(0, storage);
    vstore_half3(v2 * k, 0, inout);
  }
  // vector4
  {
    const float4 v1 = vload_half4(0, inout);
    vstore_half4(v1 * k, 0, storage);
    const float4 v2 = vload_half4(0, storage);
    vstore_half4(v2 * k, 0, inout);
  }
  // vector8
  {
    const float8 v1 = vload_half8(0, inout);
    vstore_half8(v1 * k, 0, storage);
    const float8 v2 = vload_half8(0, storage);
    vstore_half8(v2 * k, 0, inout);
  }
}
