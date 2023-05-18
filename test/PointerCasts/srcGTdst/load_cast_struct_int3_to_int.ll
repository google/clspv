; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i32:32-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK:  [[gepb:[^ ]+]] = getelementptr { i32, i32, i32 }, ptr addrspace(1) %b, i32 0
; CHECK:  [[udiv:[^ ]+]] = udiv i32 %i, 3
; CHECK:  [[gep:[^ ]+]] = getelementptr { i32, i32, i32 }, ptr addrspace(1) [[gepb]], i32 [[udiv]]
; CHECK:  load { i32, i32, i32 }, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[urem:[^ ]+]] = urem i32 %i, 3
; ...
; CHECK:  [[val:[^ ]+]] = extractelement <3 x i32> %{{.*}}, i32 [[urem]]
; CHECK:  store i32 [[val]], ptr addrspace(1) %a, align 4


define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr { i32, i32, i32 }, ptr addrspace(1) %b, i32 0
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %0, i32 %i
  %1 = load i32, ptr addrspace(1) %arrayidx, align 4
  store i32 %1, ptr addrspace(1) %a, align 4
  ret void
}


