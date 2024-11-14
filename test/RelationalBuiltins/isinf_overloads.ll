; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent nounwind
define spir_func void @test() {
entry:
  %call = tail call spir_func i32 @_Z5isinff(float 0x40035C2900000000) #3
  %call1 = tail call spir_func <2 x i32> @_Z5isinfDv2_f(<2 x float> splat (float 0x40035C2900000000)) #3
  %call2 = tail call spir_func <3 x i32> @_Z5isinfDv3_f(<3 x float> splat (float 0x40035C2900000000)) #3
  %call3 = tail call spir_func <4 x i32> @_Z5isinfDv4_f(<4 x float> splat (float 0x40035C2900000000)) #3
  ret void
}

; Function Attrs: argmemonly nounwind

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z5isinff(float) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func <2 x i32> @_Z5isinfDv2_f(<2 x float>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func <3 x i32> @_Z5isinfDv3_f(<3 x float>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func <4 x i32> @_Z5isinfDv4_f(<4 x float>) local_unnamed_addr #2

; CHECK: call i1 @_Z8spirv.op.157.f(i32 157, float 0x40035C2900000000)
; CHECK: call <2 x i1> @_Z8spirv.op.157.Dv2_f(i32 157, <2 x float> splat (float 0x40035C2900000000))
; CHECK: call <3 x i1> @_Z8spirv.op.157.Dv3_f(i32 157, <3 x float> splat (float 0x40035C2900000000))
; CHECK: call <4 x i1> @_Z8spirv.op.157.Dv4_f(i32 157, <4 x float> splat (float 0x40035C2900000000))
