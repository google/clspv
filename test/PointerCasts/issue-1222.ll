; RUN: clspv-opt --passes=replace-pointer-bitcast %s -o %t
; RUN: FileCheck %s < %t

; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 0
; CHECK:  [[load0:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 1
; CHECK:  [[load1:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 2
; CHECK:  [[load2:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]], align 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 3
; CHECK:  [[load3:%[^ ]+]] = load i8, ptr addrspace(1) [[gep]], align 1
; CHECK:  [[insert0:%[^ ]+]] = insertelement <4 x i8> poison, i8 [[load0]], i32 0
; CHECK:  [[insert1:%[^ ]+]] = insertelement <4 x i8> [[insert0]], i8 [[load1]], i32 1
; CHECK:  [[insert2:%[^ ]+]] = insertelement <4 x i8> [[insert1]], i8 [[load2]], i32 2
; CHECK:  [[insert3:%[^ ]+]] = insertelement <4 x i8> [[insert2]], i8 [[load3]], i32 3
; CHECK:  [[bitcast:%[^ ]+]] = bitcast <4 x i8> [[insert3]] to i32
; CHECK:  [[gep:%[^ ]+]] = getelementptr i8, ptr addrspace(1) %in, i32 3
; CHECK:  [[bitcast2:%[^ ]+]] = bitcast i32 [[bitcast]] to <4 x i8>
; CHECK:  [[extract0:%[^ ]+]] = extractelement <4 x i8> [[bitcast2]], i64 0
; CHECK:  [[extract1:%[^ ]+]] = extractelement <4 x i8> [[bitcast2]], i64 1
; CHECK:  [[extract2:%[^ ]+]] = extractelement <4 x i8> [[bitcast2]], i64 2
; CHECK:  [[extract3:%[^ ]+]] = extractelement <4 x i8> [[bitcast2]], i64 3
; CHECK:  [[gep0:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store i8 [[extract0]], ptr addrspace(1) [[gep0]], align 1
; CHECK:  [[gep1:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 1
; CHECK:  store i8 [[extract1]], ptr addrspace(1) [[gep1]], align 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 2
; CHECK:  store i8 [[extract2]], ptr addrspace(1) [[gep2]], align 1
; CHECK:  [[gep3:%[^ ]+]] = getelementptr i8, ptr addrspace(1) [[gep]], i32 3
; CHECK:  store i8 [[extract3]], ptr addrspace(1) [[gep3]], align 1

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) %in, i32 %n) {
entry:
  %load = load i32, ptr addrspace(1) %in, align 4
  %gep = getelementptr [8 x i8], ptr addrspace(1) %in, i32 0, i32 3
  store i32 %load, ptr addrspace(1) %gep, align 4
  ret void
}

