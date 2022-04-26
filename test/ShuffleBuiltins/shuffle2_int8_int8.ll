; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x i32> %srcA, <8 x i32> %srcB, <8 x i32> addrspace(1)* noundef align 32 %dst, <8 x i32> %mask) {
entry:
  %0 = call spir_func <8 x i32> @_Z8shuffle2Dv8_iS_Dv8_j(<8 x i32> %srcA, <8 x i32> %srcB, <8 x i32> %mask)
  store <8 x i32> %0, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z8shuffle2Dv8_iS_Dv8_j(<8 x i32> noundef, <8 x i32> noundef, <8 x i32> noundef)

; CHECK: [[srcA_alloca:%[^ ]+]] = alloca [8 x i32], align 4
; CHECK: [[srcB_alloca:%[^ ]+]] = alloca [8 x i32], align 4

; CHECK: [[_srcA0:%[^ ]+]] = extractvalue [8 x i32] %srcA, 0
; CHECK: [[_srcAi0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[_srcA0]], 0
; CHECK: [[_srcA1:%[^ ]+]] = extractvalue [8 x i32] %srcA, 1
; CHECK: [[_srcAi1:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi0]], i32 [[_srcA1]], 1
; CHECK: [[_srcA2:%[^ ]+]] = extractvalue [8 x i32] %srcA, 2
; CHECK: [[_srcAi2:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi1]], i32 [[_srcA2]], 2
; CHECK: [[_srcA3:%[^ ]+]] = extractvalue [8 x i32] %srcA, 3
; CHECK: [[_srcAi3:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi2]], i32 [[_srcA3]], 3
; CHECK: [[_srcA4:%[^ ]+]] = extractvalue [8 x i32] %srcA, 4
; CHECK: [[_srcAi4:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi3]], i32 [[_srcA4]], 4
; CHECK: [[_srcA5:%[^ ]+]] = extractvalue [8 x i32] %srcA, 5
; CHECK: [[_srcAi5:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi4]], i32 [[_srcA5]], 5
; CHECK: [[_srcA6:%[^ ]+]] = extractvalue [8 x i32] %srcA, 6
; CHECK: [[_srcAi6:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi5]], i32 [[_srcA6]], 6
; CHECK: [[_srcA7:%[^ ]+]] = extractvalue [8 x i32] %srcA, 7
; CHECK: [[_srcAi7:%[^ ]+]] = insertvalue [8 x i32] [[_srcAi6]], i32 [[_srcA7]], 7

; CHECK: [[_srcB0:%[^ ]+]] = extractvalue [8 x i32] %srcB, 0
; CHECK: [[_srcBi0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[_srcB0]], 0
; CHECK: [[_srcB1:%[^ ]+]] = extractvalue [8 x i32] %srcB, 1
; CHECK: [[_srcBi1:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi0]], i32 [[_srcB1]], 1
; CHECK: [[_srcB2:%[^ ]+]] = extractvalue [8 x i32] %srcB, 2
; CHECK: [[_srcBi2:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi1]], i32 [[_srcB2]], 2
; CHECK: [[_srcB3:%[^ ]+]] = extractvalue [8 x i32] %srcB, 3
; CHECK: [[_srcBi3:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi2]], i32 [[_srcB3]], 3
; CHECK: [[_srcB4:%[^ ]+]] = extractvalue [8 x i32] %srcB, 4
; CHECK: [[_srcBi4:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi3]], i32 [[_srcB4]], 4
; CHECK: [[_srcB5:%[^ ]+]] = extractvalue [8 x i32] %srcB, 5
; CHECK: [[_srcBi5:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi4]], i32 [[_srcB5]], 5
; CHECK: [[_srcB6:%[^ ]+]] = extractvalue [8 x i32] %srcB, 6
; CHECK: [[_srcBi6:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi5]], i32 [[_srcB6]], 6
; CHECK: [[_srcB7:%[^ ]+]] = extractvalue [8 x i32] %srcB, 7
; CHECK: [[_srcBi7:%[^ ]+]] = insertvalue [8 x i32] [[_srcBi6]], i32 [[_srcB7]], 7

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

; CHECK: [[_srcAii0:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 0
; CHECK: [[srcAGep0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 0
; CHECK: store i32 [[_srcAii0]], i32* [[srcAGep0]], align 4
; CHECK: [[_srcAii1:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 1
; CHECK: [[srcAGep1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 1
; CHECK: store i32 [[_srcAii1]], i32* [[srcAGep1]], align 4
; CHECK: [[_srcAii2:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 2
; CHECK: [[srcAGep2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 2
; CHECK: store i32 [[_srcAii2]], i32* [[srcAGep2]], align 4
; CHECK: [[_srcAii3:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 3
; CHECK: [[srcAGep3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 3
; CHECK: store i32 [[_srcAii3]], i32* [[srcAGep3]], align 4
; CHECK: [[_srcAii4:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 4
; CHECK: [[srcAGep4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 4
; CHECK: store i32 [[_srcAii4]], i32* [[srcAGep4]], align 4
; CHECK: [[_srcAii5:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 5
; CHECK: [[srcAGep5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 5
; CHECK: store i32 [[_srcAii5]], i32* [[srcAGep5]], align 4
; CHECK: [[_srcAii6:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 6
; CHECK: [[srcAGep6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 6
; CHECK: store i32 [[_srcAii6]], i32* [[srcAGep6]], align 4
; CHECK: [[_srcAii7:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 7
; CHECK: [[srcAGep7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 7
; CHECK: store i32 [[_srcAii7]], i32* [[srcAGep7]], align 4

; CHECK: [[_srcBii0:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 0
; CHECK: [[srcBGep0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 0
; CHECK: store i32 [[_srcBii0]], i32* [[srcBGep0]], align 4
; CHECK: [[_srcBii1:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 1
; CHECK: [[srcBGep1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 1
; CHECK: store i32 [[_srcBii1]], i32* [[srcBGep1]], align 4
; CHECK: [[_srcBii2:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 2
; CHECK: [[srcBGep2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 2
; CHECK: store i32 [[_srcBii2]], i32* [[srcBGep2]], align 4
; CHECK: [[_srcBii3:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 3
; CHECK: [[srcBGep3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 3
; CHECK: store i32 [[_srcBii3]], i32* [[srcBGep3]], align 4
; CHECK: [[_srcBii4:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 4
; CHECK: [[srcBGep4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 4
; CHECK: store i32 [[_srcBii4]], i32* [[srcBGep4]], align 4
; CHECK: [[_srcBii5:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 5
; CHECK: [[srcBGep5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 5
; CHECK: store i32 [[_srcBii5]], i32* [[srcBGep5]], align 4
; CHECK: [[_srcBii6:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 6
; CHECK: [[srcBGep6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 6
; CHECK: store i32 [[_srcBii6]], i32* [[srcBGep6]], align 4
; CHECK: [[_srcBii7:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 7
; CHECK: [[srcBGep7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 7
; CHECK: store i32 [[_srcBii7]], i32* [[srcBGep7]], align 4

; CHECK: [[mask0:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 0
; CHECK: [[mask0mod:%[^ ]+]] = urem i32 [[mask0]], 8
; CHECK: [[srcAGepi0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask0mod]]
; CHECK: [[srcA0:%[^ ]+]] = load i32, i32* [[srcAGepi0]], align 4
; CHECK: [[srcBGepi0:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask0mod]]
; CHECK: [[srcB0:%[^ ]+]] = load i32, i32* [[srcBGepi0]], align 4
; CHECK: [[mask0mod2:%[^ ]+]] = urem i32 [[mask0]], 16
; CHECK: [[cmp0:%[^ ]+]] = icmp sge i32 [[mask0mod2]], 8
; CHECK: [[val0:%[^ ]+]] = select i1 [[cmp0]], i32 [[srcB0]], i32 [[srcA0]]
; CHECK: [[res0:%[^ ]+]] = insertvalue [8 x i32] undef, i32 [[val0]], 0

; CHECK: [[mask1:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 1
; CHECK: [[mask1mod:%[^ ]+]] = urem i32 [[mask1]], 8
; CHECK: [[srcAGepi1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask1mod]]
; CHECK: [[srcA1:%[^ ]+]] = load i32, i32* [[srcAGepi1]], align 4
; CHECK: [[srcBGepi1:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask1mod]]
; CHECK: [[srcB1:%[^ ]+]] = load i32, i32* [[srcBGepi1]], align 4
; CHECK: [[mask1mod2:%[^ ]+]] = urem i32 [[mask1]], 16
; CHECK: [[cmp1:%[^ ]+]] = icmp sge i32 [[mask1mod2]], 8
; CHECK: [[val1:%[^ ]+]] = select i1 [[cmp1]], i32 [[srcB1]], i32 [[srcA1]]
; CHECK: [[res1:%[^ ]+]] = insertvalue [8 x i32] [[res0]], i32 [[val1]], 1

; CHECK: [[mask2:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 2
; CHECK: [[mask2mod:%[^ ]+]] = urem i32 [[mask2]], 8
; CHECK: [[srcAGepi2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask2mod]]
; CHECK: [[srcA2:%[^ ]+]] = load i32, i32* [[srcAGepi2]], align 4
; CHECK: [[srcBGepi2:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask2mod]]
; CHECK: [[srcB2:%[^ ]+]] = load i32, i32* [[srcBGepi2]], align 4
; CHECK: [[mask2mod2:%[^ ]+]] = urem i32 [[mask2]], 16
; CHECK: [[cmp2:%[^ ]+]] = icmp sge i32 [[mask2mod2]], 8
; CHECK: [[val2:%[^ ]+]] = select i1 [[cmp2]], i32 [[srcB2]], i32 [[srcA2]]
; CHECK: [[res2:%[^ ]+]] = insertvalue [8 x i32] [[res1]], i32 [[val2]], 2

; CHECK: [[mask3:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 3
; CHECK: [[mask3mod:%[^ ]+]] = urem i32 [[mask3]], 8
; CHECK: [[srcAGepi3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask3mod]]
; CHECK: [[srcA3:%[^ ]+]] = load i32, i32* [[srcAGepi3]], align 4
; CHECK: [[srcBGepi3:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask3mod]]
; CHECK: [[srcB3:%[^ ]+]] = load i32, i32* [[srcBGepi3]], align 4
; CHECK: [[mask3mod2:%[^ ]+]] = urem i32 [[mask3]], 16
; CHECK: [[cmp3:%[^ ]+]] = icmp sge i32 [[mask3mod2]], 8
; CHECK: [[val3:%[^ ]+]] = select i1 [[cmp3]], i32 [[srcB3]], i32 [[srcA3]]
; CHECK: [[res3:%[^ ]+]] = insertvalue [8 x i32] [[res2]], i32 [[val3]], 3

; CHECK: [[mask4:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 4
; CHECK: [[mask4mod:%[^ ]+]] = urem i32 [[mask4]], 8
; CHECK: [[srcAGepi4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask4mod]]
; CHECK: [[srcA4:%[^ ]+]] = load i32, i32* [[srcAGepi4]], align 4
; CHECK: [[srcBGepi4:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask4mod]]
; CHECK: [[srcB4:%[^ ]+]] = load i32, i32* [[srcBGepi4]], align 4
; CHECK: [[mask4mod2:%[^ ]+]] = urem i32 [[mask4]], 16
; CHECK: [[cmp4:%[^ ]+]] = icmp sge i32 [[mask4mod2]], 8
; CHECK: [[val4:%[^ ]+]] = select i1 [[cmp4]], i32 [[srcB4]], i32 [[srcA4]]
; CHECK: [[res4:%[^ ]+]] = insertvalue [8 x i32] [[res3]], i32 [[val4]], 4

; CHECK: [[mask5:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 5
; CHECK: [[mask5mod:%[^ ]+]] = urem i32 [[mask5]], 8
; CHECK: [[srcAGepi5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask5mod]]
; CHECK: [[srcA5:%[^ ]+]] = load i32, i32* [[srcAGepi5]], align 4
; CHECK: [[srcBGepi5:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask5mod]]
; CHECK: [[srcB5:%[^ ]+]] = load i32, i32* [[srcBGepi5]], align 4
; CHECK: [[mask5mod2:%[^ ]+]] = urem i32 [[mask5]], 16
; CHECK: [[cmp5:%[^ ]+]] = icmp sge i32 [[mask5mod2]], 8
; CHECK: [[val5:%[^ ]+]] = select i1 [[cmp5]], i32 [[srcB5]], i32 [[srcA5]]
; CHECK: [[res5:%[^ ]+]] = insertvalue [8 x i32] [[res4]], i32 [[val5]], 5

; CHECK: [[mask6:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 6
; CHECK: [[mask6mod:%[^ ]+]] = urem i32 [[mask6]], 8
; CHECK: [[srcAGepi6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask6mod]]
; CHECK: [[srcA6:%[^ ]+]] = load i32, i32* [[srcAGepi6]], align 4
; CHECK: [[srcBGepi6:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask6mod]]
; CHECK: [[srcB6:%[^ ]+]] = load i32, i32* [[srcBGepi6]], align 4
; CHECK: [[mask6mod2:%[^ ]+]] = urem i32 [[mask6]], 16
; CHECK: [[cmp6:%[^ ]+]] = icmp sge i32 [[mask6mod2]], 8
; CHECK: [[val6:%[^ ]+]] = select i1 [[cmp6]], i32 [[srcB6]], i32 [[srcA6]]
; CHECK: [[res6:%[^ ]+]] = insertvalue [8 x i32] [[res5]], i32 [[val6]], 6

; CHECK: [[mask7:%[^ ]+]] = extractvalue [8 x i32] [[mask]], 7
; CHECK: [[mask7mod:%[^ ]+]] = urem i32 [[mask7]], 8
; CHECK: [[srcAGepi7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcA_alloca]], i32 0, i32 [[mask7mod]]
; CHECK: [[srcA7:%[^ ]+]] = load i32, i32* [[srcAGepi7]], align 4
; CHECK: [[srcBGepi7:%[^ ]+]] = getelementptr [8 x i32], [8 x i32]* [[srcB_alloca]], i32 0, i32 [[mask7mod]]
; CHECK: [[srcB7:%[^ ]+]] = load i32, i32* [[srcBGepi7]], align 4
; CHECK: [[mask7mod2:%[^ ]+]] = urem i32 [[mask7]], 16
; CHECK: [[cmp7:%[^ ]+]] = icmp sge i32 [[mask7mod2]], 8
; CHECK: [[val7:%[^ ]+]] = select i1 [[cmp7]], i32 [[srcB7]], i32 [[srcA7]]
; CHECK: [[res7:%[^ ]+]] = insertvalue [8 x i32] [[res6]], i32 [[val7]], 7

; CHECK: store [8 x i32] [[res7]], [8 x i32] addrspace(1)* %dst, align 32
