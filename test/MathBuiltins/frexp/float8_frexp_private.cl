// RUN: clspv --long-vector %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Check that fract for float8 is supported.

// CHECK: [[GLSL:%[^ ]+]] = OpExtInstImport "GLSL.std.450"
//
// CHECK-DAG: [[FLOAT:%[^ ]+]] = OpTypeFloat 32
// CHECK-DAG: [[PTR_FLOAT:%[^ ]+]] = OpTypePointer StorageBuffer [[FLOAT]]
//
// CHECK-DAG: [[FLOAT8:%[^ ]+]] = OpTypeStruct [[FLOAT]] [[FLOAT]] [[FLOAT]] [[FLOAT]] [[FLOAT]] [[FLOAT]] [[FLOAT]] [[FLOAT]]
// CHECK-DAG: [[RUNTIME_FLOAT8:%[^ ]+]] = OpTypeRuntimeArray [[FLOAT8]]
// CHECK-DAG: [[WRAPPER_FLOAT8:%[^ ]+]] = OpTypeStruct [[RUNTIME_FLOAT8]]
// CHECK-DAG: [[PTR_WRAPPER_FLOAT8:%[^ ]+]] = OpTypePointer StorageBuffer [[WRAPPER_FLOAT8]]
//
// CHECK-DAG: [[INT:%[^ ]+]] = OpTypeInt 32
// CHECK-DAG: [[PTR_INT:%[^ ]+]] = OpTypePointer StorageBuffer [[INT]]
//
// CHECK-DAG: [[INT8:%[^ ]+]] = OpTypeStruct [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]] [[INT]]
// CHECK-DAG: [[RUNTIME_INT8:%[^ ]+]] = OpTypeRuntimeArray [[INT8]]
// CHECK-DAG: [[WRAPPER_INT8:%[^ ]+]] = OpTypeStruct [[RUNTIME_INT8]]
// CHECK-DAG: [[PTR_WRAPPER_INT8:%[^ ]+]] = OpTypePointer StorageBuffer [[WRAPPER_INT8]]
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
// CHECK-DAG: [[INOUT:%[^ ]+]] = OpVariable [[PTR_WRAPPER_FLOAT8]] StorageBuffer
// CHECK-DAG: [[OUT:%[^ ]+]] = OpVariable [[PTR_WRAPPER_INT8]] StorageBuffer
//
// CHECK-DAG: [[PTR_INTOUT_0:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[PTR_INTOUT_1:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[PTR_INTOUT_2:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_2]]
// CHECK-DAG: [[PTR_INTOUT_3:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_3]]
// CHECK-DAG: [[PTR_INTOUT_4:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_4]]
// CHECK-DAG: [[PTR_INTOUT_5:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_5]]
// CHECK-DAG: [[PTR_INTOUT_6:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_6]]
// CHECK-DAG: [[PTR_INTOUT_7:%[^ ]+]] = OpAccessChain [[PTR_FLOAT]] [[INOUT]] [[CST_0]] [[CST_0]] [[CST_7]]
//
// CHECK-DAG: [[PTR_OUT_0:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_0]]
// CHECK-DAG: [[PTR_OUT_1:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_1]]
// CHECK-DAG: [[PTR_OUT_2:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_2]]
// CHECK-DAG: [[PTR_OUT_3:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_3]]
// CHECK-DAG: [[PTR_OUT_4:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_4]]
// CHECK-DAG: [[PTR_OUT_5:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_5]]
// CHECK-DAG: [[PTR_OUT_6:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_6]]
// CHECK-DAG: [[PTR_OUT_7:%[^ ]+]] = OpAccessChain [[PTR_INT]] [[OUT]] [[CST_0]] [[CST_0]] [[CST_7]]
//
// CHECK-DAG: [[X_0:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_0]]
// CHECK-DAG: [[X_1:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_1]]
// CHECK-DAG: [[X_2:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_2]]
// CHECK-DAG: [[X_3:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_3]]
// CHECK-DAG: [[X_4:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_4]]
// CHECK-DAG: [[X_5:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_5]]
// CHECK-DAG: [[X_6:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_6]]
// CHECK-DAG: [[X_7:%[^ ]+]] = OpLoad [[FLOAT]] [[PTR_INTOUT_7]]
//
// CHECK-DAG: [[Y_0:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_0]] [[PTR_OUT_0]]
// CHECK-DAG: [[Y_1:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_1]] [[PTR_OUT_1]]
// CHECK-DAG: [[Y_2:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_2]] [[PTR_OUT_2]]
// CHECK-DAG: [[Y_3:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_3]] [[PTR_OUT_3]]
// CHECK-DAG: [[Y_4:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_4]] [[PTR_OUT_4]]
// CHECK-DAG: [[Y_5:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_5]] [[PTR_OUT_5]]
// CHECK-DAG: [[Y_6:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_6]] [[PTR_OUT_6]]
// CHECK-DAG: [[Y_7:%[^ ]+]] = OpExtInst [[FLOAT]] [[GLSL]] Frexp [[X_7]] [[PTR_OUT_7]]
//
// CHECK-DAG: OpStore [[PTR_INTOUT_0]] [[Y_0]]
// CHECK-DAG: OpStore [[PTR_INTOUT_1]] [[Y_1]]
// CHECK-DAG: OpStore [[PTR_INTOUT_2]] [[Y_2]]
// CHECK-DAG: OpStore [[PTR_INTOUT_3]] [[Y_3]]
// CHECK-DAG: OpStore [[PTR_INTOUT_4]] [[Y_4]]
// CHECK-DAG: OpStore [[PTR_INTOUT_5]] [[Y_5]]
// CHECK-DAG: OpStore [[PTR_INTOUT_6]] [[Y_6]]
// CHECK-DAG: OpStore [[PTR_INTOUT_7]] [[Y_7]]

void kernel test(global float8 *inout, global int8 *out) {
  float8 x = *inout;
  float8 y = frexp(x, out);
  *inout = y;
}
