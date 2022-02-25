; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<2 x i32> %srcA, <2 x i32> %srcB, <8 x i32> addrspace(1)* noundef align 32 %dst, <8 x i32> %mask) {
entry:
  %0 = call spir_func <8 x i32> @_Z8shuffle2Dv2_iS_Dv8_j(<2 x i32> %srcA, <2 x i32> %srcB, <8 x i32> %mask)
  store <8 x i32> %0, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z8shuffle2Dv2_iS_Dv8_j(<2 x i32> noundef, <2 x i32> noundef, <8 x i32> noundef)

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

; CHECK: [[mask0:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 0
; CHECK: [[mask0mod:%[^ ]+]] = urem i32 [[mask0]], 2
; CHECK: [[srcA0:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask0]]
; CHECK: [[srcB0:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask0mod]]
; CHECK: [[cmp0:%[^ ]+]] = icmp sge i32 [[mask0]], 2
; CHECK: [[val0:%[^ ]+]] = select i1 [[cmp0]], i32 [[srcB0]], i32 [[srcA0]]
; CHECK: [[res0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[val0]], 0

; CHECK: [[mask1:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 1
; CHECK: [[mask1mod:%[^ ]+]] = urem i32 [[mask1]], 2
; CHECK: [[srcA1:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask1]]
; CHECK: [[srcB1:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask1mod]]
; CHECK: [[cmp1:%[^ ]+]] = icmp sge i32 [[mask1]], 2
; CHECK: [[val1:%[^ ]+]] = select i1 [[cmp1]], i32 [[srcB1]], i32 [[srcA1]]
; CHECK: [[res1:%[^ ]+]] = insertvalue [8 x i32] [[res0]], i32 [[val1]], 1

; CHECK: [[mask2:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 2
; CHECK: [[mask2mod:%[^ ]+]] = urem i32 [[mask2]], 2
; CHECK: [[srcA2:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask2]]
; CHECK: [[srcB2:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask2mod]]
; CHECK: [[cmp2:%[^ ]+]] = icmp sge i32 [[mask2]], 2
; CHECK: [[val2:%[^ ]+]] = select i1 [[cmp2]], i32 [[srcB2]], i32 [[srcA2]]
; CHECK: [[res2:%[^ ]+]] = insertvalue [8 x i32] [[res1]], i32 [[val2]], 2

; CHECK: [[mask3:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 3
; CHECK: [[mask3mod:%[^ ]+]] = urem i32 [[mask3]], 2
; CHECK: [[srcA3:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask3]]
; CHECK: [[srcB3:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask3mod]]
; CHECK: [[cmp3:%[^ ]+]] = icmp sge i32 [[mask3]], 2
; CHECK: [[val3:%[^ ]+]] = select i1 [[cmp3]], i32 [[srcB3]], i32 [[srcA3]]
; CHECK: [[res3:%[^ ]+]] = insertvalue [8 x i32] [[res2]], i32 [[val3]], 3

; CHECK: [[mask4:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 4
; CHECK: [[mask4mod:%[^ ]+]] = urem i32 [[mask4]], 2
; CHECK: [[srcA4:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask4]]
; CHECK: [[srcB4:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask4mod]]
; CHECK: [[cmp4:%[^ ]+]] = icmp sge i32 [[mask4]], 2
; CHECK: [[val4:%[^ ]+]] = select i1 [[cmp4]], i32 [[srcB4]], i32 [[srcA4]]
; CHECK: [[res4:%[^ ]+]] = insertvalue [8 x i32] [[res3]], i32 [[val4]], 4

; CHECK: [[mask5:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 5
; CHECK: [[mask5mod:%[^ ]+]] = urem i32 [[mask5]], 2
; CHECK: [[srcA5:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask5]]
; CHECK: [[srcB5:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask5mod]]
; CHECK: [[cmp5:%[^ ]+]] = icmp sge i32 [[mask5]], 2
; CHECK: [[val5:%[^ ]+]] = select i1 [[cmp5]], i32 [[srcB5]], i32 [[srcA5]]
; CHECK: [[res5:%[^ ]+]] = insertvalue [8 x i32] [[res4]], i32 [[val5]], 5

; CHECK: [[mask6:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 6
; CHECK: [[mask6mod:%[^ ]+]] = urem i32 [[mask6]], 2
; CHECK: [[srcA6:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask6]]
; CHECK: [[srcB6:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask6mod]]
; CHECK: [[cmp6:%[^ ]+]] = icmp sge i32 [[mask6]], 2
; CHECK: [[val6:%[^ ]+]] = select i1 [[cmp6]], i32 [[srcB6]], i32 [[srcA6]]
; CHECK: [[res6:%[^ ]+]] = insertvalue [8 x i32] [[res5]], i32 [[val6]], 6

; CHECK: [[mask7:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 7
; CHECK: [[mask7mod:%[^ ]+]] = urem i32 [[mask7]], 2
; CHECK: [[srcA7:%[^ ]+]] = extractelement <2 x i32> %srcA, i32 [[mask7]]
; CHECK: [[srcB7:%[^ ]+]] = extractelement <2 x i32> %srcB, i32 [[mask7mod]]
; CHECK: [[cmp7:%[^ ]+]] = icmp sge i32 [[mask7]], 2
; CHECK: [[val7:%[^ ]+]] = select i1 [[cmp7]], i32 [[srcB7]], i32 [[srcA7]]
; CHECK: [[res7:%[^ ]+]] = insertvalue [8 x i32] [[res6]], i32 [[val7]], 7

; CHECK: store [8 x i32] [[res7]], [8 x i32] addrspace(1)* %dst, align 32
