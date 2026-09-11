; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 1, { [0 x i32] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @test(ptr addrspace(1) nofree align 4 %data, ptr addrspace(1) align 4 %a) local_unnamed_addr #0 !kernel_arg_addr_space !0 !kernel_arg_access_qual !1 !kernel_arg_type !2 !kernel_arg_base_type !3 !kernel_arg_type_qual !4 !kernel_arg_name !77 !clspv.pod_args_impl !79 {
entry:
  %0 = load i32, ptr addrspace(1) %data, align 4
  %1 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 234, ptr addrspace(1) %a, i32 1, i32 72, i32 11) #2
  %arrayidx1.i123456 = getelementptr i32, ptr addrspace(1) %data, i32 1
  store i32 %0, ptr addrspace(1) %arrayidx1.i123456, align 4
  ret void
}

declare i32 @_Z8spirv.op.234.PU3AS1jjj(i32, ptr addrspace(1), i32, i32, i32) local_unnamed_addr #1

attributes #0 = { convergent norecurse nounwind denormal_fpenv(dynamic) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #1 = { convergent }
attributes #2 = { nounwind }

!opencl.ocl.version = !{!5}
!llvm.ident = !{!6}
!llvm.errno.tbaa = !{!11}
!llvm.module.flags = !{!12, !13, !14}
!_Z28clspv.entry_point_attributes = !{!75, !76}

!0 = !{i32 1, i32 1}
!1 = !{!"none", !"none"}
!2 = !{!"int*", !"atomic_int*"}
!3 = !{!"int*", !"_Atomic(int)*"}
!4 = !{!"", !""}
!5 = !{i32 3, i32 0}
!6 = !{!"clang version 24.0.0git (https://github.com/llvm/llvm-project 7c0969c0842a1b19bcffd8bf3b67a76badb2c431)"}
!7 = !{!"Simple C/C++ TBAA"}
!8 = !{!"omnipotent char", !7, i64 0}
!9 = !{!"int", !8, i64 0}
!10 = !{!"__libc_errno", !9, i64 0}
!11 = !{!10, !9, i64 0}
!12 = !{i32 7, !"frame-pointer", i32 2}
!13 = !{i32 1, !"ThinLTO", i32 0}
!14 = !{i32 1, !"EnableSplitLTOUnit", i32 1}
!75 = !{!"test", !"kernel"}
!76 = !{!"__clang_ocl_kern_imp_test", !"kernel"}
!77 = !{!"data", !"a"}
!79 = !{i32 2}

