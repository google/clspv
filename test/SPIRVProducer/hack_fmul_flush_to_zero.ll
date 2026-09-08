; RUN: clspv-opt %s -o %t.hack.ll --passes=spirv-producer -producer-out-file %t.hack.spv -hack-fmul-flush-to-zero=32
; RUN: spirv-dis %t.hack.spv -o %t.hack.spvasm
; RUN: FileCheck %s --check-prefix=CHECK-HACK < %t.hack.spvasm
; RUN: spirv-val %t.hack.spv

; RUN: clspv-opt %s -o %t.nohack.ll --passes=spirv-producer -producer-out-file %t.nohack.spv
; RUN: spirv-dis %t.nohack.spv -o %t.nohack.spvasm
; RUN: FileCheck %s --check-prefix=CHECK-NOHACK < %t.nohack.spvasm
; RUN: spirv-val %t.nohack.spv

; CHECK-HACK-DAG: [[int:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-HACK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-HACK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-HACK-DAG: [[array:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[float]]
; CHECK-HACK-DAG: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[array]]
; CHECK-HACK-DAG: [[block_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
; CHECK-HACK-DAG: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[float]]
; CHECK-HACK-DAG: [[zero:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 0{{$}}
; CHECK-HACK-DAG: [[one:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 1{{$}}
; CHECK-HACK-DAG: [[two:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2{{$}}
; CHECK-HACK-DAG: [[three:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 3{{$}}
; CHECK-HACK-DAG: [[mask_sign:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483648
; CHECK-HACK-DAG: [[mask_abs:%[a-zA-Z0-9_]+]] = OpConstant [[int]] 2147483647
; CHECK-HACK-DAG: [[float_min_norm:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 1.17549435e-38
; CHECK-HACK-DAG: [[const_two:%[a-zA-Z0-9_]+]] = OpConstant [[float]] 2{{$}}
; CHECK-HACK: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[block_ptr]] StorageBuffer
; CHECK-HACK: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[zero]]
; CHECK-HACK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[gep0]]
; CHECK-HACK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[one]]
; CHECK-HACK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[gep1]]
; CHECK-HACK: [[cast1_0:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld0]]
; CHECK-HACK: [[and1_0:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast1_0]] [[mask_sign]]
; CHECK-HACK: [[sign0:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and1_0]]
; CHECK-HACK: [[cast2_0:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld0]]
; CHECK-HACK: [[and2_0:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast2_0]] [[mask_abs]]
; CHECK-HACK: [[abs0:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and2_0]]
; CHECK-HACK: [[cond0:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs0]] [[float_min_norm]]
; CHECK-HACK: [[canon0:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[cond0]] [[sign0]] [[ld0]]
; CHECK-HACK: [[cast1_1:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld1]]
; CHECK-HACK: [[and1_1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast1_1]] [[mask_sign]]
; CHECK-HACK: [[sign1:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and1_1]]
; CHECK-HACK: [[cast2_1:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[ld1]]
; CHECK-HACK: [[and2_1:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast2_1]] [[mask_abs]]
; CHECK-HACK: [[abs1:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and2_1]]
; CHECK-HACK: [[cond1:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs1]] [[float_min_norm]]
; CHECK-HACK: [[canon1:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[cond1]] [[sign1]] [[ld1]]
; CHECK-HACK: [[mul:%[a-zA-Z0-9_]+]] = OpFMul [[float]] [[canon0]] [[canon1]]
; CHECK-HACK: [[cast1_res:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[mul]]
; CHECK-HACK: [[and1_res:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast1_res]] [[mask_sign]]
; CHECK-HACK: [[sign_res:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and1_res]]
; CHECK-HACK: [[cast2_res:%[a-zA-Z0-9_]+]] = OpBitcast [[int]] [[mul]]
; CHECK-HACK: [[and2_res:%[a-zA-Z0-9_]+]] = OpBitwiseAnd [[int]] [[cast2_res]] [[mask_abs]]
; CHECK-HACK: [[abs_res:%[a-zA-Z0-9_]+]] = OpBitcast [[float]] [[and2_res]]
; CHECK-HACK: [[cond_res:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs_res]] [[float_min_norm]]
; CHECK-HACK: [[canon_res:%[a-zA-Z0-9_]+]] = OpSelect [[float]] [[cond_res]] [[sign_res]] [[mul]]
; CHECK-HACK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[two]]
; CHECK-HACK: OpStore [[gep2]] [[canon_res]]
; CHECK-HACK: [[mul_p2:%[a-zA-Z0-9_]+]] = OpFMul [[float]] [[ld0]] [[const_two]]
; CHECK-HACK: [[gep3:%[a-zA-Z0-9_]+]] = OpAccessChain [[ptr]] [[var]] [[zero]] [[three]]
; CHECK-HACK: OpStore [[gep3]] [[mul_p2]]

; CHECK-NOHACK: [[var:%[a-zA-Z0-9_]+]] = OpVariable {{.*}} StorageBuffer
; CHECK-NOHACK: [[gep0:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] {{.*}}
; CHECK-NOHACK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[float:%[a-zA-Z0-9_]+]] [[gep0]]
; CHECK-NOHACK: [[gep1:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] {{.*}}
; CHECK-NOHACK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[float]] [[gep1]]
; CHECK-NOHACK: [[mul:%[a-zA-Z0-9_]+]] = OpFMul [[float]] [[ld0]] [[ld1]]
; CHECK-NOHACK: [[gep2:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] {{.*}}
; CHECK-NOHACK: OpStore [[gep2]] [[mul]]
; CHECK-NOHACK: [[mul_p2:%[a-zA-Z0-9_]+]] = OpFMul [[float]] [[ld0]]
; CHECK-NOHACK: [[gep3:%[a-zA-Z0-9_]+]] = OpAccessChain {{.*}} [[var]] {{.*}}
; CHECK-NOHACK: OpStore [[gep3]] [[mul_p2]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 4 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
  %1 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %ld0 = load float, ptr addrspace(1) %1, align 4
  %2 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %ld1 = load float, ptr addrspace(1) %2, align 4
  %res_mul = fmul float %ld0, %ld1
  %3 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 2
  store float %res_mul, ptr addrspace(1) %3, align 4
  %res_p2 = fmul float %ld0, 2.000000e+00
  %4 = getelementptr { [0 x float] }, ptr addrspace(1) %0, i32 0, i32 0, i32 3
  store float %res_p2, ptr addrspace(1) %4, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x float] })

!8 = !{i32 2}
