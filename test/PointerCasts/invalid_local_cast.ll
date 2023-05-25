; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast &> %t.stderr || echo "failure expected"
; RUN: FileCheck %s < %t.stderr

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: Err: SrcTy = float - DstTy = float - Ty = float - CstVal = 32

define void @test6(ptr %in) {
entry:
  %gep1 = getelementptr float, ptr %in, i32 1
  %gep2 = getelementptr i32, ptr %gep1, i32 1
  ret void
}

