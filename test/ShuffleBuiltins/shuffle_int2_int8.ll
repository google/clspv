; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<2 x i32> %src, ptr addrspace(1) noundef align 32 %dst, <8 x i32> %mask) {
entry:
  %0 = call spir_func <8 x i32> @_Z7shuffleDv2_iDv8_j(<2 x i32> %src, <8 x i32> %mask)
  store <8 x i32> %0, ptr addrspace(1) %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z7shuffleDv2_iDv8_j(<2 x i32> noundef, <8 x i32> noundef)

; CHECK: [[_mask0:%[^ ]+]] = extractvalue [8 x i32] %mask, 0
; CHECK: [[_maski0:%[^ ]+]] = insertvalue [8 x i32] poison, i32 [[_mask0]], 0
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

; CHECK: [[mask0:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 0
; CHECK: [[mask0mod:%[^ ]+]] = urem i32 [[mask0]], 2
; CHECK: [[src0:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask0mod]]
; CHECK: [[res0:%[^ ]+]] = insertvalue [8 x i32] poison, i32 [[src0]], 0

; CHECK: [[mask1:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 1
; CHECK: [[mask1mod:%[^ ]+]] = urem i32 [[mask1]], 2
; CHECK: [[src1:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask1mod]]
; CHECK: [[res1:%[^ ]+]] = insertvalue [8 x i32] [[res0]], i32 [[src1]], 1

; CHECK: [[mask2:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 2
; CHECK: [[mask2mod:%[^ ]+]] = urem i32 [[mask2]], 2
; CHECK: [[src2:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask2mod]]
; CHECK: [[res2:%[^ ]+]] = insertvalue [8 x i32] [[res1]], i32 [[src2]], 2

; CHECK: [[mask3:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 3
; CHECK: [[mask3mod:%[^ ]+]] = urem i32 [[mask3]], 2
; CHECK: [[src3:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask3mod]]
; CHECK: [[res3:%[^ ]+]] = insertvalue [8 x i32] [[res2]], i32 [[src3]], 3

; CHECK: [[mask4:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 4
; CHECK: [[mask4mod:%[^ ]+]] = urem i32 [[mask4]], 2
; CHECK: [[src4:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask4mod]]
; CHECK: [[res4:%[^ ]+]] = insertvalue [8 x i32] [[res3]], i32 [[src4]], 4

; CHECK: [[mask5:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 5
; CHECK: [[mask5mod:%[^ ]+]] = urem i32 [[mask5]], 2
; CHECK: [[src5:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask5mod]]
; CHECK: [[res5:%[^ ]+]] = insertvalue [8 x i32] [[res4]], i32 [[src5]], 5

; CHECK: [[mask6:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 6
; CHECK: [[mask6mod:%[^ ]+]] = urem i32 [[mask6]], 2
; CHECK: [[src6:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask6mod]]
; CHECK: [[res6:%[^ ]+]] = insertvalue [8 x i32] [[res5]], i32 [[src6]], 6

; CHECK: [[mask7:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 7
; CHECK: [[mask7mod:%[^ ]+]] = urem i32 [[mask7]], 2
; CHECK: [[src7:%[^ ]+]] = extractelement <2 x i32> %src, i32 [[mask7mod]]
; CHECK: [[res7:%[^ ]+]] = insertvalue [8 x i32] [[res6]], i32 [[src7]], 7

; CHECK: store [8 x i32] [[res7]], ptr addrspace(1) %dst, align 32
