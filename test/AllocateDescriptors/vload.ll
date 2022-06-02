; RUN: clspv-opt -opaque-pointers %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i8] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i8] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i16] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x i16] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.4(i32 0, i32 4, i32 0, i32 4, i32 4, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.5(i32 0, i32 5, i32 0, i32 5, i32 5, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.6(i32 0, i32 6, i32 0, i32 6, i32 6, i32 0, { [0 x i64] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.7(i32 0, i32 7, i32 0, i32 7, i32 7, i32 0, { [0 x i64] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.8(i32 0, i32 8, i32 0, i32 8, i32 8, i32 0, { [0 x half] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.9(i32 0, i32 9, i32 0, i32 9, i32 9, i32 0, { [0 x half] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.10(i32 0, i32 10, i32 0, i32 10, i32 10, i32 0, { [0 x float] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.11(i32 0, i32 11, i32 0, i32 11, i32 11, i32 0, { [0 x double] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 1 %a, ptr addrspace(1) align 1 %b, ptr addrspace(1) align 2 %c, ptr addrspace(1) align 2 %d, ptr addrspace(1) align 4 %e, ptr addrspace(1) align 4 %f, ptr addrspace(1) align 8 %g, ptr addrspace(1) align 8 %h, ptr addrspace(1) align 2 %i1, ptr addrspace(1) align 2 %i2, ptr addrspace(1) align 4 %j, ptr addrspace(1) align 8 %k) !clspv.pod_args_impl !7 {
entry:
  %call = call spir_func <2 x i8> @_Z6vload2jPU3AS1Kh(i32 0, ptr addrspace(1) %a)
  %call1 = call spir_func <3 x i8> @_Z6vload3jPU3AS1Kc(i32 0, ptr addrspace(1) %b)
  %call2 = call spir_func <4 x i16> @_Z6vload4jPU3AS1Kt(i32 0, ptr addrspace(1) %c)
  %call3 = call spir_func <8 x i16> @_Z6vload8jPU3AS1Ks(i32 0, ptr addrspace(1) %d)
  %call4 = call spir_func <16 x i32> @_Z7vload16jPU3AS1Kj(i32 0, ptr addrspace(1) %e)
  %call5 = call spir_func <2 x i32> @_Z6vload2jPU3AS1Ki(i32 0, ptr addrspace(1) %f)
  %call6 = call spir_func <3 x i64> @_Z6vload3jPU3AS1Km(i32 0, ptr addrspace(1) %g)
  %call7 = call spir_func <4 x i64> @_Z6vload4jPU3AS1Kl(i32 0, ptr addrspace(1) %h)
  %call8 = call spir_func <8 x float> @_Z11vload_half8jPU3AS1KDh(i32 0, ptr addrspace(1) %i1)
  %call9 = call spir_func <16 x float> @_Z13vloada_half16jPU3AS1KDh(i32 0, ptr addrspace(1) %i2)
  %call10 = call spir_func <2 x float> @_Z6vload2jPU3AS1Kf(i32 0, ptr addrspace(1) %j)
  %call11 = call spir_func <3 x double> @_Z6vload3jPU3AS1Kd(i32 0, ptr addrspace(1) %k)
  ret void
}

declare spir_func <2 x i8> @_Z6vload2jPU3AS1Kh(i32, ptr addrspace(1))
declare spir_func <3 x i8> @_Z6vload3jPU3AS1Kc(i32, ptr addrspace(1))
declare spir_func <4 x i16> @_Z6vload4jPU3AS1Kt(i32, ptr addrspace(1))
declare spir_func <8 x i16> @_Z6vload8jPU3AS1Ks(i32, ptr addrspace(1))
declare spir_func <16 x i32> @_Z7vload16jPU3AS1Kj(i32, ptr addrspace(1))
declare spir_func <2 x i32> @_Z6vload2jPU3AS1Ki(i32, ptr addrspace(1))
declare spir_func <3 x i64> @_Z6vload3jPU3AS1Km(i32, ptr addrspace(1))
declare spir_func <4 x i64> @_Z6vload4jPU3AS1Kl(i32, ptr addrspace(1))
declare spir_func <8 x float> @_Z11vload_half8jPU3AS1KDh(i32, ptr addrspace(1))
declare spir_func <16 x float> @_Z13vloada_half16jPU3AS1KDh(i32, ptr addrspace(1))
declare spir_func <2 x float> @_Z6vload2jPU3AS1Kf(i32, ptr addrspace(1))
declare spir_func <3 x double> @_Z6vload3jPU3AS1Kd(i32, ptr addrspace(1))

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 15.0.0 (https://github.com/llvm/llvm-project 64c85742099d4de14f18167249fc0f40c10b9782)"}
!3 = !{i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1}
!4 = !{!"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none"}
!5 = !{!"uchar*", !"char*", !"ushort*", !"short*", !"uint*", !"int*", !"ulong*", !"long*", !"half*", !"half*", !"float*", !"double*"}
!6 = !{!"", !"", !"", !"", !"", !"", !"", !"", !"", !"", !"", !""}
!7 = !{i32 1}

