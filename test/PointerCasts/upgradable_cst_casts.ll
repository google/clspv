; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: do.body.i
; CHECK: getelementptr <4 x half>, ptr addrspace(1) %filters_loc.2.i, i32 1
; CHECK: getelementptr <4 x half>, ptr addrspace(1) %filters_loc.2.i, i32 8

; CHECK: do.end.i
; CHECK: [[lshr:%[^ ]+]] = lshr i32 %shl, 3
; CHECK: getelementptr <4 x half>, ptr addrspace(1) %filters_loc.1.i17, i32 [[lshr]]

; CHECK: for.end.i.loopexit
; CHECK: [[lshr:%[^ ]+]] = lshr i32 %shl, 3
; CHECK: getelementptr <4 x half>, ptr addrspace(1) %filters_loc.0.i36, i32 [[lshr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) %weights_buffer, i32 %i, i32 %j, i1 %cmp0, i1 %cmp1, i1 %cmp2, i1 %cmp3) {
for.body.i.lr.ph:                                 ; preds = %if.end10.i
  %shl = shl i32 %i, 6
  %add.ptr.i = getelementptr inbounds <4 x half>, ptr addrspace(1) %weights_buffer, i32 %j
  br label %for.body.i

for.body.i:                                       ; preds = %for.body.i.lr.ph, %for.end.i
  %filters_loc.0.i36 = phi ptr addrspace(1) [ %add.ptr.i, %for.body.i.lr.ph ], [ %filters_loc.1.i.lcssa, %for.end.i ]
  br i1 %cmp0, label %for.body33.i.lr.ph, label %for.end.i

for.body33.i.lr.ph:                               ; preds = %for.body.i
  br label %for.body33.i

for.body33.i:                                     ; preds = %for.body33.i.lr.ph, %do.end.i
  %filters_loc.1.i17 = phi ptr addrspace(1) [ %filters_loc.0.i36, %for.body33.i.lr.ph ], [ %scevgep, %do.end.i ]
  br label %do.body.i

do.body.i:                                        ; preds = %do.body.i, %for.body33.i
  %filters_loc.2.i = phi ptr addrspace(1) [ %filters_loc.1.i17, %for.body33.i ], [ %add.ptr194.i, %do.body.i ]
  %41 = load <4 x half>, ptr addrspace(1) %filters_loc.2.i, align 8
  %arrayidx82.i = getelementptr inbounds i8, ptr addrspace(1) %filters_loc.2.i, i32 8
  %46 = load <4 x half>, ptr addrspace(1) %arrayidx82.i, align 8
  %add.ptr194.i = getelementptr inbounds i8, ptr addrspace(1) %filters_loc.2.i, i32 64
  br i1 %cmp1, label %do.body.i, label %do.end.i

do.end.i:                                         ; preds = %do.body.i
  %scevgep = getelementptr i8, ptr addrspace(1) %filters_loc.1.i17, i32 %shl
  br i1 %cmp2, label %for.body33.i, label %for.end.i.loopexit

for.end.i.loopexit:                               ; preds = %do.end.i
  %scevgep60 = getelementptr i8, ptr addrspace(1) %filters_loc.0.i36, i32 %shl
  br label %for.end.i

for.end.i:                                        ; preds = %for.end.i.loopexit, %for.body.i
  %filters_loc.1.i.lcssa = phi ptr addrspace(1) [ %filters_loc.0.i36, %for.body.i ], [ %scevgep60, %for.end.i.loopexit ]
  br i1 %cmp3, label %for.body.i, label %exit

exit:
  ret void
}
