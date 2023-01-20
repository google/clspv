; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(<8 x i32> %srcA, <8 x i32> %srcB, ptr addrspace(1) noundef align 32 %dst, <2 x i32> %mask) {
entry:
  %0 = call spir_func <2 x i32> @_Z8shuffle2Dv8_iS_Dv2_j(<8 x i32> %srcA, <8 x i32> %srcB, <2 x i32> %mask)
  store <2 x i32> %0, ptr addrspace(1) %dst, align 32
  ret void
}

declare spir_func <2 x i32> @_Z8shuffle2Dv8_iS_Dv2_j(<8 x i32> noundef, <8 x i32> noundef, <2 x i32> noundef)

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

; CHECK: [[_srcAii0:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 0
; CHECK: [[srcAGep0:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 0
; CHECK: store i32 [[_srcAii0]], ptr [[srcAGep0]], align 4
; CHECK: [[_srcAii1:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 1
; CHECK: [[srcAGep1:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 1
; CHECK: store i32 [[_srcAii1]], ptr [[srcAGep1]], align 4
; CHECK: [[_srcAii2:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 2
; CHECK: [[srcAGep2:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 2
; CHECK: store i32 [[_srcAii2]], ptr [[srcAGep2]], align 4
; CHECK: [[_srcAii3:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 3
; CHECK: [[srcAGep3:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 3
; CHECK: store i32 [[_srcAii3]], ptr [[srcAGep3]], align 4
; CHECK: [[_srcAii4:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 4
; CHECK: [[srcAGep4:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 4
; CHECK: store i32 [[_srcAii4]], ptr [[srcAGep4]], align 4
; CHECK: [[_srcAii5:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 5
; CHECK: [[srcAGep5:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 5
; CHECK: store i32 [[_srcAii5]], ptr [[srcAGep5]], align 4
; CHECK: [[_srcAii6:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 6
; CHECK: [[srcAGep6:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 6
; CHECK: store i32 [[_srcAii6]], ptr [[srcAGep6]], align 4
; CHECK: [[_srcAii7:%[^ ]+]] = extractvalue [8 x i32] [[_srcAi7]], 7
; CHECK: [[srcAGep7:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 7
; CHECK: store i32 [[_srcAii7]], ptr [[srcAGep7]], align 4

; CHECK: [[_srcBii0:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 0
; CHECK: [[srcBGep0:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 0
; CHECK: store i32 [[_srcBii0]], ptr [[srcBGep0]], align 4
; CHECK: [[_srcBii1:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 1
; CHECK: [[srcBGep1:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 1
; CHECK: store i32 [[_srcBii1]], ptr [[srcBGep1]], align 4
; CHECK: [[_srcBii2:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 2
; CHECK: [[srcBGep2:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 2
; CHECK: store i32 [[_srcBii2]], ptr [[srcBGep2]], align 4
; CHECK: [[_srcBii3:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 3
; CHECK: [[srcBGep3:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 3
; CHECK: store i32 [[_srcBii3]], ptr [[srcBGep3]], align 4
; CHECK: [[_srcBii4:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 4
; CHECK: [[srcBGep4:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 4
; CHECK: store i32 [[_srcBii4]], ptr [[srcBGep4]], align 4
; CHECK: [[_srcBii5:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 5
; CHECK: [[srcBGep5:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 5
; CHECK: store i32 [[_srcBii5]], ptr [[srcBGep5]], align 4
; CHECK: [[_srcBii6:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 6
; CHECK: [[srcBGep6:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 6
; CHECK: store i32 [[_srcBii6]], ptr [[srcBGep6]], align 4
; CHECK: [[_srcBii7:%[^ ]+]] = extractvalue [8 x i32] [[_srcBi7]], 7
; CHECK: [[srcBGep7:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 7
; CHECK: store i32 [[_srcBii7]], ptr [[srcBGep7]], align 4

; CHECK: [[mask0:%[^ ]+]] = extractelement <2 x i32> %mask, i64 0
; CHECK: [[mask0mod:%[^ ]+]] = urem i32 [[mask0]], 8
; CHECK: [[srcAGepi0:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 [[mask0mod]]
; CHECK: [[srcA0:%[^ ]+]] = load i32, ptr [[srcAGepi0]], align 4
; CHECK: [[srcBGepi0:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 [[mask0mod]]
; CHECK: [[srcB0:%[^ ]+]] = load i32, ptr [[srcBGepi0]], align 4
; CHECK: [[mask0mod2:%[^ ]+]] = urem i32 [[mask0]], 16
; CHECK: [[cmp0:%[^ ]+]] = icmp sge i32 [[mask0mod2]], 8
; CHECK: [[val0:%[^ ]+]] = select i1 [[cmp0]], i32 [[srcB0]], i32 [[srcA0]]
; CHECK: [[res0:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[val0]], i64 0

; CHECK: [[mask1:%[^ ]+]] = extractelement <2 x i32> %mask, i64 1
; CHECK: [[mask1mod:%[^ ]+]] = urem i32 [[mask1]], 8
; CHECK: [[srcAGepi1:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcA_alloca]], i32 0, i32 [[mask1mod]]
; CHECK: [[srcA1:%[^ ]+]] = load i32, ptr [[srcAGepi1]], align 4
; CHECK: [[srcBGepi1:%[^ ]+]] = getelementptr [8 x i32], ptr [[srcB_alloca]], i32 0, i32 [[mask1mod]]
; CHECK: [[srcB1:%[^ ]+]] = load i32, ptr [[srcBGepi1]], align 4
; CHECK: [[mask1mod2:%[^ ]+]] = urem i32 [[mask1]], 16
; CHECK: [[cmp1:%[^ ]+]] = icmp sge i32 [[mask1mod2]], 8
; CHECK: [[val1:%[^ ]+]] = select i1 [[cmp1]], i32 [[srcB1]], i32 [[srcA1]]
; CHECK: [[res1:%[^ ]+]] = insertelement <2 x i32> [[res0]], i32 [[val1]], i64 1

; CHECK: store <2 x i32> [[res1]], ptr addrspace(1) %dst, align 32
