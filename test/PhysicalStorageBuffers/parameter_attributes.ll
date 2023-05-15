; RUN: clspv-opt %s -o %t.ll --passes=physical-pointer-args
; RUN: FileCheck %s < %t.ll

; CHECK: @test(target("spirv.Sampler") {{%[0-9a-zA-Z_.]+}}, i64 {{%[0-9a-zA-Z_.]+}}, i32 inreg {{%[0-9a-zA-Z_.]+}}, i64 inreg {{%[0-9a-zA-Z_.]+}})

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

define spir_kernel void @test(target("spirv.Sampler") %s, ptr addrspace(1) noalias %p1, i32 inreg %pod, ptr addrspace(1) readnone inreg align 64 %p2) !clspv.pod_args_impl !0 {
entry:
  %ld1 = load float, ptr addrspace(1) %p1
  %ld2 = load float, ptr addrspace(1) %p2
  ret void
}

!0 = !{i32 1 }
