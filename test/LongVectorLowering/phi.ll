; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; CHECK: phi [8 x i32]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(<8 x i32> %x) {
entry:
    br label %loop
loop:
    %xloop = phi <8 x i32> [%x, %entry], [%xloopm, %loop]
    %xloopm = add <8 x i32> %xloop, <i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1>
    %cmp = icmp sle <8 x i32> %xloopm, zeroinitializer
    %cmp0 = extractelement <8 x i1> %cmp, i32 0
    %cmp1 = extractelement <8 x i1> %cmp, i32 1
    %cmp2 = extractelement <8 x i1> %cmp, i32 2
    %cmp3 = extractelement <8 x i1> %cmp, i32 3
    %cmp4 = extractelement <8 x i1> %cmp, i32 4
    %cmp5 = extractelement <8 x i1> %cmp, i32 5
    %cmp6 = extractelement <8 x i1> %cmp, i32 6
    %cmp7 = extractelement <8 x i1> %cmp, i32 7
    %and01 = and i1 %cmp0, %cmp1
    %and23 = and i1 %cmp2, %cmp3
    %and45 = and i1 %cmp4, %cmp5
    %and67 = and i1 %cmp6, %cmp7
    %and0123 = and i1 %and01, %and23
    %and4567 = and i1 %and45, %and67
    %andall = and i1 %and0123, %and4567
    br i1 %andall, label %exit, label %loop
exit:
    ret void
}
