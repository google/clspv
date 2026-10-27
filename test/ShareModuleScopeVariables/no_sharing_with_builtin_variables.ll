; RUN: clspv-opt %s -o %t.ll --passes=share-module-scope-vars
; RUN: FileCheck %s < %t.ll

; @foo.local is a __local variable of the same type as the module scope
; private variable clspv creates for get_max_sub_group_size(), which must not
; be shared with it.

; CHECK: @foo.local = internal unnamed_addr addrspace(3) global i32 undef, align 4
; CHECK: @__spirv_SubgroupMaxSize = local_unnamed_addr addrspace(8) global i32 0
; CHECK: store i32 {{.*}}, ptr addrspace(3) @foo.local
; CHECK: load i32, ptr addrspace(3) @foo.local
; CHECK: load i32, ptr addrspace(8) @__spirv_SubgroupMaxSize

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

@foo.local = internal unnamed_addr addrspace(3) global i32 undef, align 4
@__spirv_SubgroupMaxSize = local_unnamed_addr addrspace(8) global i32 0

define spir_kernel void @foo(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out, i32 %n) {
entry:
  %in.n = getelementptr i32, ptr addrspace(1) %in, i32 %n
  %0 = load i32, ptr addrspace(1) %in.n, align 4
  store i32 %0, ptr addrspace(3) @foo.local, align 4
  tail call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264)
  %1 = load i32, ptr addrspace(3) @foo.local, align 4
  %2 = load i32, ptr addrspace(8) @__spirv_SubgroupMaxSize, align 4
  %add = add i32 %2, %1
  %out.n = getelementptr i32, ptr addrspace(1) %out, i32 %n
  store i32 %add, ptr addrspace(1) %out.n, align 4
  ret void
}

declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32)
