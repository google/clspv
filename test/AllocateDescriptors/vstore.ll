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
  call spir_func void @_Z7vstore2Dv2_hjPU3AS1h(<2 x i8> zeroinitializer, i32 0, ptr addrspace(1) %a)
  call spir_func void @_Z7vstore3Dv3_cjPU3AS1c(<3 x i8> zeroinitializer, i32 0, ptr addrspace(1) %b)
  call spir_func void @_Z7vstore4Dv4_tjPU3AS1t(<4 x i16> zeroinitializer, i32 0, ptr addrspace(1) %c)
  call spir_func void @_Z7vstore8Dv8_sjPU3AS1s(<8 x i16> zeroinitializer, i32 0, ptr addrspace(1) %d)
  call spir_func void @_Z8vstore16Dv16_jjPU3AS1j(<16 x i32> zeroinitializer, i32 0, ptr addrspace(1) %e)
  call spir_func void @_Z7vstore2Dv2_ijPU3AS1i(<2 x i32> zeroinitializer, i32 0, ptr addrspace(1) %f)
  call spir_func void @_Z7vstore3Dv3_mjPU3AS1m(<3 x i64> zeroinitializer, i32 0, ptr addrspace(1) %g)
  call spir_func void @_Z7vstore4Dv4_ljPU3AS1l(<4 x i64> zeroinitializer, i32 0, ptr addrspace(1) %h)
  call spir_func void @_Z12vstore_half8Dv8_fjPU3AS1Dh(<8 x float> zeroinitializer, i32 0, ptr addrspace(1) %i1)
  call spir_func void @_Z14vstorea_half16Dv16_fjPU3AS1Dh(<16 x float> zeroinitializer, i32 0, ptr addrspace(1) %i2)
  call spir_func void @_Z7vstore2Dv2_fjPU3AS1f(<2 x float> zeroinitializer, i32 0, ptr addrspace(1) %j)
  call spir_func void @_Z7vstore3Dv3_djPU3AS1d(<3 x double> zeroinitializer, i32 0, ptr addrspace(1) %k)
  ret void
}

declare spir_func void @_Z7vstore2Dv2_hjPU3AS1h(<2 x i8>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore3Dv3_cjPU3AS1c(<3 x i8>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore4Dv4_tjPU3AS1t(<4 x i16>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore8Dv8_sjPU3AS1s(<8 x i16>, i32, ptr addrspace(1))
declare spir_func void @_Z8vstore16Dv16_jjPU3AS1j(<16 x i32>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore2Dv2_ijPU3AS1i(<2 x i32>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore3Dv3_mjPU3AS1m(<3 x i64>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore4Dv4_ljPU3AS1l(<4 x i64>, i32, ptr addrspace(1))
declare spir_func void @_Z12vstore_half8Dv8_fjPU3AS1Dh(<8 x float>, i32, ptr addrspace(1))
declare spir_func void @_Z14vstorea_half16Dv16_fjPU3AS1Dh(<16 x float>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore2Dv2_fjPU3AS1f(<2 x float>, i32, ptr addrspace(1))
declare spir_func void @_Z7vstore3Dv3_djPU3AS1d(<3 x double>, i32, ptr addrspace(1))

!7 = !{i32 1}

