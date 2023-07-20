; RUN: clspv-opt %s -o %t.ll --passes=printf-pass
; RUN: FileCheck %s < %t.ll

; CHECK: define i32 @__clspv.printf.0(ptr addrspace(1) [[ptr:%[^ ]+]])
; CHECK: [[ptrtoint:%[^ ]+]] = ptrtoint ptr addrspace(1) [[ptr]] to i64
; CHECK: store i64 [[ptrtoint]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { i64, i64 }

@.str = private unnamed_addr addrspace(2) constant [4 x i8] c"%p\0A\00", align 1
@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test11(ptr addrspace(1) align 4 %x, ptr addrspace(1) align 8 %xAddr) #0 !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !12 !kernel_arg_type_qual !13 !kernel_arg_name !14 !clspv.pod_args_impl !15 {
entry:
  %x.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %x.addr, align 8
  %xAddr.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %xAddr.addr, align 8
  store ptr addrspace(1) %x, ptr %x.addr, align 8
  store ptr addrspace(1) %xAddr, ptr %xAddr.addr, align 8
  %0 = load ptr addrspace(1), ptr %x.addr, align 8
  %call = call spir_func i32 (ptr addrspace(2), ...) @printf(ptr addrspace(2) @.str, ptr addrspace(1) %0) #2
  %1 = load ptr addrspace(1), ptr %x.addr, align 8
  %2 = ptrtoint ptr addrspace(1) %1 to i64
  %3 = load ptr addrspace(1), ptr %xAddr.addr, align 8
  store i64 %2, ptr addrspace(1) %3, align 8
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !16 spir_func i32 @printf(ptr addrspace(2), ...) #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7}
!_Z28clspv.entry_point_attributes = !{!8}

!0 = !{i32 9, i32 10}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 3, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!8 = !{!"test11", !" __kernel"}
!9 = !{i32 1, i32 1}
!10 = !{!"none", !"none"}
!11 = !{!"int*", !"intptr_t*"}
!12 = !{!"int*", !"long*"}
!13 = !{!"", !""}
!14 = !{!"x", !"xAddr"}
!15 = !{i32 3}
!16 = !{!""}
