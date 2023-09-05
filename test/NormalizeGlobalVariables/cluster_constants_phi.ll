; RUN: clspv-opt %s -o %t.ll --passes=cluster-constants
; RUN: FileCheck %s < %t.ll

; CHECK: entry:
; CHECK:   [[gep_entry:%[^ ]+]] = getelementptr inbounds { <{ [4 x i32] }> }, ptr addrspace(2) @clspv.clustered_constants, i32 0, i32 0
; CHECK:   br i1 %test, label %true, label %false
; CHECK: true:
; CHECK:   [[gep_true:%[^ ]+]] = getelementptr inbounds { <{ [4 x i32] }> }, ptr addrspace(2) @clspv.clustered_constants, i32 0, i32 0
; CHECK:   br i1 %test2, label %exit, label %false
; CHECK: false:
; CHECK:   %phi = phi ptr addrspace(2) [ [[gep_entry]], %entry ], [ [[gep_true]], %true ]


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@data = addrspace(2) constant <{ [4 x i32] }> <{ [ 4 x i32 ]  zeroinitializer }>, align 4

; Function Attrs: convergent nounwind
define spir_kernel void @foo(i1 %test, i1 %test2) {
entry:
  br i1 %test, label %true, label %false
true:
  br i1 %test2, label %exit, label %false
false:
  %phi = phi ptr addrspace(2) [ @data, %entry ], [ @data, %true]
  br label %exit
exit:
  ret void
}
