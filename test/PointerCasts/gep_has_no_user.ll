; RUN: clspv-opt --passes=replace-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test1() {
entry:
  %0 = load i8 addrspace(1)*, i8 addrspace(1)** null, align 4
  %1 = bitcast i8 addrspace(1)* %0 to float addrspace(1)*
  %2 = getelementptr float, float addrspace(1)* %1, i32 0
  ret void
}

; CHECK-LABEL: define dso_local spir_kernel void @test1() {
; CHECK: entry:
; CHECK:   %0 = load i8 addrspace(1)*, i8 addrspace(1)** null, align 4
; CHECK:   %1 = bitcast i8 addrspace(1)* %0 to float addrspace(1)*
; CHECK:   ret void
; CHECK: }

define dso_local spir_kernel void @test2() {
entry:
  %0 = sdiv i32 0, 4
  %1 = bitcast i8 addrspace(1)* undef to float addrspace(1)*
  %2 = getelementptr float, float addrspace(1)* %1, i32 %0
  ret void
}

; CHECK-LABEL: define dso_local spir_kernel void @test2() {
; CHECK: entry:
; CHECK:   %0 = sdiv i32 0, 4
; CHECK:   %1 = bitcast i8 addrspace(1)* undef to float addrspace(1)*
; CHECK:   ret void
; CHECK: }

define dso_local spir_kernel void @test3() {
entry:
  %0 = sdiv i32 0, 4
  %1 = bitcast i8 addrspace(1)* null to float addrspace(1)*
  %2 = getelementptr float, float addrspace(1)* %1, i32 %0
  ret void
}

; CHECK-LABEL: define dso_local spir_kernel void @test3() {
; CHECK: entry:
; CHECK:   %0 = sdiv i32 0, 4
; CHECK:   %1 = bitcast i8 addrspace(1)* null to float addrspace(1)*
; CHECK:   ret void
; CHECK: }
