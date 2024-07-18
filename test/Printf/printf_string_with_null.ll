; RUN: clspv-opt %s -o %t.ll --passes=printf-pass
; RUN: FileCheck %s < %t.ll

; CHECK: !clspv.printf_metadata = !{![[FMT:[0-9]+]], ![[LITERAL:[0-9]+]]}
; CHECK: ![[FMT]] = !{i32 0, !"%s\00",
; CHECK: ![[LITERAL]] = !{i32 1, !"foo\00foo\00",

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@.str = private unnamed_addr addrspace(2) constant [3 x i8] c"%s\00", align 1
@.str.1 = private unnamed_addr addrspace(2) constant [8 x i8] c"foo\00foo\00", align 1
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @m() #0 !kernel_arg_addr_space !6 !kernel_arg_access_qual !6 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !6 !kernel_arg_name !6 !clspv.pod_args_impl !7 {
entry:
  %call = call spir_func i32 (ptr addrspace(2), ...) @printf(ptr addrspace(2) @.str, ptr addrspace(2) @.str.1) #2
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !8 spir_func i32 @printf(ptr addrspace(2), ...) #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!_Z28clspv.entry_point_attributes = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 19.0.0git (https://github.com/llvm/llvm-project 402eca265f7162e26b8b74d18297fd76c9f100de)"}
!5 = !{!"m", !"kernel"}
!6 = !{}
!7 = !{i32 2}
!8 = !{!""}
