; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

; This test covers alloca, load and store instructions.

declare spir_func void @sink(i8* %x)

define spir_func void @test1(<16 x half>* %ptr) {
  %alloca = alloca <16 x half>, align 16
  %value = load <16 x half>, <16 x half>* %ptr, align 16
  store volatile <16 x half> %value, <16 x half>* %alloca, align 16
  %cast = bitcast <16 x half>* %alloca to i8*
  call spir_func void @sink(i8* %cast)
  ret void
}

define spir_func void @test2(<8 x i32>* %ptr) {
  %alloca = alloca <8 x i32>, align 32
  %value = load volatile <8 x i32>, <8 x i32>* %ptr, align 32
  store <8 x i32> %value, <8 x i32>* %alloca, align 32
  %cast = bitcast <8 x i32>* %alloca to i8*
  call spir_func void @sink(i8* %cast)
  ret void
}

; CHECK-LABEL: define spir_func void @test2(
; CHECK-SAME: [[INT8:{ i32, i32, i32, i32, i32, i32, i32, i32 }]]* [[PTR:%[^ ]+]])
; CHECK: [[ALLOCA:%[^ ]+]] = alloca [[INT8]], align 32
; CHECK: [[VALUE:%[^ ]+]] = load volatile [[INT8]], [[INT8]]* [[PTR]], align 32
; CHECK: store [[INT8]] [[VALUE]], [[INT8]]* [[ALLOCA]], align 32
; CHECK: [[CAST:%[^ ]+]] = bitcast [[INT8]]* [[ALLOCA]] to i8*
; CHECK: call spir_func void @sink(i8* [[CAST]])
; CHECK: ret void

; CHECK-LABEL: define spir_func void @test1(
; CHECK-SAME: [[HALF16:{ half, half, half, half, half, half, half, half, half, half, half, half, half, half, half, half }]]* [[PTR:%[^ ]+]])
; CHECK: [[ALLOCA:%[^ ]+]] = alloca [[HALF16]], align 16
; CHECK: [[VALUE:%[^ ]+]] = load [[HALF16]], [[HALF16]]* [[PTR]], align 16
; CHECK: store volatile [[HALF16]] [[VALUE]], [[HALF16]]* [[ALLOCA]], align 16
; CHECK: [[CAST:%[^ ]+]] = bitcast [[HALF16]]* [[ALLOCA]] to i8*
; CHECK: call spir_func void @sink(i8* [[CAST]])
; CHECK: ret void
