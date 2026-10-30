; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-LABEL: define spir_kernel void @test_select(
; CHECK: %[[SEL:[a-zA-Z0-9_]+]] = select i1 %cond, i32 268435460, i32 268435468
; CHECK: store i32 %[[SEL]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_select(ptr addrspace(1) %out, i1 %cond) {
entry:
  %a = alloca [4 x i32], align 4
  %gep1 = getelementptr [4 x i32], ptr %a, i32 0, i32 1
  %gep2 = getelementptr [4 x i32], ptr %a, i32 0, i32 3
  %sel = select i1 %cond, ptr %gep1, ptr %gep2
  %pti = ptrtoint ptr %sel to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_icmp_select_null(
; CHECK: %[[SEL:[a-zA-Z0-9_]+]] = select i1 %cond, i32 {{[-0-9]+}}, i32 0
; CHECK: %[[CMP:[a-zA-Z0-9_]+]] = icmp eq i32 %[[SEL]], 0
; CHECK: %[[RES:[a-zA-Z0-9_]+]] = zext i1 %[[CMP]] to i32
; CHECK: store i32 %[[RES]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_icmp_select_null(ptr addrspace(1) %out, i1 %cond) {
entry:
  %a = alloca [4 x i32], align 4
  %sel = select i1 %cond, ptr %a, ptr null
  %cmp = icmp eq ptr %sel, null
  %res = zext i1 %cmp to i32
  store i32 %res, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_select_null_asc_undef(
; CHECK: %[[SEL1:[a-zA-Z0-9_]+]] = select i1 %c1, i32 0, i32 undef
; CHECK: %[[SEL2:[a-zA-Z0-9_]+]] = select i1 %c2, i32 {{[-0-9]+}}, i32 %[[SEL1]]
; CHECK: store i32 %[[SEL2]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_select_null_asc_undef(ptr addrspace(1) %out, i1 %c1, i1 %c2) {
entry:
  %a = alloca [4 x i32], align 4
  %asc_null = addrspacecast ptr addrspace(4) null to ptr
  %sel1 = select i1 %c1, ptr %asc_null, ptr undef
  %sel2 = select i1 %c2, ptr %a, ptr %sel1
  %pti = ptrtoint ptr %sel2 to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_gep_of_select(
; CHECK: %[[SEL:[a-zA-Z0-9_]+]] = select i1 %cond, i32 {{[-0-9]+}}, i32 {{[-0-9]+}}
; CHECK: %[[ADD_CST:[a-zA-Z0-9_]+]] = add i32 %[[SEL]], 16
; CHECK: %[[MUL_DYN:[a-zA-Z0-9_]+]] = shl i32 %idx, 2
; CHECK: %[[ADD_DYN:[a-zA-Z0-9_]+]] = add i32 %[[ADD_CST]], %[[MUL_DYN]]
; CHECK: store i32 %[[ADD_DYN]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_gep_of_select(ptr addrspace(1) %out, i1 %cond, i32 %idx) {
entry:
  %a = alloca [4 x i32], align 4
  %b = alloca [4 x i32], align 4
  %sel = select i1 %cond, ptr %a, ptr %b
  %gep = getelementptr [4 x i32], ptr %sel, i32 1, i32 %idx
  %pti = ptrtoint ptr %gep to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_phi_dyn_gep(
; CHECK: then:
; CHECK: %[[DYN_MUL:[a-zA-Z0-9_]+]] = shl i32 %idx, 2
; CHECK: %[[DYN_ADDR:[a-zA-Z0-9_]+]] = add i32 {{[-0-9]+}}, %[[DYN_MUL]]
; CHECK: br label %merge
; CHECK: merge:
; CHECK: %[[PHI:[a-zA-Z0-9_]+]] = phi i32 [ %[[DYN_ADDR]], %then ], [ 0, %else ]
; CHECK: store i32 %[[PHI]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_phi_dyn_gep(ptr addrspace(1) %out, i1 %cond, i32 %idx) {
entry:
  %a = alloca [4 x i32], align 4
  br i1 %cond, label %then, label %else

then:
  %gep = getelementptr [4 x i32], ptr %a, i32 0, i32 %idx
  br label %merge

else:
  br label %merge

merge:
  %phi = phi ptr [ %gep, %then ], [ null, %else ]
  %pti = ptrtoint ptr %phi to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_phi_loop(
; CHECK: loop:
; CHECK: %[[PHI:[a-zA-Z0-9_]+]] = phi i32 [ {{[-0-9]+}}, %entry ], [ %[[NEXT:[a-zA-Z0-9_]+]], %loop ]
; CHECK: %[[NEXT]] = add i32 %[[PHI]], 4
; CHECK: exit:
; CHECK: store i32 %[[PHI]], ptr addrspace(1) %out, align 4

define spir_kernel void @test_phi_loop(ptr addrspace(1) %out, i1 %cond) {
entry:
  %a = alloca [4 x i32], align 4
  br label %loop

loop:
  %phi = phi ptr [ %a, %entry ], [ %next, %loop ]
  %next = getelementptr i32, ptr %phi, i32 1
  br i1 %cond, label %loop, label %exit

exit:
  %pti = ptrtoint ptr %phi to i32
  store i32 %pti, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_func i32 @test_unconvertible_bailout(
; CHECK: merge:
; CHECK: %phi = phi ptr [ %arg, %then ], [ %a, %else ]
; CHECK-NOT: phi i32
; CHECK: %pti = ptrtoint ptr %sel to i32
; CHECK: ret i32 %pti

define spir_func i32 @test_unconvertible_bailout(ptr %arg, i1 %cond) {
entry:
  %a = alloca i32, align 4
  br i1 %cond, label %then, label %else

then:
  br label %merge

else:
  br label %merge

merge:
  %phi = phi ptr [ %arg, %then ], [ %a, %else ]
  %sel = select i1 %cond, ptr %a, ptr %phi
  %pti = ptrtoint ptr %sel to i32
  ret i32 %pti
}
