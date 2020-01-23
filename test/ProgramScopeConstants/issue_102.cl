// https://github.com/google/clspv/issues/102

// RUN: clspv -cl-std=CLC++ -inline-entry-points %s -o %t.spv
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
// CHECK:  [[_float:%[0-9a-zA-Z_]+]] = OpTypeFloat 32 0
// CHECK:  [[_uint:%[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK:  [[_uint_3:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 3
// CHECK:  [[__arr_float_uint_3:%[0-9a-zA-Z_]+]] = OpTypeArray [[_float]] [[_uint_3]]
// CHECK:  [[__ptr_Private__arr_float_uint_3:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr_float_uint_3]]
// CHECK:  [[_v4float:%[0-9a-zA-Z_]+]] = OpTypeVector [[_float]] 4
// CHECK:  [[__struct_20:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_v4float]] [[_float]] {{.*}}
// CHECK:  [[_uint_2:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[__arr__struct_20_uint_2:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_20]] [[_uint_2]]
// CHECK:  [[%_ptr_Private__arr__struct_20_uint_2:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr__struct_20_uint_2]]
// CHECK:  [[__struct_28:%[0-9a-zA-Z_]+]] = OpTypeStruct [[_v4float]] [[_float]]
// CHECK:  [[_uint_2_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 2
// CHECK:  [[__arr__struct_28_uint_2_0:%[0-9a-zA-Z_]+]] = OpTypeArray [[__struct_28]] [[_uint_2_0]]
// CHECK:  [[%_ptr_Private__arr__struct_28_uint_2_0:%[0-9a-zA-Z_]+]] = OpTypePointer Private [[__arr__struct_28_uint_2_0]]
// CHECK:  [[_uint_0:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 0
// CHECK:  [[_float_10_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 10.5
// CHECK:  [[_float_11_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 11.5
// CHECK:  [[_float_12_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 12.5
// CHECK:  [[_float_13_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 13.5
// CHECK:  [[_x:_%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_10_5]] [[_float_11_5]] [[_float_12_5]] [[_float_13_5]]
// CHECK:  [[_float_14_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 14.5
// CHECK:  [[_y:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__struct_28]] [[_x]] [[_float_14_5]]
// CHECK:  [[_float_20_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 20.5
// CHECK:  [[_float_21_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 21.5
// CHECK:  [[_float_22_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 22.5
// CHECK:  [[_float_23_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 23.5
// CHECK:  [[_z:%[0-9a-zA-Z_]+]] = OpConstantComposite [[_v4float]] [[_float_20_5]] [[_float_21_5]] [[_float_22_5]] [[_float_23_5]]
// CHECK:  [[_float_24_5:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 24.5
// CHECK:  [[_w:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__struct_28]] [[_z]] [[_float_24_5]]
// CHECK:  [[_t%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr__struct_28_uint_2_0]] [[_y]] [[_w]]
// CHECK:  [[_uint_1:%[0-9a-zA-Z_]+]] = OpConstant [[_uint]] 1
// CHECK:  [[_float_1:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 1
// CHECK:  [[_float_2:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 2
// CHECK:  [[_float_3:%[0-9a-zA-Z_]+]] = OpConstant [[_float]] 3
// CHECK:  [[_u:%[0-9a-zA-Z_]+]] = OpConstantComposite [[__arr_float_uint_3]] [[_float_1]] [[_float_2]] [[_float_3]]
// CHECK:  [[_pu:%[0-9a-zA-Z_]+]] = OpVariable [[_ptr_Private__arr_float_uint_3]] Private [[_u]]
// CHECK:  [[_pt:%[0-9a-zA-Z_]+]] = OpVariable [[_ptr_Private__arr__struct_28_uint_2_0]] Private [[_t]]
// CHECK:  [[_pf:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_pu]]
// CHECK:  [[_f:%[0-9a-zA-Z_]+]] = OpLoad [[_float]] [[_pf]]
// CHECK:  [[_bc:%[0-9a-zA-Z_]+]] = OpBitcast [[_ptr_private__arr__struct_20_uint_2]] [[_pt]]
// CHECK:  [[_pv:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_bc]]
// CHECK:  [[_v:%[0-9a-zA-Z_]+]] = OpLoad [[_v4float]] [[_pv]]
