; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test8(<4 x i64> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr, align 32
  %ptr1 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 1
  %x1 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr1, align 32
  %a = shufflevector <4 x i64> %x0, <4 x i64> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 2
  %x2 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr2, align 32
  %ptr3 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 3
  %x3 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr3, align 32
  %b = shufflevector <4 x i64> %x2, <4 x i64> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %and = and <8 x i64> %a, %b

  %c = shufflevector <8 x i64> %and, <8 x i64> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 4
  store <4 x i64> %c, <4 x i64> addrspace(1)* %ptr4, align 32

  %d = shufflevector <8 x i64> %and, <8 x i64> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 5
  store <4 x i64> %d, <4 x i64> addrspace(1)* %ptr5, align 32

  ret void
}

; CHECK-LABEL: @test8
; TODO Once dead instructions are removed, add CHECK-NOT: and <8 x i64>
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64

define spir_func void @test16(<4 x i64> addrspace(1)* %ptr) {
entry:
  %x0 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr, align 32
  %ptr1 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 1
  %x1 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr1, align 32
  %a = shufflevector <4 x i64> %x0, <4 x i64> %x1, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %ptr2 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 2
  %x2 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr2, align 32
  %ptr3 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 3
  %x3 = load <4 x i64>, <4 x i64> addrspace(1)* %ptr3, align 32
  %b = shufflevector <4 x i64> %x2, <4 x i64> %x3, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>

  %c = shufflevector <8 x i64> %a, <8 x i64> %b, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>

  %and = and <16 x i64> %c, <i64 0, i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8, i64 9, i64 10, i64 11, i64 12, i64 13, i64 14, i64 15>

  %d = shufflevector <16 x i64> %and, <16 x i64> undef, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
  %ptr4 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 4
  store <4 x i64> %d, <4 x i64> addrspace(1)* %ptr4, align 32

  %e = shufflevector <16 x i64> %and, <16 x i64> undef, <4 x i32> <i32 4, i32 5, i32 6, i32 7>
  %ptr5 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 5
  store <4 x i64> %e, <4 x i64> addrspace(1)* %ptr5, align 32

  %f = shufflevector <16 x i64> %and, <16 x i64> undef, <4 x i32> <i32 8, i32 9, i32 10, i32 11>
  %ptr6 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 6
  store <4 x i64> %f, <4 x i64> addrspace(1)* %ptr6, align 32

  %g = shufflevector <16 x i64> %and, <16 x i64> undef, <4 x i32> <i32 12, i32 13, i32 14, i32 15>
  %ptr7 = getelementptr <4 x i64>, <4 x i64> addrspace(1)* %ptr, i64 7
  store <4 x i64> %g, <4 x i64> addrspace(1)* %ptr7, align 32

  ret void
}

; CHECK-LABEL: @test16
; TODO Once dead instructions are removed, add CHECK-NOT: and <16 x i64>
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
; CHECK: and i64
