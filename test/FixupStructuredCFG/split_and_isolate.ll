; RUN: clspv-opt --passes=fixup-structured-cfg %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: for.cond35.i.preheader:
; CHECK-NEXT: br label %[[split1:[a-zA-Z0-9_.]+]]
; CHECK: [[split1]]:
; CHECK-NEXT: br label %for.body38.i
; CHECK: interpolation_func_bicubic.exit27:
; CHECK-NEXT: br i1 undef, label %[[split2:[a-zA-Z0-9_.]+]], label %[[split1]]
; CHECK: [[split2]]:
; CHECK-NEXT: br label %for.end.i

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test() {
entry:
  br i1 undef, label %if.end.i, label %Flow37

if.end.i:
  br i1 undef, label %if.then23.i, label %if.end24.i

if.then23.i:
  br label %if.end24.i

Flow37:
  br label %clip_rotate_bicubic.inner.exit

if.end24.i:
  br label %for.cond35.i.preheader

for.cond35.i.preheader:
  br label %for.body38.i

for.body38.i:
  br i1 undef, label %cond.false.i, label %Flow36

cond.false.i:
  br i1 undef, label %cond.false4.i, label %Flow35

Flow35:
  br i1 undef, label %cond.true2.i, label %cond.end.i

cond.true2.i:
  br label %cond.end.i

cond.false4.i:
  br label %Flow35

Flow36:
  br label %interpolation_func_bicubic.exit

cond.end.i:
  br label %Flow36

interpolation_func_bicubic.exit:
  br i1 undef, label %cond.false4.i15, label %Flow34

cond.false4.i15:
  br i1 undef, label %cond.false4.i22, label %Flow

Flow:
  br i1 undef, label %cond.true2.i19, label %cond.end.i25

cond.true2.i19:
  br label %cond.end.i25

cond.false4.i22:
  br label %Flow

Flow34:
  br label %interpolation_func_bicubic.exit27

cond.end.i25:
  br label %Flow34

interpolation_func_bicubic.exit27:
  br i1 undef, label %for.end.i, label %for.body38.i

for.end.i:
  br i1 undef, label %for.end56.i, label %for.cond35.i.preheader

for.end56.i:
  br i1 undef, label %cond.true67.i, label %cond.end72.i

cond.true67.i:
  br label %cond.end72.i

cond.end72.i:
  br label %Flow37

clip_rotate_bicubic.inner.exit:
  ret void
}
