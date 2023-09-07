; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: getelementptr i8, ptr %md5, i32 4

define dso_local spir_kernel void @kernel(ptr %md5) {
entry:
    %arraydecay518 = getelementptr [4 x i32], ptr %md5, i32 0, i32 0
    %arrayidx519 = getelementptr i8, ptr %arraydecay518, i32 4
    ret void
}
