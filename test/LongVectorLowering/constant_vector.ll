; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test(<8 x float>* %src, <16 x float>* %dst) {
entry:
  %0 = load <8 x float>, <8 x float>* %src, align 32
  %1 = shufflevector <8 x float> %0, <8 x float> <float 0.000000e+00, float undef, float undef, float undef, float undef, float undef, float undef, float undef>, <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 0, i32 0, i32 1, i32 2, i32 3, i32 4, i32 5>
  store <16 x float> %1, <16 x float>* %dst, align 32
  ret void
}

; CHECK: [[load:%[^ ]+]] = load [8 x float], [8 x float]* %src, align 32
; CHECK: [[ld0:%[^ ]+]] = extractvalue [8 x float] [[load]], 0
; CHECK: [[ins0:%[^ ]+]] = insertvalue [16 x float] undef, float [[ld0]], 0
; CHECK: [[ld1:%[^ ]+]] = extractvalue [8 x float] [[load]], 1
; CHECK: [[ins1:%[^ ]+]] = insertvalue [16 x float] [[ins0]], float [[ld1]], 1
; CHECK: [[ld2:%[^ ]+]] = extractvalue [8 x float] [[load]], 2
; CHECK: [[ins2:%[^ ]+]] = insertvalue [16 x float] [[ins1]], float [[ld2]], 2
; CHECK: [[ld3:%[^ ]+]] = extractvalue [8 x float] [[load]], 3
; CHECK: [[ins3:%[^ ]+]] = insertvalue [16 x float] [[ins2]], float [[ld3]], 3
; CHECK: [[ld4:%[^ ]+]] = extractvalue [8 x float] [[load]], 4
; CHECK: [[ins4:%[^ ]+]] = insertvalue [16 x float] [[ins3]], float [[ld4]], 4
; CHECK: [[ld5:%[^ ]+]] = extractvalue [8 x float] [[load]], 5
; CHECK: [[ins5:%[^ ]+]] = insertvalue [16 x float] [[ins4]], float [[ld5]], 5
; CHECK: [[ld6:%[^ ]+]] = extractvalue [8 x float] [[load]], 6
; CHECK: [[ins6:%[^ ]+]] = insertvalue [16 x float] [[ins5]], float [[ld6]], 6
; CHECK: [[ld7:%[^ ]+]] = extractvalue [8 x float] [[load]], 7
; CHECK: [[ins7:%[^ ]+]] = insertvalue [16 x float] [[ins6]], float [[ld7]], 7
; CHECK: [[ins8:%[^ ]+]] = insertvalue [16 x float] [[ins7]], float 0.000000e+00, 8
; CHECK: [[ld0:%[^ ]+]] = extractvalue [8 x float] [[load]], 0
; CHECK: [[ins9:%[^ ]+]] = insertvalue [16 x float] [[ins8]], float [[ld0]], 9
; CHECK: [[ld0:%[^ ]+]] = extractvalue [8 x float] [[load]], 0
; CHECK: [[ins10:%[^ ]+]] = insertvalue [16 x float] [[ins9]], float [[ld0]], 10
; CHECK: [[ld1:%[^ ]+]] = extractvalue [8 x float] [[load]], 1
; CHECK: [[ins11:%[^ ]+]] = insertvalue [16 x float] [[ins10]], float [[ld1]], 11
; CHECK: [[ld2:%[^ ]+]] = extractvalue [8 x float] [[load]], 2
; CHECK: [[ins12:%[^ ]+]] = insertvalue [16 x float] [[ins11]], float [[ld2]], 12
; CHECK: [[ld3:%[^ ]+]] = extractvalue [8 x float] [[load]], 3
; CHECK: [[ins13:%[^ ]+]] = insertvalue [16 x float] [[ins12]], float [[ld3]], 13
; CHECK: [[ld4:%[^ ]+]] = extractvalue [8 x float] [[load]], 4
; CHECK: [[ins14:%[^ ]+]] = insertvalue [16 x float] [[ins13]], float [[ld4]], 14
; CHECK: [[ld5:%[^ ]+]] = extractvalue [8 x float] [[load]], 5
; CHECK: [[ins15:%[^ ]+]] = insertvalue [16 x float] [[ins14]], float [[ld5]], 15
