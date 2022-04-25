; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x i32> %src, <8 x i32> addrspace(1)* noundef align 32 %dst, <8 x i32> %mask) {
entry:
  %0 = call spir_func <8 x i32> @_Z7shuffleDv8_iDv8_j(<8 x i32> %src, <8 x i32> %mask)
  store <8 x i32> %0, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z7shuffleDv8_iDv8_j(<8 x i32> noundef, <8 x i32> noundef)

; CHECK: [[src_alloca:%[^ ]+]] = alloca [8 x i32], align 4

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

; CHECK: [[_mask0:%[^ ]+]] = extractvalue [8 x i32] %mask, 0
; CHECK: [[_maski0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[_mask0]], 0
; CHECK: [[_mask1:%[^ ]+]] = extractvalue [8 x i32] %mask, 1
; CHECK: [[_maski1:%[^ ]+]] = insertvalue [8 x i32] [[_maski0]], i32 [[_mask1]], 1
; CHECK: [[_mask2:%[^ ]+]] = extractvalue [8 x i32] %mask, 2
; CHECK: [[_maski2:%[^ ]+]] = insertvalue [8 x i32] [[_maski1]], i32 [[_mask2]], 2
; CHECK: [[_mask3:%[^ ]+]] = extractvalue [8 x i32] %mask, 3
; CHECK: [[_maski3:%[^ ]+]] = insertvalue [8 x i32] [[_maski2]], i32 [[_mask3]], 3
; CHECK: [[_mask4:%[^ ]+]] = extractvalue [8 x i32] %mask, 4
; CHECK: [[_maski4:%[^ ]+]] = insertvalue [8 x i32] [[_maski3]], i32 [[_mask4]], 4
; CHECK: [[_mask5:%[^ ]+]] = extractvalue [8 x i32] %mask, 5
; CHECK: [[_maski5:%[^ ]+]] = insertvalue [8 x i32] [[_maski4]], i32 [[_mask5]], 5
; CHECK: [[_mask6:%[^ ]+]] = extractvalue [8 x i32] %mask, 6
; CHECK: [[_maski6:%[^ ]+]] = insertvalue [8 x i32] [[_maski5]], i32 [[_mask6]], 6
; CHECK: [[_mask7:%[^ ]+]] = extractvalue [8 x i32] %mask, 7
; CHECK: [[mask:%[^ ]+]] = insertvalue [8 x i32] [[_maski6]], i32 [[_mask7]], 7

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

; CHECK: [[mask0:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 0
; CHECK: [[mask0mod:%[^ ]+]] = urem i32 [[mask0]], 8
; CHECK: [[srcGepi0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask0mod]]
; CHECK: [[src0:%[^ ]+]] = load i32, i32* [[srcGepi0]], align 4
; CHECK: [[res0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[src0]], 0

; CHECK: [[mask1:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 1
; CHECK: [[mask1mod:%[^ ]+]] = urem i32 [[mask1]], 8
; CHECK: [[srcGepi1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask1mod]]
; CHECK: [[src1:%[^ ]+]] = load i32, i32* [[srcGepi1]], align 4
; CHECK: [[res1:%[^ ]+]] = insertvalue [8 x i32] [[res0]], i32 [[src1]], 1

; CHECK: [[mask2:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 2
; CHECK: [[mask2mod:%[^ ]+]] = urem i32 [[mask2]], 8
; CHECK: [[srcGepi2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask2mod]]
; CHECK: [[src2:%[^ ]+]] = load i32, i32* [[srcGepi2]], align 4
; CHECK: [[res2:%[^ ]+]] = insertvalue [8 x i32] [[res1]], i32 [[src2]], 2

; CHECK: [[mask3:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 3
; CHECK: [[mask3mod:%[^ ]+]] = urem i32 [[mask3]], 8
; CHECK: [[srcGepi3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask3mod]]
; CHECK: [[src3:%[^ ]+]] = load i32, i32* [[srcGepi3]], align 4
; CHECK: [[res3:%[^ ]+]] = insertvalue [8 x i32] [[res2]], i32 [[src3]], 3

; CHECK: [[mask4:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 4
; CHECK: [[mask4mod:%[^ ]+]] = urem i32 [[mask4]], 8
; CHECK: [[srcGepi4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask4mod]]
; CHECK: [[src4:%[^ ]+]] = load i32, i32* [[srcGepi4]], align 4
; CHECK: [[res4:%[^ ]+]] = insertvalue [8 x i32] [[res3]], i32 [[src4]], 4

; CHECK: [[mask5:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 5
; CHECK: [[mask5mod:%[^ ]+]] = urem i32 [[mask5]], 8
; CHECK: [[srcGepi5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask5mod]]
; CHECK: [[src5:%[^ ]+]] = load i32, i32* [[srcGepi5]], align 4
; CHECK: [[res5:%[^ ]+]] = insertvalue [8 x i32] [[res4]], i32 [[src5]], 5

; CHECK: [[mask6:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 6
; CHECK: [[mask6mod:%[^ ]+]] = urem i32 [[mask6]], 8
; CHECK: [[srcGepi6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask6mod]]
; CHECK: [[src6:%[^ ]+]] = load i32, i32* [[srcGepi6]], align 4
; CHECK: [[res6:%[^ ]+]] = insertvalue [8 x i32] [[res5]], i32 [[src6]], 6

; CHECK: [[mask7:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 7
; CHECK: [[mask7mod:%[^ ]+]] = urem i32 [[mask7]], 8
; CHECK: [[srcGepi7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[src_alloca]], i32 0, i32 [[mask7mod]]
; CHECK: [[src7:%[^ ]+]] = load i32, i32* [[srcGepi7]], align 4
; CHECK: [[res7:%[^ ]+]] = insertvalue [8 x i32] [[res6]], i32 [[src7]], 7

; CHECK: store [8 x i32] [[res7]], [8 x i32] addrspace(1)* %dst, align 32
