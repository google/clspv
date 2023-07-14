; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x <2 x float>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x <3 x float>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x <4 x float>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.4(i32 0, i32 4, i32 0, i32 4, i32 4, i32 0, { [0 x <8 x float>] } zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.5(i32 0, i32 5, i32 0, i32 5, i32 5, i32 0, { [0 x <16 x float>] } zeroinitializer)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @test(ptr addrspace(1) align 4 %a, ptr addrspace(1) align 8 %b, ptr addrspace(1) align 16 %c, ptr addrspace(1) align 16 %d, ptr addrspace(1) align 32 %e, ptr addrspace(1) align 64 %f) !clspv.pod_args_impl !8 {
entry:
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %a, i32 0
  %0 = load float, ptr addrspace(1) %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds float, ptr addrspace(1) %a, i32 1
  %call = call spir_func float @_Z5fractfPU3AS1f(float %0, ptr addrspace(1) %arrayidx1)
  %arrayidx2 = getelementptr inbounds <2 x float>, ptr addrspace(1) %b, i32 0
  %1 = load <2 x float>, ptr addrspace(1) %arrayidx2, align 8
  %arrayidx3 = getelementptr inbounds <2 x float>, ptr addrspace(1) %b, i32 1
  %call4 = call spir_func <2 x float> @_Z5fractDv2_fPU3AS1S_(<2 x float> %1, ptr addrspace(1) %arrayidx3)
  %arrayidx5 = getelementptr inbounds <3 x float>, ptr addrspace(1) %c, i32 0
  %2 = load <3 x float>, ptr addrspace(1) %arrayidx5, align 16
  %arrayidx6 = getelementptr inbounds <3 x float>, ptr addrspace(1) %c, i32 1
  %call7 = call spir_func <3 x float> @_Z5fractDv3_fPU3AS1S_(<3 x float> %2, ptr addrspace(1) %arrayidx6)
  %arrayidx8 = getelementptr inbounds <4 x float>, ptr addrspace(1) %d, i32 0
  %3 = load <4 x float>, ptr addrspace(1) %arrayidx8, align 16
  %arrayidx9 = getelementptr inbounds <4 x float>, ptr addrspace(1) %d, i32 1
  %call10 = call spir_func <4 x float> @_Z5fractDv4_fPU3AS1S_(<4 x float> %3, ptr addrspace(1) %arrayidx9)
  %arrayidx11 = getelementptr inbounds <8 x float>, ptr addrspace(1) %e, i32 0
  %4 = load <8 x float>, ptr addrspace(1) %arrayidx11, align 32
  %arrayidx12 = getelementptr inbounds <8 x float>, ptr addrspace(1) %e, i32 1
  %call13 = call spir_func <8 x float> @_Z5fractDv8_fPU3AS1S_(<8 x float> %4, ptr addrspace(1) %arrayidx12)
  %arrayidx14 = getelementptr inbounds <16 x float>, ptr addrspace(1) %f, i32 0
  %5 = load <16 x float>, ptr addrspace(1) %arrayidx14, align 64
  %arrayidx15 = getelementptr inbounds <16 x float>, ptr addrspace(1) %f, i32 1
  %call16 = call spir_func <16 x float> @_Z5fractDv16_fPU3AS1S_(<16 x float> %5, ptr addrspace(1) %arrayidx15)
  ret void
}

declare spir_func float @_Z5fractfPU3AS1f(float, ptr addrspace(1))
declare spir_func <2 x float> @_Z5fractDv2_fPU3AS1S_(<2 x float>, ptr addrspace(1))
declare spir_func <3 x float> @_Z5fractDv3_fPU3AS1S_(<3 x float>, ptr addrspace(1))
declare spir_func <4 x float> @_Z5fractDv4_fPU3AS1S_(<4 x float>, ptr addrspace(1))
declare spir_func <8 x float> @_Z5fractDv8_fPU3AS1S_(<8 x float>, ptr addrspace(1))
declare spir_func <16 x float> @_Z5fractDv16_fPU3AS1S_(<16 x float>, ptr addrspace(1))

!8 = !{i32 1}

