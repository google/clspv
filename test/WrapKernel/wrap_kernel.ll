; RUN: clspv-opt %s -o %t.ll --passes=wrap-kernel
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @add(ptr addrspace(1) align 4 %A, ptr addrspace(1) align 4 %B) #2 !kernel_arg_addr_space !15 !kernel_arg_access_qual !16 !kernel_arg_type !17 !kernel_arg_base_type !17 !kernel_arg_type_qual !18 !work_group_size_hint !19 !reqd_work_group_size !19 {
entry:
  %A.addr = alloca ptr addrspace(1), align 4
  %B.addr = alloca ptr addrspace(1), align 4
  %i = alloca i32, align 4
  store ptr addrspace(1) %A, ptr %A.addr, align 4
  store ptr addrspace(1) %B, ptr %B.addr, align 4
  store i32 0, ptr %i, align 4  ret void
}

define dso_local spir_kernel void @main_kernel(ptr addrspace(1) align 4 %A, ptr addrspace(1) align 4 %B) #2 !kernel_arg_addr_space !15 !kernel_arg_access_qual !16 !kernel_arg_type !17 !kernel_arg_base_type !17 !kernel_arg_type_qual !18 {
entry:
  %A.addr = alloca ptr addrspace(1), align 4
  %B.addr = alloca ptr addrspace(1), align 4
  store ptr addrspace(1) %A, ptr %A.addr, align 4
  store ptr addrspace(1) %B, ptr %B.addr, align 4
  %0 = load ptr addrspace(1), ptr %A.addr, align 4
  %1 = load ptr addrspace(1), ptr %B.addr, align 4
  call spir_kernel void @add(ptr addrspace(1) align 4 %0, ptr addrspace(1) align 4 %1) #5
  ret void
}


!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 18.0.0 (https://github.com/llvm/llvm-project c7d65e4466eafe518937c59ef9a242234ed7a08a)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!7 = !{!"_Z4sqrtf", !" __attribute__((overloadable)) __attribute__((const))"}
!8 = !{!"_Z4sqrtDv2_f", !" __attribute__((overloadable)) __attribute__((const))"}
!9 = !{!"_Z4sqrtDv3_f", !" __attr((overloadable)) __attribute__((const))"}
!10 = !{!"_Z4sqrtDv4_f", !" __attribute__((overloadable)) __aibute__ttribute__((const))"}
!11 = !{!"_Z4sqrtDv8_f", !" __attribute__((overloadable)) __attribute__((const))"}
!12 = !{!"_Z4sqrtDv16_f", !" __attribute__((overloadable)) __attribute__((const))"}
!13 = !{!"add", !" __attribute__((work_group_size_hint(1, 1, 1))) __attribute__((reqd_work_group_size(1, 1, 1))) __kernel"}
!14 = !{!"main_kernel", !" kernel"}
!15 = !{i32 1, i32 1}
!16 = !{!"none", !"none"}
!17 = !{!"int*", !"int*"}
!18 = !{!"", !""}
!19 = !{i32 1, i32 1, i32 1}

; CHECK:define dso_local spir_func void @add.inner(ptr addrspace(1) align [[alignment:[0-9]*]] %A, ptr addrspace(1) align [[alignment]] %B)
; CHECK-NEXT: entry:
; CHECK: ret void

; CHECK:  define dso_local spir_kernel void @add(ptr addrspace(1) align [[alignment]] %A, ptr addrspace(1) align [[alignment]] %B) !kernel_arg_addr_space [[args_type:![0-9]*]] !kernel_arg_access_qual [[none:![0-9]*]] !kernel_arg_type [[ptr:![0-9]*]] !kernel_arg_base_type [[ptr]] !kernel_arg_type_qual [[empty:![0-9]*]] !work_group_size_hint [[work_group_hint:![0-9]*]] !reqd_work_group_size [[work_group_hint]]
; CHECK-NEXT: entry:
; CHECK-NEXT: call spir_func void @add.inner(ptr addrspace(1) %A, ptr addrspace(1) %B)
; CHECK: ret void

; CHECK:  define dso_local spir_kernel void @main_kernel(ptr addrspace(1) align [[alignment]] %A, ptr addrspace(1) align [[alignment]] %B) !kernel_arg_addr_space [[args_type]] !kernel_arg_access_qual [[none]] !kernel_arg_type [[ptr]] !kernel_arg_base_type [[ptr]] !kernel_arg_type_qual [[empty]]
; CHECK-NEXT: entry:
; CHECK-DAG: [[paramA:%[a-zA-A0-9_]+]] = load ptr addrspace(1), ptr %A.addr, align [[alignment]]
; CHECK-DAG: [[paramB:%[a-zA-A0-9_]+]] = load ptr addrspace(1), ptr %B.addr, align [[alignment]]
; CHECK: call spir_func void @add.inner(ptr addrspace(1) align [[alignment]] [[paramA]], ptr addrspace(1) align [[alignment]] [[paramB]])
; CHECK ret void

; CHECK: [[args_type]] = !{i32 1, i32 1}
; CHECK: [[none]] = !{!"none", !"none"}
; CHECK: [[ptr]] = !{!"int*", !"int*"}
; CHECK: [[empty]] = !{!"", !""}
; CHECK: [[work_group_hint]] = !{i32 1, i32 1, i32 1}
