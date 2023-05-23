; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: @test1
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %struct.Line, ptr addrspace(1) %lines, i32 %n, i32 1
; CHECK: store float 0.000000e+00, ptr addrspace(1) [[gep]]

; CHECK: @test2
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %S, ptr addrspace(1) %data, i32 %n, i32 0, i32 1
; CHECK: store float 0.000000e+00, ptr addrspace(1) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.Line = type { i32, float, i32 }
%S = type { %struct.Line, i32 }

define void @test1(ptr addrspace(1) %lines, i32 %n) {
entry:
  %gep1 = getelementptr inbounds %struct.Line, ptr addrspace(1) %lines, i32 %n
  %gep2 = getelementptr inbounds i8, ptr addrspace(1) %gep1, i32 4
  store float 0.000000e+00, ptr addrspace(1) %gep2, align 4
  ret void
}

define void @test2(ptr addrspace(1) %data, i32 %n) {
entry:
  %gep1 = getelementptr inbounds %S, ptr addrspace(1) %data, i32 %n
  %gep2 = getelementptr inbounds i8, ptr addrspace(1) %gep1, i32 4
  store float 0.000000e+00, ptr addrspace(1) %gep2, align 4
  ret void
}
