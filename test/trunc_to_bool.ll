; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test() {
entry:
    %0 = trunc <2 x i32> zeroinitializer to <2 x i1>
    ret void
}

; CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
; CHECK-DAG: [[bool:%[^ ]+]] = OpTypeBool
; CHECK-DAG: [[v2bool:%[^ ]+]] = OpTypeVector [[bool]] 2
; CHECK: [[null:%[^ ]+]] = OpConstantNull [[v2uint]]
; CHECK: OpINotEqual [[v2bool]] [[null]] [[null]]
