; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x <2 x i32>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.5(i32 0, i32 5, i32 0, i32 5, i32 5, i32 0, { [0 x <3 x i32>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.7(i32 0, i32 7, i32 0, i32 7, i32 7, i32 0, { [0 x <4 x i32>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.9(i32 0, i32 9, i32 0, i32 9, i32 9, i32 0, { [0 x <8 x i32>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.11(i32 0, i32 11, i32 0, i32 11, i32 11, i32 0, { [0 x <16 x i32>] } zeroinitializer)
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 4 %a2, ptr addrspace(1) align 8 %b, ptr addrspace(1) align 8 %b2, ptr addrspace(1) align 16 %c, ptr addrspace(1) align 16 %c2, ptr addrspace(1) align 16 %d, ptr addrspace(1) align 16 %d2, ptr addrspace(1) align 32 %e, ptr addrspace(1) align 32 %e2, ptr addrspace(1) align 64 %f, ptr addrspace(1) align 64 %f2) !clspv.pod_args_impl !8 {
entry:
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %a, i32 0
  %0 = load float, ptr addrspace(1) %arrayidx, align 4
  %call = call spir_func float @_Z6remquofPU3AS1i(float %0, ptr addrspace(1) %a2)
  %arrayidx1 = getelementptr inbounds <2 x float>, ptr addrspace(1) %b, i32 0
  %1 = load <2 x float>, ptr addrspace(1) %arrayidx1, align 8
  %call2 = call spir_func <2 x float> @_Z6remquoDv2_fPU3AS1Dv2_i(<2 x float> %1, ptr addrspace(1) %b2)
  %arrayidx3 = getelementptr inbounds <3 x float>, ptr addrspace(1) %c, i32 0
  %2 = load <3 x float>, ptr addrspace(1) %arrayidx3, align 16
  %call4 = call spir_func <3 x float> @_Z6remquoDv3_fPU3AS1Dv3_i(<3 x float> %2, ptr addrspace(1) %c2)
  %arrayidx5 = getelementptr inbounds <4 x float>, ptr addrspace(1) %d, i32 0
  %3 = load <4 x float>, ptr addrspace(1) %arrayidx5, align 16
  %call6 = call spir_func <4 x float> @_Z6remquoDv4_fPU3AS1Dv4_i(<4 x float> %3, ptr addrspace(1) %d2)
  %arrayidx7 = getelementptr inbounds <8 x float>, ptr addrspace(1) %e, i32 0
  %4 = load <8 x float>, ptr addrspace(1) %arrayidx7, align 32
  %call8 = call spir_func <8 x float> @_Z6remquoDv8_fPU3AS1Dv8_i(<8 x float> %4, ptr addrspace(1) %e2)
  %arrayidx9 = getelementptr inbounds <16 x float>, ptr addrspace(1) %f, i32 0
  %5 = load <16 x float>, ptr addrspace(1) %arrayidx9, align 64
  %call10 = call spir_func <16 x float> @_Z6remquoDv16_fPU3AS1Dv16_i(<16 x float> %5, ptr addrspace(1) %f2)
  ret void
}

declare spir_func float @_Z6remquofPU3AS1i(float, ptr addrspace(1))
declare spir_func <2 x float> @_Z6remquoDv2_fPU3AS1Dv2_i(<2 x float>, ptr addrspace(1))
declare spir_func <3 x float> @_Z6remquoDv3_fPU3AS1Dv3_i(<3 x float>, ptr addrspace(1))
declare spir_func <4 x float> @_Z6remquoDv4_fPU3AS1Dv4_i(<4 x float>, ptr addrspace(1))
declare spir_func <8 x float> @_Z6remquoDv8_fPU3AS1Dv8_i(<8 x float>, ptr addrspace(1))
declare spir_func <16 x float> @_Z6remquoDv16_fPU3AS1Dv16_i(<16 x float>, ptr addrspace(1))

!8 = !{i32 1}

