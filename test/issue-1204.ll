; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: [[entry:[^:]+]]:
; CHECK:   [[shl:%[^ ]+]] = shl i32 %i, 1
; CHECK:   [[gep1:%[^ ]+]] = getelementptr i16, ptr %s1, i32 [[shl]]
; CHECK:   br i1 %test, label %[[b0:[^,]+]], label %[[b1:[^ ]+]]
; CHECK: [[b0]]:
; CHECK:   [[gep2:%[^ ]+]] = getelementptr i16, ptr %s2, i32 %i
; CHECK:   br i1 %test, label %[[b1]], label %[[b2:[^ ]+]]
; CHECK: [[b1]]:
; CHECK:   [[phi1:%[^ ]+]] = phi ptr [ [[gep1]], %entry ], [ [[gep2]], %b0 ]
; CHECK:   getelementptr i8, ptr [[phi1]], i32 %j
; CHECK:   br label %[[b2]]
; CHECK: [[b2]]:
; CHECK:   phi ptr [ [[gep1]], %b1 ], [ [[gep2]], %b0 ]
; CHECK:   getelementptr i8, ptr %phi2, i32 %j
; CHECK:   ret void

define dso_local spir_kernel void @kernel(ptr %s1, ptr %s2, i32 %i, i32 %j, i1 %test) {
entry:
  %gep_s1 = getelementptr i32, ptr %s1, i32 %i
  br i1 %test, label %b0, label %b1
b0:
  %gep_s2 = getelementptr i16, ptr %s2, i32 %i
  br i1 %test, label %b1, label %b2
b1:
  %phi1 = phi ptr [ %gep_s1, %entry ], [ %gep_s2, %b0 ]
  %gep1 = getelementptr i8, ptr %phi1, i32 %j
  br label %b2
b2:
  %phi2 = phi ptr [ %gep_s1, %b1 ], [ %gep_s2, %b0 ]
  %gep2 = getelementptr i8, ptr %phi2, i32 %j
  ret void
}
