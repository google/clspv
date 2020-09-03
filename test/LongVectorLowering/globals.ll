; RUN: clspv-opt --LongVectorLowering --instcombine %s -o %t
; RUN: FileCheck %s < %t
; RUN: FileCheck --check-prefix=NEGATIVE %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; NEGATIVE-NOT: <8 x float>
; NEGATIVE-NOT: <16 x float>

@global_a = external addrspace(2) constant <8 x float>, align 32
; CHECK: external addrspace(2) constant { float, float, float, float, float, float, float, float }, align 32

@global_b = addrspace(3) global <16 x i16> zeroinitializer, align 16
; CHECK: addrspace(3) global { i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16, i16 }
; CHECK-SAME: zeroinitializer, align 16

define spir_func <8 x float> @test_a() {
entry:
  %x = load <8 x float>, <8 x float> addrspace(2)* @global_a, align 32
  ret <8 x float> %x
}

define spir_func <16 x i16> @test_b() {
entry:
  %x = load <16 x i16>, <16 x i16> addrspace(3)* @global_b, align 16
  ret <16 x i16> %x
}

; CHECK-LABEL: @test_b
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16
; CHECK: load i16

; CHECK-LABEL: @test_a
; CHECK: load float
; CHECK: load float
; CHECK: load float
; CHECK: load float
; CHECK: load float
; CHECK: load float
; CHECK: load float
; CHECK: load float
