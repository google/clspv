; RUN: clspv-opt --ThreeElementVectorLowering --vec3-to-vec4 %s -o %t
; RUN: FileCheck %s < %t

; CHECK: phi <4 x i32>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(<3 x i32> %x) {
entry:
    br label %loop
loop:
    %xloop = phi <3 x i32> [%x, %entry], [%xloopm, %loop]
    %xloopm = add <3 x i32> %xloop, <i32 -1, i32 -1, i32 -1>
    %cmp = icmp sle <3 x i32> %xloopm, zeroinitializer
    %cmp0 = extractelement <3 x i1> %cmp, i32 0
    %cmp1 = extractelement <3 x i1> %cmp, i32 1
    %cmp2 = extractelement <3 x i1> %cmp, i32 2
    %and01 = and i1 %cmp0, %cmp1
    %and012 = and i1 %and01, %cmp2
    br i1 %and012, label %exit, label %loop
exit:
    ret void
}
