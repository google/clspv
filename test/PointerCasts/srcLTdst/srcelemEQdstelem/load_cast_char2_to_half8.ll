; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[shr]]
; CHECK: [[ld0:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add4]]
; CHECK: [[ld4:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add5]]
; CHECK: [[ld5:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add6]]
; CHECK: [[ld6:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add7]]
; CHECK: [[ld7:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]

; CHECK: [[ld0cast:%[^ ]+]] = bitcast <2 x i8> [[ld0]] to half
; CHECK: [[ld1cast:%[^ ]+]] = bitcast <2 x i8> [[ld1]] to half
; CHECK: [[ld2cast:%[^ ]+]] = bitcast <2 x i8> [[ld2]] to half
; CHECK: [[ld3cast:%[^ ]+]] = bitcast <2 x i8> [[ld3]] to half
; CHECK: [[ld4cast:%[^ ]+]] = bitcast <2 x i8> [[ld4]] to half
; CHECK: [[ld5cast:%[^ ]+]] = bitcast <2 x i8> [[ld5]] to half
; CHECK: [[ld6cast:%[^ ]+]] = bitcast <2 x i8> [[ld6]] to half
; CHECK: [[ld7cast:%[^ ]+]] = bitcast <2 x i8> [[ld7]] to half

; CHECK: [[ret0:%[^ ]+]] = insertvalue [8 x half] poison, half [[ld0cast]], 0
; CHECK: [[ret1:%[^ ]+]] = insertvalue [8 x half] [[ret0]], half [[ld1cast]], 1
; CHECK: [[ret2:%[^ ]+]] = insertvalue [8 x half] [[ret1]], half [[ld2cast]], 2
; CHECK: [[ret3:%[^ ]+]] = insertvalue [8 x half] [[ret2]], half [[ld3cast]], 3
; CHECK: [[ret4:%[^ ]+]] = insertvalue [8 x half] [[ret3]], half [[ld4cast]], 4
; CHECK: [[ret5:%[^ ]+]] = insertvalue [8 x half] [[ret4]], half [[ld5cast]], 5
; CHECK: [[ret6:%[^ ]+]] = insertvalue [8 x half] [[ret5]], half [[ld6cast]], 6
; CHECK: [[ret7:%[^ ]+]] = insertvalue [8 x half] [[ret6]], half [[ld7cast]], 7

define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:
  %0 = getelementptr <2 x i8>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x half], ptr addrspace(1) %0, i32 %i
  %1 = load [8 x half], ptr addrspace(1) %arrayidx, align 8
  store [8 x half] %1, ptr addrspace(1) %b, align 8
  ret void
}

