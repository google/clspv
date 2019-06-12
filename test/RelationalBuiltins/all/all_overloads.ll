; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent nounwind
define void @test() {
entry:
  %call = tail call spir_func i32 @_Z3allc(i8 signext 10) #3
  %call1 = tail call spir_func i32 @_Z3allDv2_c(<2 x i8> <i8 10, i8 10>) #3
  %call2 = tail call spir_func i32 @_Z3allDv3_c(<3 x i8> <i8 10, i8 10, i8 10>) #3
  %call3 = tail call spir_func i32 @_Z3allDv4_c(<4 x i8> <i8 10, i8 10, i8 10, i8 10>) #3
  %call4 = tail call spir_func i32 @_Z3alls(i16 signext 10) #3
  %call5 = tail call spir_func i32 @_Z3allDv2_s(<2 x i16> <i16 10, i16 10>) #3
  %call6 = tail call spir_func i32 @_Z3allDv3_s(<3 x i16> <i16 10, i16 10, i16 10>) #3
  %call7 = tail call spir_func i32 @_Z3allDv4_s(<4 x i16> <i16 10, i16 10, i16 10, i16 10>) #3
  %call8 = tail call spir_func i32 @_Z3alli(i32 10) #3
  %call9 = tail call spir_func i32 @_Z3allDv2_i(<2 x i32> <i32 10, i32 10>) #3
  %call10 = tail call spir_func i32 @_Z3allDv3_i(<3 x i32> <i32 10, i32 10, i32 10>) #3
  %call11 = tail call spir_func i32 @_Z3allDv4_i(<4 x i32> <i32 10, i32 10, i32 10, i32 10>) #3
  %call12 = tail call spir_func i32 @_Z3alll(i64 10) #3
  %call13 = tail call spir_func i32 @_Z3allDv2_l(<2 x i64> <i64 10, i64 10>) #3
  %call14 = tail call spir_func i32 @_Z3allDv3_l(<3 x i64> <i64 10, i64 10, i64 10>) #3
  %call15 = tail call spir_func i32 @_Z3allDv4_l(<4 x i64> <i64 10, i64 10, i64 10, i64 10>) #3
  ret void
}

; Function Attrs: argmemonly nounwind

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allc(i8 signext) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv2_c(<2 x i8>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv3_c(<3 x i8>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv4_c(<4 x i8>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3alls(i16 signext) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv2_s(<2 x i16>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv3_s(<3 x i16>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv4_s(<4 x i16>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3alli(i32) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv2_i(<2 x i32>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv3_i(<3 x i32>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv4_i(<4 x i32>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3alll(i64) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv2_l(<2 x i64>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv3_l(<3 x i64>) local_unnamed_addr #2

; Function Attrs: convergent nounwind readnone
declare spir_func i32 @_Z3allDv4_l(<4 x i64>) local_unnamed_addr #2

; CHECK: call i1 @spirv.op.155.Dv2_b(i32 155, <2 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv3_b(i32 155, <3 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv4_b(i32 155, <4 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv2_b(i32 155, <2 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv3_b(i32 155, <3 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv4_b(i32 155, <4 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv2_b(i32 155, <2 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv3_b(i32 155, <3 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv4_b(i32 155, <4 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv2_b(i32 155, <2 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv3_b(i32 155, <3 x i1> %{{[0-9]+}})
; CHECK: call i1 @spirv.op.155.Dv4_b(i32 155, <4 x i1> %{{[0-9]+}})
