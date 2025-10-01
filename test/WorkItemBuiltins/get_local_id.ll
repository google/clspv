; RUN: clspv-opt %s -o %t.ll --passes=define-opencl-workitem-builtins,early-cse
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func i32 @_Z12get_local_idj(i32 3)
; CHECK: call spir_func i32 @_Z12get_local_idj(i32 %b)

; CHECK: define spir_func i32 @_Z12get_local_idj(i32 [[p:%[0-9]+]])
; CHECK: [[cmp:%[0-9]+]] = icmp ult i32 [[p]], 3
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 [[p]], i32 0
; CHECK: [[gep:%[0-9]+]] = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_LocalInvocationId, i32 0, i32 [[sel]]
; CHECK: [[ld:%[0-9]+]] = load i32, ptr addrspace(5) [[gep]]
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 [[ld]], i32 0
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @foo(ptr addrspace(1) align 4 %a, i32 %b) #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 !reqd_work_group_size !8 !clspv.pod_args_impl !9 {
entry:
  %a.addr = alloca ptr, align 4, addrspace(1)
  store ptr addrspace(1) null, ptr addrspace(1) %a.addr, align 4
  %b.addr = alloca i32, align 4
  store i32 0, i32* %b.addr, align 4
  store ptr addrspace(1) %a, ptr addrspace(1) %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  %call = call spir_func i32 @_Z12get_local_idj(i32 3) #2
  %0 = load ptr addrspace(1), ptr addrspace(1) %a.addr, align 4
  %1 = load i32, i32* %b.addr, align 4
  %call1 = call spir_func i32 @_Z12get_local_idj(i32 %1) #2
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %0, i32 %call1
  store i32 %call, ptr addrspace(1) %arrayidx, align 4
  ret void
}

; Function Attrs: convergent nounwind readnone willreturn
declare spir_func i32 @_Z12get_local_idj(i32) #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind readnone willreturn "frame-pointer"="none" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind readnone willreturn "no-builtins" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}
!llvm.ident = !{!2, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 15.0.0 (https://github.com/llvm/llvm-project cc03414125d234da80e9b445909568b065c7f2a6)"}
!3 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!4 = !{i32 1, i32 0}
!5 = !{!"none", !"none"}
!6 = !{!"uint*", !"uint"}
!7 = !{!"", !""}
!8 = !{i32 1, i32 1, i32 1}
!9 = !{i32 2}

