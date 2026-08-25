; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK: getelementptr %struct.S16, ptr addrspace(1) %in, i32 %lid, i32 0, i32 %gid
; CHECK: load i64, ptr addrspace(1)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.S16 = type { <4 x float> }

define spir_kernel void @kern(ptr addrspace(1) %in, ptr addrspace(1) %out, i32 %lid, i32 %gid) {
entry:
  %s1 = getelementptr %struct.S16, ptr addrspace(1) %in, i32 %lid
  %s2 = getelementptr float, ptr addrspace(1) %s1, i32 %gid
  %v = load i64, ptr addrspace(1) %s2, align 8
  %out_ptr = getelementptr i64, ptr addrspace(1) %out, i32 %lid
  store i64 %v, ptr addrspace(1) %out_ptr, align 8
  ret void
}
