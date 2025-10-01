; RUN: clspv-opt %s -o %t.ll --passes=define-opencl-workitem-builtins,early-cse
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func i32 @_Z15get_global_sizej(i32 3)
; CHECK: call spir_func i32 @_Z15get_global_sizej(i32 %b)

; CHECK: define spir_func i32 @_Z15get_global_sizej(i32 [[p:%[0-9]+]]
; CHECK: [[cmp:%[0-9]+]] = icmp ult i32 [[p]], 3
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 [[p]], i32 0
; CHECK: [[gep:%[0-9]+]] = getelementptr <3 x i32>, ptr addrspace(8) @__spirv_WorkgroupSize, i32 0, i32 [[sel]]
; CHECK: [[ld1:%[0-9]+]] = load i32, ptr addrspace(8) [[gep]]
; CHECK: [[gep:%[0-9]+]] = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_NumWorkgroups, i32 0, i32 [[sel]]
; CHECK: [[ld2:%[0-9]+]] = load i32, ptr addrspace(5) [[gep]]
; CHECK: [[mul:%[0-9]+]] = mul i32 [[ld1]], [[ld2]]
; CHECK: [[sel:%[0-9]+]] = select i1 [[cmp]], i32 [[mul]], i32 1
; CHECK: ret i32 [[sel]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(ptr addrspace(1) align 4 %a, i32 %b) #0 !reqd_work_group_size !8 !clspv.pod_args_impl !9 {
entry:
  %a.addr = alloca ptr, align 4, addrspace(1)
  store ptr addrspace(1) null, ptr addrspace(1) %a.addr, align 4
  %b.addr = alloca i32, align 4
  store i32 0, i32* %b.addr, align 4
  store ptr addrspace(1) %a, ptr addrspace(1) %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  %call = call spir_func i32 @_Z15get_global_sizej(i32 3) #2
  %0 = load ptr addrspace(1), ptr addrspace(1) %a.addr, align 4
  %1 = load i32, i32* %b.addr, align 4
  %call1 = call spir_func i32 @_Z15get_global_sizej(i32 %1) #2
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %0, i32 %call1
  store i32 %call, ptr addrspace(1) %arrayidx, align 4
  ret void
}

declare spir_func i32 @_Z15get_global_sizej(i32) #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind readnone willreturn "frame-pointer"="none" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind readnone willreturn "no-builtins" }

!8 = !{i32 1, i32 1, i32 1}
!9 = !{i32 2}

