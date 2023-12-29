; RUN: clspv-opt %s -o %t.ll --passes=three-element-vector-lowering --vec3-to-vec4
; RUN: FileCheck %s < %t.ll

; CHECK:  [[gep1:%[^ ]+]] = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr <3 x i32>, ptr addrspace(9) [[gep1]], i32 0, i32 1
; CHECK:  load i32, ptr addrspace(9) [[gep2]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define dso_local spir_kernel void @test() {
entry:
  %0 = getelementptr inbounds %0, ptr addrspace(9) @__push_constants, i32 0, i32 1
  %1 = getelementptr <3 x i32>, ptr addrspace(9) %0, i32 0, i32 1
  %2 = load i32, ptr addrspace(9) %1, align 4
  ret void
}

!0 = !{i32 3, i32 4}
