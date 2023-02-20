; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test8(ptr %a, ptr %b, ptr %c, ptr %d) {
entry:
  %0 = load <8 x i32>, ptr %a, align 32
  %1 = load <8 x i32>, ptr %b, align 32
  %2 = call { <8 x i32>, <8 x i32> } @_Z8spirv.op.149.Dv8_jDv8_j(i32 149, <8 x i32> %0, <8 x i32> %1)
  %3 = extractvalue { <8 x i32>, <8 x i32> } %2, 0
  %4 = extractvalue { <8 x i32>, <8 x i32> } %2, 1
  store <8 x i32> %3, ptr %c, align 32
  store <8 x i32> %4, ptr %d, align 32
  ret void
}

; Function Attrs: readnone
declare { <8 x i32>, <8 x i32> } @_Z8spirv.op.149.Dv8_jDv8_j(i32, <8 x i32>, <8 x i32>)

; CHECK: [[rettype:%[^ ]+]] = type { i32, i32 }

; CHECK: [[loada:%[^ ]+]] = load [8 x i32], ptr %a, align 32
; CHECK: [[loadb:%[^ ]+]] = load [8 x i32], ptr %b, align 32

; CHECK: [[a0:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 0
; CHECK: [[b0:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 0
; CHECK: [[addc0:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a0]], i32 [[b0]])
; CHECK: [[addc0val:%[^ ]+]] = extractvalue [[rettype]] [[addc0]], 0
; CHECK: [[res0:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } poison, i32 [[addc0val]], 0, 0
; CHECK: [[addc0carry:%[^ ]+]] = extractvalue [[rettype]] [[addc0]], 1
; CHECK: [[res00:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res0]], i32 [[addc0carry]], 1, 0

; CHECK: [[a1:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 1
; CHECK: [[b1:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 1
; CHECK: [[addc1:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a1]], i32 [[b1]])
; CHECK: [[addc1val:%[^ ]+]] = extractvalue [[rettype]] [[addc1]], 0
; CHECK: [[res01:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res00]], i32 [[addc1val]], 0, 1
; CHECK: [[addc1carry:%[^ ]+]] = extractvalue [[rettype]] [[addc1]], 1
; CHECK: [[res11:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res01]], i32 [[addc1carry]], 1, 1

; CHECK: [[a2:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 2
; CHECK: [[b2:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 2
; CHECK: [[addc2:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a2]], i32 [[b2]])
; CHECK: [[addc2val:%[^ ]+]] = extractvalue [[rettype]] [[addc2]], 0
; CHECK: [[res12:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res11]], i32 [[addc2val]], 0, 2
; CHECK: [[addc2carry:%[^ ]+]] = extractvalue [[rettype]] [[addc2]], 1
; CHECK: [[res22:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res12]], i32 [[addc2carry]], 1, 2

; CHECK: [[a3:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 3
; CHECK: [[b3:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 3
; CHECK: [[addc3:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a3]], i32 [[b3]])
; CHECK: [[addc3val:%[^ ]+]] = extractvalue [[rettype]] [[addc3]], 0
; CHECK: [[res23:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res22]], i32 [[addc3val]], 0, 3
; CHECK: [[addc3carry:%[^ ]+]] = extractvalue [[rettype]] [[addc3]], 1
; CHECK: [[res33:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res23]], i32 [[addc3carry]], 1, 3

; CHECK: [[a4:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 4
; CHECK: [[b4:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 4
; CHECK: [[addc4:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a4]], i32 [[b4]])
; CHECK: [[addc4val:%[^ ]+]] = extractvalue [[rettype]] [[addc4]], 0
; CHECK: [[res34:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res33]], i32 [[addc4val]], 0, 4
; CHECK: [[addc4carry:%[^ ]+]] = extractvalue [[rettype]] [[addc4]], 1
; CHECK: [[res44:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res34]], i32 [[addc4carry]], 1, 4

; CHECK: [[a5:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 5
; CHECK: [[b5:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 5
; CHECK: [[addc5:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a5]], i32 [[b5]])
; CHECK: [[addc5val:%[^ ]+]] = extractvalue [[rettype]] [[addc5]], 0
; CHECK: [[res45:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res44]], i32 [[addc5val]], 0, 5
; CHECK: [[addc5carry:%[^ ]+]] = extractvalue [[rettype]] [[addc5]], 1
; CHECK: [[res55:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res45]], i32 [[addc5carry]], 1, 5

; CHECK: [[a6:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 6
; CHECK: [[b6:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 6
; CHECK: [[addc6:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a6]], i32 [[b6]])
; CHECK: [[addc6val:%[^ ]+]] = extractvalue [[rettype]] [[addc6]], 0
; CHECK: [[res56:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res55]], i32 [[addc6val]], 0, 6
; CHECK: [[addc6carry:%[^ ]+]] = extractvalue [[rettype]] [[addc6]], 1
; CHECK: [[res66:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res56]], i32 [[addc6carry]], 1, 6

; CHECK: [[a7:%[^ ]+]] = extractvalue [8 x i32] [[loada]], 7
; CHECK: [[b7:%[^ ]+]] = extractvalue [8 x i32] [[loadb]], 7
; CHECK: [[addc7:%[^ ]+]] = call [[rettype]] @_Z8spirv.op(i32 149, i32 [[a7]], i32 [[b7]])
; CHECK: [[addc7val:%[^ ]+]] = extractvalue [[rettype]] [[addc7]], 0
; CHECK: [[res67:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res66]], i32 [[addc7val]], 0, 7
; CHECK: [[addc7carry:%[^ ]+]] = extractvalue [[rettype]] [[addc7]], 1
; CHECK: [[res77:%[^ ]+]] = insertvalue { [8 x i32], [8 x i32] } [[res67]], i32 [[addc7carry]], 1, 7

; CHECK [[resc:%[^ ]+]] = extractvalue { [8 x i32], [8 x i32] } [[res77]], 0
; CHECK [[resd:%[^ ]+]] = extractvalue { [8 x i32], [8 x i32] } [[res77]], 1

; CHECK store [8 x i32] [[resc]], [8 x i32]* %c, align 32
; CHECK store [8 x i32] [[resd]], [8 x i32]* %d, align 32
