; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-NOT: call spirv_func ptr @__to_private
; CHECK: addrspacecast ptr addrspace(4) {{.*}} to ptr
; CHECK-NOT: call spirv_func ptr @__to_private

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_func float @_Z4loopPU3AS4Kfj(ptr addrspace(4) %data, i32 %num) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %j.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %res.0 = phi float [ 0.000000e+00, %entry ], [ %add, %for.inc ]
  %cmp = icmp ult i32 %j.0, %num
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %0 = call spir_func ptr @__to_private(ptr addrspace(4) %data)
  %arrayidx = getelementptr inbounds float, ptr %0, i32 %j.0
  %1 = load float, ptr %arrayidx, align 4
  %add = fadd float %res.0, %1
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %inc = add i32 %j.0, 1
  br label %for.cond, !llvm.loop !7

for.end:                                          ; preds = %for.cond
  ret float %res.0
}

declare spir_func ptr @__to_private(ptr addrspace(4))

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @k(ptr addrspace(1) align 4 %out) #1 !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !clspv.pod_args_impl !13 {
entry:
  %in = alloca [128 x float], align 4
  store [128 x float] zeroinitializer, ptr %in, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) @__push_constants, align 4
  %2 = add i32 %0, %1
  %arraydecay = getelementptr inbounds [128 x float], ptr %in, i32 0, i32 0
  %arraydecay.ascast = addrspacecast ptr %arraydecay to ptr addrspace(4)
  %call1 = call spir_func float @_Z4loopPU3AS4Kfj(ptr addrspace(4) %arraydecay.ascast, i32 %2) #2
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 %2
  store float %call1, ptr addrspace(1) %arrayidx, align 4
  ret void
}

attributes #0 = { convergent mustprogress norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #1 = { convergent mustprogress norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #2 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 2, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project be3764fecc263f7180bfada7ac61c5f8d799610e)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = distinct !{!7, !8}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{i32 1}
!10 = !{!"none"}
!11 = !{!"float*"}
!12 = !{!""}
!13 = !{i32 3}
