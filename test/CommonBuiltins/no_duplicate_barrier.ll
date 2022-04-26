; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

; CHECK: noduplicate
; CHECK-NEXT: spirv.op.224.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@foo.localmem_A = internal addrspace(3) global [16 x i32] undef, align 4
@__spirv_LocalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupId = addrspace(5) global <3 x i32> zeroinitializer

; Function Attrs: convergent nounwind
define spir_kernel void @foo(i32 addrspace(1)* %out) #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 !reqd_work_group_size !7 {
entry:
  %out.addr = alloca i32 addrspace(1)*, align 4
  store i32 addrspace(1)* null, i32 addrspace(1)** %out.addr
  %lid = alloca i32, align 4
  store i32 0, i32* %lid
  store i32 addrspace(1)* %out, i32 addrspace(1)** %out.addr, align 4
  %0 = load i32, i32 addrspace(5)* getelementptr (<3 x i32>, <3 x i32> addrspace(5)* @__spirv_LocalInvocationId, i32 0, i32 0)
  store i32 %0, i32* %lid, align 4
  %1 = load i32, i32* %lid, align 4
  %cmp = icmp eq i32 %1, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %2 = load i32, i32 addrspace(5)* getelementptr (<3 x i32>, <3 x i32> addrspace(5)* @__spirv_WorkgroupId, i32 0, i32 0)
  %3 = load i32, i32* %lid, align 4
  %arrayidx = getelementptr inbounds [16 x i32], [16 x i32] addrspace(3)* @foo.localmem_A, i32 0, i32 %3
  store i32 %2, i32 addrspace(3)* %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  call spir_func void @_Z7barrierj(i32 1) #2
  %4 = load i32, i32* %lid, align 4
  %cmp2 = icmp eq i32 %4, 0
  br i1 %cmp2, label %if.then3, label %if.end6

if.then3:                                         ; preds = %if.end
  %5 = load i32, i32 addrspace(3)* getelementptr inbounds ([16 x i32], [16 x i32] addrspace(3)* @foo.localmem_A, i32 0, i32 0), align 4
  %6 = load i32 addrspace(1)*, i32 addrspace(1)** %out.addr, align 4
  %7 = load i32, i32 addrspace(5)* getelementptr (<3 x i32>, <3 x i32> addrspace(5)* @__spirv_WorkgroupId, i32 0, i32 0)
  %arrayidx5 = getelementptr inbounds i32, i32 addrspace(1)* %6, i32 %7
  store i32 %5, i32 addrspace(1)* %arrayidx5, align 4
  br label %if.end6

if.end6:                                          ; preds = %if.then3, %if.end
  ret void
}

; Function Attrs: convergent
declare spir_func void @_Z7barrierj(i32) #1

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { convergent "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { convergent nobuiltin }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 9.0.0 (https://github.com/llvm-mirror/clang 151e674ab9981c986990e45c8a0a97815cac2021) (https://github.com/llvm-mirror/llvm 86b49e2b741eec98bc7afc6e075ace823e616f50)"}
!3 = !{i32 1}
!4 = !{!"none"}
!5 = !{!"int*"}
!6 = !{!""}
!7 = !{i32 16, i32 1, i32 1}

