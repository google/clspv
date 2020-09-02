; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test8(<4 x i32> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr, align 16
  %ptr1 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 1
  %x1 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr1, align 16
  %a = shufflevector <4 x i32> %x0, <4 x i32> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 2
  %x2 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr2, align 16
  %ptr3 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 3
  %x3 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr3, align 16
  %b = shufflevector <4 x i32> %x2, <4 x i32> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %add = add <8 x i32> %a, %b

  %c = shufflevector <8 x i32> %add, <8 x i32> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 4
  store <4 x i32> %c, <4 x i32> addrspace(1)* %ptr4, align 16

  %d = shufflevector <8 x i32> %add, <8 x i32> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 5
  store <4 x i32> %d, <4 x i32> addrspace(1)* %ptr5, align 16

  ret void
}

; CHECK-LABEL: @test8
; TODO Once dead instructions are removed, add CHECK-NOT: add <8 x i32>
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32

define spir_func void @test16(<4 x i32> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr, align 16
  %ptr1 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 1
  %x1 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr1, align 16
  %a = shufflevector <4 x i32> %x0, <4 x i32> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 2
  %x2 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr2, align 16
  %ptr3 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 3
  %x3 = load <4 x i32>, <4 x i32> addrspace(1)* %ptr3, align 16
  %b = shufflevector <4 x i32> %x2, <4 x i32> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %c = shufflevector <8 x i32> %a, <8 x i32> %b, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>

  %add = add <16 x i32> %c, <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>

  %d = shufflevector <16 x i32> %add, <16 x i32> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 4
  store <4 x i32> %d, <4 x i32> addrspace(1)* %ptr4, align 16

  %e = shufflevector <16 x i32> %add, <16 x i32> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 5
  store <4 x i32> %e, <4 x i32> addrspace(1)* %ptr5, align 16

  %f = shufflevector <16 x i32> %add, <16 x i32> undef, <4 x i32> <i32 8, i32 9, i32 10, i32 11>
  %ptr6 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 6
  store <4 x i32> %f, <4 x i32> addrspace(1)* %ptr6, align 16

  %g = shufflevector <16 x i32> %add, <16 x i32> undef, <4 x i32> <i32 12, i32 13, i32 14, i32 15>
  %ptr7 = getelementptr <4 x i32>, <4 x i32> addrspace(1)* %ptr, i32 7
  store <4 x i32> %g, <4 x i32> addrspace(1)* %ptr7, align 16

  ret void
}

; CHECK-LABEL: @test16
; TODO Once dead instructions are removed, add CHECK-NOT: add <16 x i32>
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
; CHECK: add i32
