; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.4(i32 0, i32 4, i32 0, i32 4, i32 4, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.5(i32 0, i32 5, i32 0, i32 5, i32 5, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.6(i32 0, i32 6, i32 0, i32 6, i32 6, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.7(i32 0, i32 7, i32 0, i32 7, i32 7, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.8(i32 0, i32 8, i32 0, i32 8, i32 8, i32 0, { [0 x i32] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @atomicTest(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 4 %b, ptr addrspace(1) align 4 %c, ptr addrspace(1) align 4 %d, ptr addrspace(1) align 4 %e, ptr addrspace(1) align 4 %f, ptr addrspace(1) align 4 %g, ptr addrspace(1) align 4 %h, ptr addrspace(1) align 4 %i) !clspv.pod_args_impl !11 {
entry:
  %0 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 234, ptr addrspace(1) %a, i32 1, i32 72, i32 1)
  %1 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 235, ptr addrspace(1) %b, i32 1, i32 72, i32 1)
  %2 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 236, ptr addrspace(1) %c, i32 1, i32 72, i32 1)
  %3 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 237, ptr addrspace(1) %d, i32 1, i32 72, i32 1)
  %4 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 238, ptr addrspace(1) %e, i32 1, i32 72, i32 1)
  %5 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 239, ptr addrspace(1) %f, i32 1, i32 72, i32 1)
  %6 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 240, ptr addrspace(1) %g, i32 1, i32 72, i32 1)
  %7 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 241, ptr addrspace(1) %h, i32 1, i32 72, i32 1)
  %8 = tail call i32 @_Z8spirv.op.234.PU3AS1jjj(i32 242, ptr addrspace(1) %i, i32 1, i32 72, i32 1)
  ret void
}

declare i32 @_Z8spirv.op.234.PU3AS1jjj(i32 %0, ptr addrspace(1) %1, i32 %2, i32 %3, i32 %4) local_unnamed_addr

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 2, i32 0}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 37def00806187ccc4cf3d7e210d6f305278d1e6d)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!6 = !{i32 1}
!7 = !{!"none"}
!8 = !{!"atomic_int*"}
!9 = !{!"_Atomic(int)*"}
!10 = !{!""}
!11 = !{i32 2}

