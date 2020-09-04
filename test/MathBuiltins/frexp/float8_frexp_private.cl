// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that fract for float8 is supported.

// CHECK: [[GLSL:%[^ ]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK-DAG: [[FLOAT:%[^ ]+]]         = OpTypeFloat 32
// CHECK-DAG: [[RUNTIME_FLOAT:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT]]
// CHECK-DAG: [[STRUCT_FLOAT:%[^ ]+]]  = OpTypeStruct [[RUNTIME_FLOAT]]
// CHECK-DAG: [[BUFFER_FLOAT:%[^ ]+]]  = OpTypePointer StorageBuffer [[STRUCT_FLOAT]]
// CHECK-DAG: [[PTR_FLOAT:%[^ ]+]]     = OpTypePointer StorageBuffer [[FLOAT]]

// CHECK-DAG: [[INT:%[^ ]+]]           = OpTypeInt 32
// CHECK-DAG: [[RUNTIME_INT:%[^ ]+]]   = OpTypeRuntimeArray [[INT]]
// CHECK-DAG: [[STRUCT_INT:%[^ ]+]]    = OpTypeStruct [[RUNTIME_INT]]
// CHECK-DAG: [[BUFFER_INT:%[^ ]+]]    = OpTypePointer StorageBuffer [[STRUCT_INT]]
// CHECK-DAG: [[PTR_INT:%[^ ]+]]       = OpTypePointer StorageBuffer [[INT]]
// CHECK-DAG: [[LOCAL_PTR_INT:%[^ ]+]] = OpTypePointer Function [[INT]]
//
// CHECK-DAG: [[INT8:%[^ ]+]] = OpTypeStruct [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]]
// CHECK-DAG: [[LOCAL_PTR_INT8:%[^ ]+]] = OpTypePointer Function [[INT8]]
//
// CHECK-DAG: [[CST_0:%[^ ]+]] = OpConstant [[INT]] 0
// CHECK-DAG: [[CST_1:%[^ ]+]] = OpConstant [[INT]] 1
// CHECK-DAG: [[CST_2:%[^ ]+]] = OpConstant [[INT]] 2
// CHECK-DAG: [[CST_3:%[^ ]+]] = OpConstant [[INT]] 3
// CHECK-DAG: [[CST_4:%[^ ]+]] = OpConstant [[INT]] 4
// CHECK-DAG: [[CST_5:%[^ ]+]] = OpConstant [[INT]] 5
// CHECK-DAG: [[CST_6:%[^ ]+]] = OpConstant [[INT]] 6
// CHECK-DAG: [[CST_7:%[^ ]+]] = OpConstant [[INT]] 7
//
// CHECK-DAG: [[INOUT:%[^ ]+]] = OpVariable [[BUFFER_FLOAT]] StorageBuffer
// CHECK-DAG: [[OUT:%[^ ]+]]   = OpVariable [[BUFFER_INT]] StorageBuffer
// CHECK-DAG: [[PTR_Z:%[^ ]+]] = OpVariable [[LOCAL_PTR_INT8]] Function
//
// CHECK-DAG: [[PTR_XY_0:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[PTR_XY_1:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[PTR_XY_2:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_2]]
// CHECK-DAG: [[PTR_XY_3:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_3]]
// CHECK-DAG: [[PTR_XY_4:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_4]]
// CHECK-DAG: [[PTR_XY_5:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_5]]
// CHECK-DAG: [[PTR_XY_6:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_6]]
// CHECK-DAG: [[PTR_XY_7:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_7]]
//
// CHECK-DAG: [[PTR_Z_0:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_0]]
// CHECK-DAG: [[PTR_Z_1:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_1]]
// CHECK-DAG: [[PTR_Z_2:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_2]]
// CHECK-DAG: [[PTR_Z_3:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_3]]
// CHECK-DAG: [[PTR_Z_4:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_4]]
// CHECK-DAG: [[PTR_Z_5:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_5]]
// CHECK-DAG: [[PTR_Z_6:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_6]]
// CHECK-DAG: [[PTR_Z_7:%[^ ]+]] = OpAccessChain [[LOCAL_PTR_INT]] [[PTR_Z]] [[CST_7]]
//
// CHECK-DAG: [[X_0:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_0]]
// CHECK-DAG: [[X_1:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_1]]
// CHECK-DAG: [[X_2:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_2]]
// CHECK-DAG: [[X_3:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_3]]
// CHECK-DAG: [[X_4:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_4]]
// CHECK-DAG: [[X_5:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_5]]
// CHECK-DAG: [[X_6:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_6]]
// CHECK-DAG: [[X_7:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_XY_7]]
//
// CHECK-DAG: [[Y_0:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_0]] [[PTR_Z_0]]
// CHECK-DAG: [[Y_1:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_1]] [[PTR_Z_1]]
// CHECK-DAG: [[Y_2:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_2]] [[PTR_Z_2]]
// CHECK-DAG: [[Y_3:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_3]] [[PTR_Z_3]]
// CHECK-DAG: [[Y_4:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_4]] [[PTR_Z_4]]
// CHECK-DAG: [[Y_5:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_5]] [[PTR_Z_5]]
// CHECK-DAG: [[Y_6:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_6]] [[PTR_Z_6]]
// CHECK-DAG: [[Y_7:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_7]] [[PTR_Z_7]]
//
// CHECK-DAG: OpStore [[PTR_XY_0]] [[Y_0]]
// CHECK-DAG: OpStore [[PTR_XY_1]] [[Y_1]]
// CHECK-DAG: OpStore [[PTR_XY_2]] [[Y_2]]
// CHECK-DAG: OpStore [[PTR_XY_3]] [[Y_3]]
// CHECK-DAG: OpStore [[PTR_XY_4]] [[Y_4]]
// CHECK-DAG: OpStore [[PTR_XY_5]] [[Y_5]]
// CHECK-DAG: OpStore [[PTR_XY_6]] [[Y_6]]
// CHECK-DAG: OpStore [[PTR_XY_7]] [[Y_7]]
//
// Currently, writing z to memory is implemented as
//   for i in 0..7:
//     out[i] = (&z)[i];
// but it could be simplified to use, for example, one OpCopyMemory instruction
// if the pointer types of out and &z were the same.
//
// CHECK-DAG: [[Z_0:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_0]]
// CHECK-DAG: [[Z_1:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_1]]
// CHECK-DAG: [[Z_2:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_2]]
// CHECK-DAG: [[Z_3:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_3]]
// CHECK-DAG: [[Z_4:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_4]]
// CHECK-DAG: [[Z_5:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_5]]
// CHECK-DAG: [[Z_6:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_6]]
// CHECK-DAG: [[Z_7:%[^ ]+]] = OpLoad [[INT]] [[PTR_Z_7]]
//
// CHECK-DAG: [[PTR_OUT_0:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[PTR_OUT_1:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[PTR_OUT_2:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_2]]
// CHECK-DAG: [[PTR_OUT_3:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_3]]
// CHECK-DAG: [[PTR_OUT_4:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_4]]
// CHECK-DAG: [[PTR_OUT_5:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_5]]
// CHECK-DAG: [[PTR_OUT_6:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_6]]
// CHECK-DAG: [[PTR_OUT_7:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_7]]
//
// CHECK-DAG: OpStore [[PTR_OUT_0]] [[Z_0]]
// CHECK-DAG: OpStore [[PTR_OUT_1]] [[Z_1]]
// CHECK-DAG: OpStore [[PTR_OUT_2]] [[Z_2]]
// CHECK-DAG: OpStore [[PTR_OUT_3]] [[Z_3]]
// CHECK-DAG: OpStore [[PTR_OUT_4]] [[Z_4]]
// CHECK-DAG: OpStore [[PTR_OUT_5]] [[Z_5]]
// CHECK-DAG: OpStore [[PTR_OUT_6]] [[Z_6]]
// CHECK-DAG: OpStore [[PTR_OUT_7]] [[Z_7]]

void kernel test(global float *inout, global int *out) {
  // Because long vectors are not supported as kernel argument, we rely on
  // vload8 and vstore8 to read/write the values.
  float8 x = vload8(0, inout);
  int8 z;
  float8 y = frexp(x, &z);
  vstore8(y, 0, inout);
  vstore8(z, 0, out);
}
