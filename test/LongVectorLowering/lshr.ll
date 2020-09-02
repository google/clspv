; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test8(<4 x i16> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr, align 8
  %ptr1 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 1
  %x1 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr1, align 8
  %a = shufflevector <4 x i16> %x0, <4 x i16> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 2
  %x2 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr2, align 8
  %ptr3 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 3
  %x3 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr3, align 8
  %b = shufflevector <4 x i16> %x2, <4 x i16> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %lshr = lshr <8 x i16> %a, %b

  %c = shufflevector <8 x i16> %lshr, <8 x i16> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 4
  store <4 x i16> %c, <4 x i16> addrspace(1)* %ptr4, align 8

  %d = shufflevector <8 x i16> %lshr, <8 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 5
  store <4 x i16> %d, <4 x i16> addrspace(1)* %ptr5, align 8

  ret void
}

; CHECK-LABEL: @test8
; TODO Once dead instructions are removed, add CHECK-NOT: lshr <8 x i16>
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16

define spir_func void @test16(<4 x i16> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr, align 8
  %ptr1 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 1
  %x1 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr1, align 8
  %a = shufflevector <4 x i16> %x0, <4 x i16> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 2
  %x2 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr2, align 8
  %ptr3 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 3
  %x3 = load <4 x i16>, <4 x i16> addrspace(1)* %ptr3, align 8
  %b = shufflevector <4 x i16> %x2, <4 x i16> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %c = shufflevector <8 x i16> %a, <8 x i16> %b, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>

  %lshr = lshr <16 x i16> %c, <i16 0, i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7, i16 8, i16 9, i16 10, i16 11, i16 12, i16 13, i16 14, i16 15>

  %d = shufflevector <16 x i16> %lshr, <16 x i16> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 4
  store <4 x i16> %d, <4 x i16> addrspace(1)* %ptr4, align 8

  %e = shufflevector <16 x i16> %lshr, <16 x i16> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 5
  store <4 x i16> %e, <4 x i16> addrspace(1)* %ptr5, align 8

  %f = shufflevector <16 x i16> %lshr, <16 x i16> undef, <4 x i32> <i32 8, i32 9, i32 10, i32 11>
  %ptr6 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 6
  store <4 x i16> %f, <4 x i16> addrspace(1)* %ptr6, align 8

  %g = shufflevector <16 x i16> %lshr, <16 x i16> undef, <4 x i32> <i32 12, i32 13, i32 14, i32 15>
  %ptr7 = getelementptr <4 x i16>, <4 x i16> addrspace(1)* %ptr, i16 7
  store <4 x i16> %g, <4 x i16> addrspace(1)* %ptr7, align 8

  ret void
}

; CHECK-LABEL: @test16
; TODO Once dead instructions are removed, add CHECK-NOT: lshr <16 x i16>
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
; CHECK: lshr i16
