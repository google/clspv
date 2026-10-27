; RUN: clspv-opt %s -o %t.ll --passes=lower-private-pointer-phi
; RUN: FileCheck %s < %t.ll

; %a, %b and %c are merged into a single alloca, as the PHI can point to any of
; them through the select. Offsets are in units of float.

; CHECK: [[alloca:%[^ ]+]] = alloca [3 x <2 x float>], align 16
; CHECK: [[select:%[^ ]+]] = select i1 %c0, i32 0, i32 2
; CHECK: then:
; CHECK: exit:
; CHECK-NEXT: [[phi:%[^ ]+]] = phi i32 [ [[select]], %entry ], [ 4, %then ]
; CHECK-NEXT: [[add:%[^ ]+]] = add i32 [[phi]], 1
; CHECK-NEXT: [[idx:%[^ ]+]] = lshr i32 [[add]], 1
; CHECK-NEXT: [[ele:%[^ ]+]] = and i32 [[add]], 1
; CHECK-NEXT: [[gep:%[^ ]+]] = getelementptr inbounds [3 x <2 x float>], ptr [[alloca]], i32 0, i32 [[idx]], i32 [[ele]]
; CHECK-NEXT: load float, ptr [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define void @test(ptr addrspace(1) %out, i1 %c0, i1 %c1) {
entry:
  %a = alloca <2 x float>, align 8
  %b = alloca <2 x float>, align 16
  %c = alloca <2 x float>, align 8
  store <2 x float> zeroinitializer, ptr %a, align 8
  store <2 x float> <float 1.0, float 1.0>, ptr %b, align 8
  store <2 x float> <float 2.0, float 2.0>, ptr %c, align 8
  %ab = select i1 %c0, ptr %a, ptr %b
  br i1 %c1, label %then, label %exit

then:
  br label %exit

exit:
  %ptr = phi ptr [ %ab, %entry ], [ %c, %then ]
  %y = getelementptr <2 x float>, ptr %ptr, i32 0, i32 1
  %ld = load float, ptr %y, align 4
  store float %ld, ptr addrspace(1) %out, align 4
  ret void
}
