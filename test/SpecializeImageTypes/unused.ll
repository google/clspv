; RUN: clspv-opt %s -o %t.ll --passes=specialize-image-types --cl-std=CL2.0
; RUN: FileCheck %s < %t.ll

; CHECK: @foo(target("spirv.Image", float, 1, 0, 0, 0, 2, 0, 2, 0) %unused)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @foo(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %unused) {
entry:
  ret void
}

!10 = !{i32 2}

