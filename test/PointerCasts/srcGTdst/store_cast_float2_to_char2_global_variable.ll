; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[gv:@[^ ]+]] = addrspace(1) global [4 x <2 x i8>] zeroinitializer
; CHECK:  [[load:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) %b, align 2
; CHECK:  [[shl:%[^ ]+]] = shl i32 %i, 2
; CHECK:  [[shl2:%[^ ]+]] = shl i32 %1, 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[shl2]], 3
; CHECK:  [[and:%[^ ]+]] = and i32 [[shl2]], 7
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[and]], 1
; CHECK:  getelementptr [4 x <2 x i8>], ptr addrspace(1) [[gv]], i32 [[lshr]], i32 [[lshr2]]
; CHECK:  store <2 x i8> [[load]], ptr addrspace(1) [[gv]], align 2

@my_var = addrspace(1) global <2 x float> zeroinitializer

define spir_kernel void @foo(ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = load <2 x i8>, ptr addrspace(1) %b, align 2
  %1 = getelementptr <2 x float>, ptr addrspace(1) @my_var, i32 %i
  store <2 x i8> %0, ptr addrspace(1) %1, align 2
  store <2 x i8> %0, ptr addrspace(1) @my_var, align 2
  ret void
}
