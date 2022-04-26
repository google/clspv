; RUN: clspv-opt %s --passes=scalarize -o %t.ll -hack-phis
; RUN: FileCheck %s < %t.ll
; RUN: clspv-opt %s --passes=scalarize,rewrite-inserts-pass -hack-phis -o %t2.ll
; RUN: FileCheck --check-prefix=CONSTRUCT %s < %t2.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%t = type { i32, i32 }
%s = type { i32, %t }

define void @constant_struct(%s %in) {
entry:
  br i1 undef, label %if, label %exit

if:
  br label %exit

exit:
  %phi = phi %s [ %in, %entry ], [ { i32 1, %t { i32 0, i32 2 } }, %if ]
  ret void
}

; CHECK: entry:
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue %s %in, 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue %s %in, 1
; CHECK: [[ex10:%[a-zA-Z0-9_.]+]] = extractvalue %t [[ex1]], 0
; CHECK: [[ex11:%[a-zA-Z0-9_.]+]] = extractvalue %t [[ex1]], 1
; CHECK: exit:
; CHECK-NOT: phi %s
; CHECK: [[phi0:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex0]], %entry ], [ 1, %if ]
; CHECK: [[phi10:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex10]], %entry ], [ 0, %if ]
; CHECK: [[phi11:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex11]], %entry ], [ 2, %if ]
; CHECK: [[in10:%[a-zA-Z0-9_.]+]] = insertvalue %t zeroinitializer, i32 [[phi10]], 0
; CHECK: [[in11:%[a-zA-Z0-9_.]+]] = insertvalue %t [[in10]], i32 [[phi11]], 1
; CHECK: [[in:%[a-zA-Z0-9_.]+]] = insertvalue %s zeroinitializer, i32 [[phi0]], 0
; CHECK:  insertvalue %s [[in]], %t [[in11]], 1

; CONSTRUCT: entry:
; CONSTRUCT: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue %s %in, 0
; CONSTRUCT: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue %s %in, 1
; CONSTRUCT: [[ex10:%[a-zA-Z0-9_.]+]] = extractvalue %t [[ex1]], 0
; CONSTRUCT: [[ex11:%[a-zA-Z0-9_.]+]] = extractvalue %t [[ex1]], 1
; CONSTRUCT: exit:
; CONSTRUCT-NOT: phi %s
; CONSTRUCT: [[phi0:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex0]], %entry ], [ 1, %if ]
; CONSTRUCT: [[phi10:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex10]], %entry ], [ 0, %if ]
; CONSTRUCT: [[phi11:%[a-zA-Z0-9_.]+]] = phi i32 [ [[ex11]], %entry ], [ 2, %if ]
; CONSTRUCT: [[con1:%[a-zA-Z0-9_.]+]] = call %t @_Z25clspv.composite_construct.0(i32 [[phi10]], i32 [[phi11]])
; CONSTRUCT: [[con2:%[a-zA-Z0-9_.]+]] = call %s @_Z25clspv.composite_construct.1(i32 [[phi0]], %t [[con1]])

