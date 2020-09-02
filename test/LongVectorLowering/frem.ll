; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test8(<4 x float> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x float>, <4 x float> addrspace(1)* %ptr, align 16
  %ptr1 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 1
  %x1 = load <4 x float>, <4 x float> addrspace(1)* %ptr1, align 16
  %a = shufflevector <4 x float> %x0, <4 x float> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 2
  %x2 = load <4 x float>, <4 x float> addrspace(1)* %ptr2, align 16
  %ptr3 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 3
  %x3 = load <4 x float>, <4 x float> addrspace(1)* %ptr3, align 16
  %b = shufflevector <4 x float> %x2, <4 x float> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %frem = frem <8 x float> %a, %b

  %c = shufflevector <8 x float> %frem, <8 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 4
  store <4 x float> %c, <4 x float> addrspace(1)* %ptr4, align 16

  %d = shufflevector <8 x float> %frem, <8 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 5
  store <4 x float> %d, <4 x float> addrspace(1)* %ptr5, align 16

  ret void
}

; CHECK-LABEL: @test8
; TODO Once dead instructions are removed, add CHECK-NOT: frem <8 x float>
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float

define spir_func void @test16(<4 x float> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x float>, <4 x float> addrspace(1)* %ptr, align 16
  %ptr1 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 1
  %x1 = load <4 x float>, <4 x float> addrspace(1)* %ptr1, align 16
  %a = shufflevector <4 x float> %x0, <4 x float> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 2
  %x2 = load <4 x float>, <4 x float> addrspace(1)* %ptr2, align 16
  %ptr3 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 3
  %x3 = load <4 x float>, <4 x float> addrspace(1)* %ptr3, align 16
  %b = shufflevector <4 x float> %x2, <4 x float> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %c = shufflevector <8 x float> %a, <8 x float> %b, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>

  %frem = frem <16 x float> %c, <float 0.0, float 1.0, float 2.0, float 3.0, float 4.0, float 5.0, float 6.0, float 7.0, float 8.0, float 9.0, float 10.0, float 11.0, float 12.0, float 13.0, float 14.0, float 15.0>

  %d = shufflevector <16 x float> %frem, <16 x float> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 4
  store <4 x float> %d, <4 x float> addrspace(1)* %ptr4, align 16

  %e = shufflevector <16 x float> %frem, <16 x float> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 5
  store <4 x float> %e, <4 x float> addrspace(1)* %ptr5, align 16

  %f = shufflevector <16 x float> %frem, <16 x float> undef, <4 x i32> <i32 8, i32 9, i32 10, i32 11>
  %ptr6 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 6
  store <4 x float> %f, <4 x float> addrspace(1)* %ptr6, align 16

  %g = shufflevector <16 x float> %frem, <16 x float> undef, <4 x i32> <i32 12, i32 13, i32 14, i32 15>
  %ptr7 = getelementptr <4 x float>, <4 x float> addrspace(1)* %ptr, i32 7
  store <4 x float> %g, <4 x float> addrspace(1)* %ptr7, align 16

  ret void
}

; CHECK-LABEL: @test16
; TODO Once dead instructions are removed, add CHECK-NOT: frem <16 x float>
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
; CHECK: frem float
