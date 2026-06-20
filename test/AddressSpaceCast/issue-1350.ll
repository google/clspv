; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: declare void @_Z21llvm.memcpy.p0.p4.i32PPU3AS1memcpy.p0.p4.i32(ptr noalias nocapture writeonly, ptr addrspace(1) noalias nocapture readonly, i32, i1) #0

; CHECK-NOT: addrspacecast
; CHECK-NOT: @llvm.memcpy.p0.p4.i32

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @kern(ptr addrspace(1) align 4 %in) {
entry:
  %cpy = alloca [4 x float], align 4
  %0 = addrspacecast ptr addrspace(1) %in to ptr addrspace(4)
  call void @llvm.memcpy.p0.p4.i32(ptr align 4 %cpy, ptr addrspace(4) align 4 %0, i32 16, i1 false)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p4.i32(ptr noalias nocapture writeonly, ptr addrspace(4) noalias nocapture readonly, i32, i1 immarg) #0

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }