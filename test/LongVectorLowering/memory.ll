; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; This test covers alloca, load and store instructions.

declare spir_func void @sink(ptr %x)

define spir_func void @test1(ptr %ptr) {
  %alloca = alloca <16 x half>, align 16
  %value = load <16 x half>, ptr %ptr, align 16
  store volatile <16 x half> %value, ptr %alloca, align 16
  call spir_func void @sink(ptr %alloca)
  ret void
}

define spir_func void @test2(ptr %ptr) {
  %alloca = alloca <8 x i32>, align 32
  %value = load volatile <8 x i32>, ptr %ptr, align 32
  store <8 x i32> %value, ptr %alloca, align 32
  call spir_func void @sink(ptr %alloca)
  ret void
}

; CHECK: define spir_func void @test1(ptr [[PTR:%[^ ]+]])
; CHECK: [[ALLOCA:%[^ ]+]] = alloca [[HALF16:\[16 x half\]]], align 16
; CHECK: [[VALUE:%[^ ]+]] = load [[HALF16]], ptr [[PTR]], align 16
; CHECK: store volatile [[HALF16]] [[VALUE]], ptr [[ALLOCA]], align 16
; CHECK: call spir_func void @sink(ptr [[ALLOCA]])
; CHECK: ret void

; CHECK: define spir_func void @test2(ptr [[PTR:%[^ ]+]])
; CHECK: [[ALLOCA:%[^ ]+]] = alloca [[INT8:\[8 x i32\]]], align 32
; CHECK: [[VALUE:%[^ ]+]] = load volatile [[INT8]], ptr [[PTR]], align 32
; CHECK: store [[INT8]] [[VALUE]], ptr [[ALLOCA]], align 32
; CHECK: call spir_func void @sink(ptr [[ALLOCA]])
; CHECK: ret void
