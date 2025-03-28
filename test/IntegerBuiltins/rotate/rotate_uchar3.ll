; RUN: clspv-opt %s -o %t.ll --passes=replace-opencl-builtin,replace-llvm-intrinsics
; RUN: FileCheck %s < %t.ll

; CHECK: [[mask1:%[0-9]+]] = and <3 x i8> %b, splat (i8 7)
; CHECK: [[sub:%[0-9]+]] = sub <3 x i8> splat (i8 8)
; CHECK: [[mask2:%[0-9]+]] = and <3 x i8> [[sub]], splat (i8 7)
; CHECK: [[shl:%[0-9]+]] = shl <3 x i8> %a, [[mask1]]
; CHECK: [[shr:%[0-9]+]] = lshr <3 x i8> %a, [[mask2]]
; CHECK: [[or:%[0-9]+]] = or <3 x i8> [[shr]], [[shl]]
; CHECK: store <3 x i8> [[or]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test_rotate(<3 x i8> addrspace(1)* align 4 %out, <3 x i8> %a, <3 x i8> %b) {
entry:
  %call.i = call spir_func <3 x i8> @_Z6rotateDv3_hS_(<3 x i8> %a, <3 x i8> %b)
  store <3 x i8> %call.i, <3 x i8> addrspace(1)* %out, align 4
  ret void
}

; Function Attrs: convergent nounwind readnone willreturn
declare spir_func <3 x i8> @_Z6rotateDv3_hS_(<3 x i8>, <3 x i8>)

