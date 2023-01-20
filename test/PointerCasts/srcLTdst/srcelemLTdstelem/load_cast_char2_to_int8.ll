; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: [[shl:%[^ ]+]] = shl i32 %i, 5
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
; CHECK: [[add8:%[^ ]+]] = add i32 [[add7]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add8]]
; CHECK: [[ld8:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add9:%[^ ]+]] = add i32 [[add8]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add9]]
; CHECK: [[ld9:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add10:%[^ ]+]] = add i32 [[add9]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add10]]
; CHECK: [[ld10:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add11:%[^ ]+]] = add i32 [[add10]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add11]]
; CHECK: [[ld11:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add12:%[^ ]+]] = add i32 [[add11]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add12]]
; CHECK: [[ld12:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add13:%[^ ]+]] = add i32 [[add12]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add13]]
; CHECK: [[ld13:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add14:%[^ ]+]] = add i32 [[add13]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add14]]
; CHECK: [[ld14:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]
; CHECK: [[add15:%[^ ]+]] = add i32 [[add14]], 1
; CHECK: [[gep:%[^ ]+]] = getelementptr <2 x i8>, ptr addrspace(1) %0, i32 [[add15]]
; CHECK: [[ld15:%[^ ]+]] = load <2 x i8>, ptr addrspace(1) [[gep]]

; CHECK: [[in1:%[^ ]+]] = shufflevector <2 x i8> [[ld0]], <2 x i8> [[ld1]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in2:%[^ ]+]] = shufflevector <2 x i8> [[ld2]], <2 x i8> [[ld3]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in3:%[^ ]+]] = shufflevector <2 x i8> [[ld4]], <2 x i8> [[ld5]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in4:%[^ ]+]] = shufflevector <2 x i8> [[ld6]], <2 x i8> [[ld7]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in5:%[^ ]+]] = shufflevector <2 x i8> [[ld8]], <2 x i8> [[ld9]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in6:%[^ ]+]] = shufflevector <2 x i8> [[ld10]], <2 x i8> [[ld11]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in7:%[^ ]+]] = shufflevector <2 x i8> [[ld12]], <2 x i8> [[ld13]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in8:%[^ ]+]] = shufflevector <2 x i8> [[ld14]], <2 x i8> [[ld15]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: [[in1cast:%[^ ]+]] = bitcast <4 x i8> [[in1]] to i32
; CHECK: [[in2cast:%[^ ]+]] = bitcast <4 x i8> [[in2]] to i32
; CHECK: [[in3cast:%[^ ]+]] = bitcast <4 x i8> [[in3]] to i32
; CHECK: [[in4cast:%[^ ]+]] = bitcast <4 x i8> [[in4]] to i32
; CHECK: [[in5cast:%[^ ]+]] = bitcast <4 x i8> [[in5]] to i32
; CHECK: [[in6cast:%[^ ]+]] = bitcast <4 x i8> [[in6]] to i32
; CHECK: [[in7cast:%[^ ]+]] = bitcast <4 x i8> [[in7]] to i32
; CHECK: [[in8cast:%[^ ]+]] = bitcast <4 x i8> [[in8]] to i32
; CHECK: [[ret0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[in1cast]], 0
; CHECK: [[ret1:%[^ ]+]] = insertvalue [8 x i32] [[ret0]], i32 [[in2cast]], 1
; CHECK: [[ret2:%[^ ]+]] = insertvalue [8 x i32] [[ret1]], i32 [[in3cast]], 2
; CHECK: [[ret3:%[^ ]+]] = insertvalue [8 x i32] [[ret2]], i32 [[in4cast]], 3
; CHECK: [[ret4:%[^ ]+]] = insertvalue [8 x i32] [[ret3]], i32 [[in5cast]], 4
; CHECK: [[ret5:%[^ ]+]] = insertvalue [8 x i32] [[ret4]], i32 [[in6cast]], 5
; CHECK: [[ret6:%[^ ]+]] = insertvalue [8 x i32] [[ret5]], i32 [[in7cast]], 6
; CHECK: [[ret7:%[^ ]+]] = insertvalue [8 x i32] [[ret6]], i32 [[in8cast]], 7
define spir_kernel void @foo(ptr addrspace(1) %a, ptr addrspace(1) %b, i32 %i) {
entry:  
  %0 = getelementptr <2 x i8>, ptr addrspace(1) %a, i32 0
  %arrayidx = getelementptr inbounds [8 x i32], ptr addrspace(1) %0, i32 %i
  %1 = load [8 x i32], ptr addrspace(1) %arrayidx, align 8
  store [8 x i32] %1, ptr addrspace(1) %b, align 8
  ret void
}

