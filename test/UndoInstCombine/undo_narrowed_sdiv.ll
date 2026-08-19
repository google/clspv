; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define void @test_sdiv(i32 %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_sdiv
  ; CHECK: [[div:%[a-zA-Z0-9_.]+]] = sdiv i32 %in, 3
  ; CHECK: store i32 [[div]]
  ; CHECK-NOT: sdiv i16
  %trunc = trunc nsw i32 %in to i16
  %sdiv = sdiv i16 %trunc, 3
  %sext = sext i16 %sdiv to i32
  store i32 %sext, ptr addrspace(1) %out, align 4
  ret void
}

define void @test_udiv(i32 %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_udiv
  ; CHECK: [[div:%[a-zA-Z0-9_.]+]] = udiv i32 %in, 3
  ; CHECK: store i32 [[div]]
  ; CHECK-NOT: udiv i16
  %trunc = trunc nuw i32 %in to i16
  %udiv = udiv i16 %trunc, 3
  %zext = zext i16 %udiv to i32
  store i32 %zext, ptr addrspace(1) %out, align 4
  ret void
}
