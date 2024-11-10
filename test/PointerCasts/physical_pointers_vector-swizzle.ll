; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { %1 }
%1 = type { i32, i32, i32, i32 }

; CHECK: test_vector_swizzle_xyzw
; CHECK: [[ptr_id:%[^ ]+]] = inttoptr i64 %b to ptr addrspace(1), !clspv.pointer_from_pod !2
; CHECK: [[load:%[^ ]+]] = load <4 x i8>, ptr addrspace(1) [[ptr_id]], align 4
; CHECK: [[gep_st:%[^ ]+]] = getelementptr <4 x i8>, ptr addrspace(1) [[ptr_id]], i32 1
; CHECK: store i32 %a, ptr addrspace(1) [[gep_st]], align 4

define spir_kernel void @test_vector_swizzle_xyzw(i32 %a, i64 %b) local_unnamed_addr !kernel_arg_type !0 !kernel_arg_base_type !1 {
entry:
  %0 = inttoptr i64 %b to ptr addrspace(1), !clspv.pointer_from_pod !2
  %1 = trunc i32 %a to i8
  %2 = load <4 x i8>, ptr addrspace(1) %0, align 4
  %3 = insertelement <4 x i8> %2, i8 %1, i64 0
  store <4 x i8> %3, ptr addrspace(1) %0, align 4
  %4 = getelementptr i32, ptr addrspace(1) %0, i32 1
  store i32 %a, ptr addrspace(1) %4, align 4
  ret void
}

!0 = !{!"char4", !"char4*"}
!1 = !{!"char __attribute__((ext_vector_type(4)))", !"char __attribute__((ext_vector_type(4)))*"}
!2 = !{}
