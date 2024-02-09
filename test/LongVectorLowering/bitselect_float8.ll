; RUN: clspv-opt %s -o %t.ll --long-vector --passes=long-vector-lowering
; RUN: FileCheck %s < %t.ll

; CHECK-COUNT-8: extractvalue [8 x float]
; CHECK-COUNT-8: bitcast float %{{.*}} to i32
; CHECK-COUNT-8: xor i32 %{{.*}}, -1
; CHECK-COUNT-8: and i32
; CHECK-COUNT-8: and i32
; CHECK-COUNT-8: or i32
; CHECK-COUNT-8: bitcast i32 %{{.*}} to float

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @test(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 4 %b, ptr addrspace(1) align 4 %c, ptr addrspace(1) align 4 %d, { i32 } %podargs) !clspv.pod_args_impl !13 !kernel_arg_map !14 {
entry:
  %x = extractvalue { i32 } %podargs, 0
  %arrayidx.i = getelementptr inbounds <8 x float>, ptr addrspace(1) %a, i32 %x
  %0 = load <8 x float>, ptr addrspace(1) %arrayidx.i, align 4
  %arrayidx1.i = getelementptr inbounds <8 x float>, ptr addrspace(1) %b, i32 %x
  %1 = load <8 x float>, ptr addrspace(1) %arrayidx1.i, align 4
  %arrayidx2.i = getelementptr inbounds <8 x float>, ptr addrspace(1) %c, i32 %x
  %2 = load <8 x float>, ptr addrspace(1) %arrayidx2.i, align 4
  %3 = bitcast <8 x float> %2 to <8 x i32>
  %4 = bitcast <8 x float> %0 to <8 x i32>
  %5 = bitcast <8 x float> %1 to <8 x i32>
  %6 = xor <8 x i32> %3, <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>
  %7 = and <8 x i32> %6, %4
  %8 = and <8 x i32> %3, %5
  %9 = or <8 x i32> %7, %8
  %10 = bitcast <8 x i32> %9 to <8 x float>
  %arrayidx3.i = getelementptr inbounds <8 x float>, ptr addrspace(1) %d, i32 %x
  store <8 x float> %10, ptr addrspace(1) %arrayidx3.i, align 4
  ret void
}

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !5, !5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 19.0.0git (https://github.com/llvm/llvm-project d5a3de4aeef4f4f1c52692533ddb9fdf45aef9d3)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!7 = !{!"test", !" kernel"}
!8 = !{i32 1, i32 1, i32 1, i32 1, i32 0}
!9 = !{!"none", !"none", !"none", !"none", !"none"}
!10 = !{!"float*", !"float*", !"float*", !"float*", !"int"}
!11 = !{!"", !"", !"", !"", !""}
!12 = !{!"a", !"b", !"c", !"d", !"x"}
!13 = !{i32 2}
!14 = !{!15, !16, !17, !18, !19}
!15 = !{!"a", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!16 = !{!"b", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!17 = !{!"c", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!18 = !{!"d", i32 3, i32 3, i32 0, i32 0, !"buffer"}
!19 = !{!"x", i32 4, i32 4, i32 0, i32 4, !"pod_pushconstant"}

