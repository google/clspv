; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test(ptr %a, ptr %b, ptr %c, ptr %d) {
entry:
  %0 = load <8 x i32>, ptr %a, align 32
  %1 = load <8 x i32>, ptr %b, align 32
  %2 = call { <8 x i32>, <8 x i32> } @_Z8spirv.op.149.Dv8_jDv8_j(i32 149, <8 x i32> %0, <8 x i32> %1)
  %3 = call { <8 x i32> } @_Z8spirv.op.150.Dv8_j(i32 150, <8 x i32> %0)
  ret void
}

declare { <8 x i32>, <8 x i32> } @_Z8spirv.op.149.Dv8_jDv8_j(i32, <8 x i32>, <8 x i32>)
declare { <8 x i32> } @_Z8spirv.op.150.Dv8_j(i32, <8 x i32>)

; CHECK: declare {{.*}} @_Z13spirv.op.150.j(i32, i32)
; CHECK: declare {{.*}} @_Z13spirv.op.149.jj(i32, i32, i32)

; CHECK-COUNT-8: call {{.*}} @_Z13spirv.op.149.jj(i32 149,
; CHECK-COUNT-8: call {{.*}} @_Z13spirv.op.150.j(i32 150,
