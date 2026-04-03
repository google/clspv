; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll
; CHECK:  [[shl:%[^ ]+]] = shl i32 %a, 1
; CHECK:  [[add:%[^ ]+]] = add i32 [[shl]], 16
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add]], 3
; CHECK:  [[and:%[^ ]+]] = and i32 [[add]], 7
; CHECK:  [[lshr2:%[^ ]+]] = lshr i32 [[and]], 1
; CHECK:  [[and2:%[^ ]+]] = and i32 [[and]], 1
; CHECK:  getelementptr [32 x [4 x <2 x float>]], ptr addrspace(3) @main_function.loc_mem, i32 0, i32 [[lshr]], i32 [[lshr2]], i32 [[and2]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@main_function.loc_mem = internal addrspace(3) global [32 x [4 x <2 x float>]] undef, align 8

define spir_kernel void @fct(i32 %a) {
entry:
  %0 = getelementptr inbounds [4 x <2 x float>], ptr addrspace(3) getelementptr inbounds nuw (i8, ptr addrspace(3) @main_function.loc_mem, i32 64), i32 0, i32 %a
  ret void
}
