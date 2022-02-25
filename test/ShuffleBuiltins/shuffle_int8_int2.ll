; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x i32> %src, <2 x i32> addrspace(1)* noundef align 32 %dst, <2 x i32> %mask) {
entry:
  %0 = call spir_func <2 x i32> @_Z7shuffleDv8_iDv2_j(<8 x i32> %src, <2 x i32> %mask)
  store <2 x i32> %0, <2 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <2 x i32> @_Z7shuffleDv8_iDv2_j(<8 x i32> noundef, <2 x i32> noundef)

; CHECK: [[_src0:%[^ ]+]] = extractvalue [8 x i32] %src, 0
; CHECK: [[_srci0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[_src0]], 0
; CHECK: [[_src1:%[^ ]+]] = extractvalue [8 x i32] %src, 1
; CHECK: [[_srci1:%[^ ]+]] = insertvalue [8 x i32] [[_srci0]], i32 [[_src1]], 1
; CHECK: [[_src2:%[^ ]+]] = extractvalue [8 x i32] %src, 2
; CHECK: [[_srci2:%[^ ]+]] = insertvalue [8 x i32] [[_srci1]], i32 [[_src2]], 2
; CHECK: [[_src3:%[^ ]+]] = extractvalue [8 x i32] %src, 3
; CHECK: [[_srci3:%[^ ]+]] = insertvalue [8 x i32] [[_srci2]], i32 [[_src3]], 3
; CHECK: [[_src4:%[^ ]+]] = extractvalue [8 x i32] %src, 4
; CHECK: [[_srci4:%[^ ]+]] = insertvalue [8 x i32] [[_srci3]], i32 [[_src4]], 4
; CHECK: [[_src5:%[^ ]+]] = extractvalue [8 x i32] %src, 5
; CHECK: [[_srci5:%[^ ]+]] = insertvalue [8 x i32] [[_srci4]], i32 [[_src5]], 5
; CHECK: [[_src6:%[^ ]+]] = extractvalue [8 x i32] %src, 6
; CHECK: [[_srci6:%[^ ]+]] = insertvalue [8 x i32] [[_srci5]], i32 [[_src6]], 6
; CHECK: [[_src7:%[^ ]+]] = extractvalue [8 x i32] %src, 7
; CHECK: [[_srci7:%[^ ]+]] = insertvalue [8 x i32] [[_srci6]], i32 [[_src7]], 7

; CHECK: [[src_alloca:%[^ ]+]] = alloca [8 x i32], align 4
; CHECK: [[_srcii0:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 0
; CHECK: [[srcGep0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 0
; CHECK: store i32 [[_srcii0]], i32* [[srcGep0]], align 4
; CHECK: [[_srcii1:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 1
; CHECK: [[srcGep1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 1
; CHECK: store i32 [[_srcii1]], i32* [[srcGep1]], align 4
; CHECK: [[_srcii2:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 2
; CHECK: [[srcGep2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 2
; CHECK: store i32 [[_srcii2]], i32* [[srcGep2]], align 4
; CHECK: [[_srcii3:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 3
; CHECK: [[srcGep3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 3
; CHECK: store i32 [[_srcii3]], i32* [[srcGep3]], align 4
; CHECK: [[_srcii4:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 4
; CHECK: [[srcGep4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 4
; CHECK: store i32 [[_srcii4]], i32* [[srcGep4]], align 4
; CHECK: [[_srcii5:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 5
; CHECK: [[srcGep5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 5
; CHECK: store i32 [[_srcii5]], i32* [[srcGep5]], align 4
; CHECK: [[_srcii6:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 6
; CHECK: [[srcGep6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 6
; CHECK: store i32 [[_srcii6]], i32* [[srcGep6]], align 4
; CHECK: [[_srcii7:%[^ ]+]] = extractvalue [8 x i32] [[_srci7]], 7
; CHECK: [[srcGep7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 7
; CHECK: store i32 [[_srcii7]], i32* [[srcGep7]], align 4

; CHECK: [[mask0:%[^ ]+]] = extractelement <2 x i32> %mask, i64 0
; CHECK: [[srcGepi0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask0]]
; CHECK: [[src0:%[^ ]+]] = load i32, i32* [[srcGepi0]], align 4
; CHECK: [[res0:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[src0]], i64 0

; CHECK: [[mask1:%[^ ]+]] = extractelement <2 x i32> %mask, i64 1
; CHECK: [[srcGepi1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask1]]
; CHECK: [[src1:%[^ ]+]] = load i32, i32* [[srcGepi1]], align 4
; CHECK: [[res1:%[^ ]+]] = insertelement <2 x i32> [[res0]], i32 [[src1]], i64 1

; CHECK: store <2 x i32> [[res1]], <2 x i32> addrspace(1)* %dst, align 32
