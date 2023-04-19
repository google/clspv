; RUN: clspv-opt --passes=lower-addrspacecast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-NOT: addrspacecast
; CHECK: icmp eq ptr addrspace(1) %in, null
; CHECK: [[gep:%[^ ]+]] = getelementptr inbounds float, ptr addrspace(1) %in
; CHECK: load float, ptr addrspace(1) [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @k(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out) #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  %1 = load i32, ptr addrspace(9) @__push_constants, align 16
  %2 = call i32 @clspv.wrap_constant_load.0(i32 %1) #2
  %3 = add i32 %0, %2
  %4 = addrspacecast ptr addrspace(1) %in to ptr addrspace(4)
  br label %for.cond.i

for.cond.i:                                       ; preds = %if.end.i, %entry
  %j.0.i = phi i32 [ 0, %entry ], [ %inc.i, %if.end.i ]
  %res.0.i = phi float [ 0.000000e+00, %entry ], [ %add.i, %if.end.i ]
  %cmp.i = icmp ult i32 %j.0.i, %3
  br i1 %cmp.i, label %for.body.i, label %_Z4loopPU3AS4Kfj.exit

for.body.i:                                       ; preds = %for.cond.i
  %tobool.not.i = icmp eq ptr addrspace(4) %4, null
  br i1 %tobool.not.i, label %if.then.i, label %if.end.i

if.then.i:                                        ; preds = %for.body.i
  br label %_Z4loopPU3AS4Kfj.exit

if.end.i:                                         ; preds = %for.body.i
  %arrayidx.i = getelementptr inbounds float, ptr addrspace(4) %4, i32 %j.0.i
  %5 = load float, ptr addrspace(4) %arrayidx.i, align 4
  %add.i = fadd float %res.0.i, %5
  %inc.i = add i32 %j.0.i, 1
  br label %for.cond.i, !llvm.loop !12

_Z4loopPU3AS4Kfj.exit:                            ; preds = %for.cond.i, %if.then.i
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 %3
  store float %res.0.i, ptr addrspace(1) %arrayidx, align 4
  ret void
}

; Function Attrs: memory(read)
declare i32 @clspv.wrap_constant_load.0(i32) #1

attributes #0 = { convergent mustprogress norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { memory(read) }
attributes #2 = { nounwind }

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
!7 = !{i32 1, i32 1}
!8 = !{!"none", !"none"}
!9 = !{!"float*", !"float*"}
!10 = !{!"", !""}
!11 = !{i32 3}
!12 = distinct !{!12, !13}
!13 = !{!"llvm.loop.mustprogress"}
