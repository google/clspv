
; RUN: clspv-opt --passes=replace-opencl-builtin,replace-llvm-intrinsics,long-vector-lowering,instcombine %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <8 x i8> @sub_sat_uchar8(<8 x i8> %a, <8 x i8> %b) {
entry:
 %call = call <8 x i8> @_Z7sub_satDv8_hS_(<8 x i8> %a, <8 x i8> %b)
 ret <8 x i8> %call
}

declare <8 x i8> @_Z7sub_satDv8_hS_(<8 x i8>, <8 x i8>)

; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op
; CHECK: @_Z8spirv.op

