; RUN: clspv-opt %s -o %t.ll --passes=share-module-scope-vars
; RUN: FileCheck %s < %t.ll

; CHECK: @foo.buffer = internal unnamed_addr addrspace(3) global [128 x i32] undef, align 4
; CHECK: @bar.buffer = internal unnamed_addr addrspace(3) global [128 x i8] undef, align 1

; CHECK: getelementptr inbounds [128 x i32], ptr addrspace(3) @foo.buffer
; CHECK: getelementptr inbounds [128 x i32], ptr addrspace(3) @foo.buffer

; CHECK: getelementptr inbounds [128 x i8], ptr addrspace(3) @bar.buffer
; CHECK: getelementptr inbounds [128 x i8], ptr addrspace(3) @bar.buffer

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@foo.buffer = internal unnamed_addr addrspace(3) global [128 x i32] undef, align 4
@bar.buffer = internal unnamed_addr addrspace(3) global [128 x i8] undef, align 1
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture align 4 %tab) local_unnamed_addr #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %1 = load i32, ptr addrspace(5) %0, align 16
  %2 = getelementptr %0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0
  %3 = load i32, ptr addrspace(9) %2, align 16
  %4 = add i32 %3, %1
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %tab, i32 %4
  %5 = load i32, ptr addrspace(1) %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds [128 x i32], ptr addrspace(3) @foo.buffer, i32 0, i32 %4
  store i32 %5, ptr addrspace(3) %arrayidx1, align 4
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #2
  %add = add i32 %4, 1
  %arrayidx2 = getelementptr inbounds [128 x i32], ptr addrspace(3) @foo.buffer, i32 0, i32 %add
  %6 = load i32, ptr addrspace(3) %arrayidx2, align 4
  store i32 %6, ptr addrspace(1) %arrayidx, align 4
  ret void
}

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @bar(ptr addrspace(1) nocapture align 1 %tab) local_unnamed_addr #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !12 !kernel_arg_base_type !12 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 0
  %1 = load i32, ptr addrspace(5) %0, align 16
  %2 = getelementptr %0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0
  %3 = load i32, ptr addrspace(9) %2, align 16
  %4 = add i32 %3, %1
  %arrayidx = getelementptr inbounds i8, ptr addrspace(1) %tab, i32 %4
  %5 = load i8, ptr addrspace(1) %arrayidx, align 1
  %arrayidx1 = getelementptr inbounds [128 x i8], ptr addrspace(3) @bar.buffer, i32 0, i32 %4
  store i8 %5, ptr addrspace(3) %arrayidx1, align 1
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #2
  %add = add i32 %4, 1
  %arrayidx2 = getelementptr inbounds [128 x i8], ptr addrspace(3) @bar.buffer, i32 0, i32 %add
  %6 = load i8, ptr addrspace(3) %arrayidx2, align 1
  store i8 %6, ptr addrspace(1) %arrayidx, align 1
  ret void
}

; Function Attrs: convergent noduplicate
declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) local_unnamed_addr #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent noduplicate }
attributes #2 = { nounwind }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 1, i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 3, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project e64fbf2cca8c4763a058ba59a48ab8e4b8193028)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = !{i32 1}
!8 = !{!"none"}
!9 = !{!"int*"}
!10 = !{!""}
!11 = !{i32 3}
!12 = !{!"char*"}
