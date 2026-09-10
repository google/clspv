; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 1, { [0 x i32] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress norecurse nounwind willreturn denormal_fpenv(dynamic)
define spir_kernel void @test(ptr addrspace(1) nofree align 4 %data, ptr addrspace(1) nofree align 4 captures(none) %a) local_unnamed_addr #0 !kernel_arg_addr_space !0 !kernel_arg_access_qual !1 !kernel_arg_type !2 !kernel_arg_base_type !2 !kernel_arg_type_qual !3 !kernel_arg_name !76 !clspv.pod_args_impl !77 {
entry:
  %0 = load i32, ptr addrspace(1) %data, align 4
  %1 = atomicrmw and ptr addrspace(1) %a, i32 1 acquire, align 4
  %arrayidx1.i123456 = getelementptr i32, ptr addrspace(1) %data, i32 1
  store i32 %0, ptr addrspace(1) %arrayidx1.i123456, align 4
  ret void
}

attributes #0 = { mustprogress norecurse nounwind willreturn denormal_fpenv(dynamic) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }

!opencl.ocl.version = !{!4}
!llvm.ident = !{!5}
!llvm.errno.tbaa = !{!10}
!llvm.module.flags = !{!11, !12, !13}
!_Z28clspv.entry_point_attributes = !{!74, !75}

!0 = !{i32 1, i32 1}
!1 = !{!"none", !"none"}
!2 = !{!"int*", !"int*"}
!3 = !{!"", !""}
!4 = !{i32 3, i32 0}
!5 = !{!"clang version 24.0.0git (https://github.com/llvm/llvm-project 7c0969c0842a1b19bcffd8bf3b67a76badb2c431)"}
!6 = !{!"Simple C/C++ TBAA"}
!7 = !{!"omnipotent char", !6, i64 0}
!8 = !{!"int", !7, i64 0}
!9 = !{!"__libc_errno", !8, i64 0}
!10 = !{!9, !8, i64 0}
!11 = !{i32 7, !"frame-pointer", i32 2}
!12 = !{i32 1, !"ThinLTO", i32 0}
!13 = !{i32 1, !"EnableSplitLTOUnit", i32 1}
!74 = !{!"test", !"kernel"}
!75 = !{!"__clang_ocl_kern_imp_test", !"kernel"}
!76 = !{!"data", !"a"}
!77 = !{i32 2}

