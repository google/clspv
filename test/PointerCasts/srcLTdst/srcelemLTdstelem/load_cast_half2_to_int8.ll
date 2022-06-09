; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 4
; CHECK: [[shr:%[^ ]+]] = lshr i32 [[shl]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[shr]]
; CHECK: [[ld0:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add:%[^ ]+]] = add i32 [[shr]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add]]
; CHECK: [[ld1:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add2:%[^ ]+]] = add i32 [[add]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add2]]
; CHECK: [[ld2:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add3:%[^ ]+]] = add i32 [[add2]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add3]]
; CHECK: [[ld3:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add4:%[^ ]+]] = add i32 [[add3]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add4]]
; CHECK: [[ld4:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add5:%[^ ]+]] = add i32 [[add4]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add5]]
; CHECK: [[ld5:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add6:%[^ ]+]] = add i32 [[add5]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add6]]
; CHECK: [[ld6:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]
; CHECK: [[add7:%[^ ]+]] = add i32 [[add6]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x half>, <2 x half> addrspace(1)* %a, i32 [[add7]]
; CHECK: [[ld7:%[^ ]+]] = load <2 x half>, <2 x half> addrspace(1)* [[gep]]

; CHECK: [[ld0cast:%[^ ]+]] = bitcast <2 x half> [[ld0]] to i32
; CHECK: [[ld1cast:%[^ ]+]] = bitcast <2 x half> [[ld1]] to i32
; CHECK: [[ld2cast:%[^ ]+]] = bitcast <2 x half> [[ld2]] to i32
; CHECK: [[ld3cast:%[^ ]+]] = bitcast <2 x half> [[ld3]] to i32
; CHECK: [[ld4cast:%[^ ]+]] = bitcast <2 x half> [[ld4]] to i32
; CHECK: [[ld5cast:%[^ ]+]] = bitcast <2 x half> [[ld5]] to i32
; CHECK: [[ld6cast:%[^ ]+]] = bitcast <2 x half> [[ld6]] to i32
; CHECK: [[ld7cast:%[^ ]+]] = bitcast <2 x half> [[ld7]] to i32

; CHECK: [[ret0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[ld0cast]], 0
; CHECK: [[ret1:%[^ ]+]] = insertvalue [8 x i32] [[ret0]], i32 [[ld1cast]], 1
; CHECK: [[ret2:%[^ ]+]] = insertvalue [8 x i32] [[ret1]], i32 [[ld2cast]], 2
; CHECK: [[ret3:%[^ ]+]] = insertvalue [8 x i32] [[ret2]], i32 [[ld3cast]], 3
; CHECK: [[ret4:%[^ ]+]] = insertvalue [8 x i32] [[ret3]], i32 [[ld4cast]], 4
; CHECK: [[ret5:%[^ ]+]] = insertvalue [8 x i32] [[ret4]], i32 [[ld5cast]], 5
; CHECK: [[ret6:%[^ ]+]] = insertvalue [8 x i32] [[ret5]], i32 [[ld6cast]], 6
; CHECK: [[ret7:%[^ ]+]] = insertvalue [8 x i32] [[ret6]], i32 [[ld7cast]], 7

define spir_kernel void @foo(<2 x half> addrspace(1)* %a, [8 x i32] addrspace(1)* %b, i32 %i) {
entry:
  %0 = bitcast <2 x half> addrspace(1)* %a to [8 x i32] addrspace(1)*
  %arrayidx = getelementptr inbounds [8 x i32], [8 x i32] addrspace(1)* %0, i32 %i
  %1 = load [8 x i32], [8 x i32] addrspace(1)* %arrayidx, align 8
  store [8 x i32] %1, [8 x i32] addrspace(1)* %b, align 8
  ret void
}

