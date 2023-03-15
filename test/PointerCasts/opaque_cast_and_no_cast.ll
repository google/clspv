; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: for.body:
; CHECK: getelementptr inbounds <2 x i8>,
; CHECK: getelementptr inbounds <2 x i8>,
; CHECK: for.inc:

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_LocalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @test_fn(ptr addrspace(3) align 2 %sSharedStorage, ptr addrspace(1) align 2 %src, ptr addrspace(1) align 4 %offsets, ptr addrspace(1) align 4 %alignmentOffsets, ptr addrspace(1) align 2 %results) {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 1
  %2 = load i32, ptr addrspace(9) %1, align 4
  %3 = add i32 %0, %2
  %4 = load i32, ptr addrspace(5) @__spirv_LocalInvocationId, align 4
  %cmp = icmp eq i32 %4, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %if.then
  %i.0 = phi i32 [ 0, %if.then ], [ %inc, %for.inc ]
  %cmp2 = icmp slt i32 %i.0, 4096
  br i1 %cmp2, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds <2 x i8>, ptr addrspace(1) %src, i32 %i.0
  %5 = load <2 x i8>, ptr addrspace(1) %arrayidx, align 2
  %arrayidx3 = getelementptr inbounds <2 x i8>, ptr addrspace(3) %sSharedStorage, i32 %i.0
  store <2 x i8> %5, ptr addrspace(3) %arrayidx3, align 2
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  br label %if.end

if.end:                                           ; preds = %for.end, %entry
  %6 = and i32 1, 1
  %7 = shl i32 %6, 8
  %8 = and i32 2, 1
  %9 = shl i32 %8, 5
  %10 = and i32 4, 1
  %11 = shl i32 %10, 9
  %12 = or i32 %7, 8
  %13 = or i32 %9, %11
  %14 = or i32 %12, %13
  call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 %14)
  %arrayidx4 = getelementptr inbounds i32, ptr addrspace(1) %offsets, i32 %3
  %15 = load i32, ptr addrspace(1) %arrayidx4, align 4
  %arrayidx5 = getelementptr inbounds i32, ptr addrspace(1) %alignmentOffsets, i32 %3
  %16 = load i32, ptr addrspace(1) %arrayidx5, align 4
  %17 = mul i32 %15, 2
  %18 = add i32 %17, 0
  %19 = add i32 %16, %18
  %20 = getelementptr i8, ptr addrspace(3) %sSharedStorage, i32 %19
  %21 = load i8, ptr addrspace(3) %20, align 1
  %22 = insertelement <2 x i8> undef, i8 %21, i64 0
  %23 = add i32 %17, 1
  %24 = add i32 %16, %23
  %25 = getelementptr i8, ptr addrspace(3) %sSharedStorage, i32 %24
  %26 = load i8, ptr addrspace(3) %25, align 1
  %27 = insertelement <2 x i8> %22, i8 %26, i64 1
  %arrayidx7 = getelementptr inbounds <2 x i8>, ptr addrspace(1) %results, i32 %3
  store <2 x i8> %27, ptr addrspace(1) %arrayidx7, align 2
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)

