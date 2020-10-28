; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @test() {
entry:
  call spir_func void @_Z9mem_fencej(i32 2)
  call spir_func void @_Z7barrierj(i32 2)
  ret void
}

declare spir_func void @_Z9mem_fencej(i32)
declare spir_func void @_Z7barrierj(i32)

; CHECK-DAG: declare void @_Z8spirv.op.225.{{.*}}(i32, i32, i32) [[FENCE_ATTRS:#[0-9]+]]
; CHECK-DAG: declare void @_Z8spirv.op.224.{{.*}}(i32, i32, i32, i32) [[BARRIER_ATTRS:#[0-9]+]]
; CHECK-DAG: attributes [[FENCE_ATTRS]] = { convergent }
; CHECK-DAG: attributes [[BARRIER_ATTRS]] = { convergent noduplicate }
