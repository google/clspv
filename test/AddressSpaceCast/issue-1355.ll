; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll
; RUN: clspv-opt %s -o %t.replace.ll --passes=lower-addrspacecast,replace-llvm-intrinsics
; RUN: FileCheck %s --check-prefix=REPLACE < %t.replace.ll

; CHECK-DAG: declare void @_Z21llvm.memcpy.p4.p4.i32PU3AS1memcpy.p4.p4.i32.1(ptr addrspace(1) noalias writeonly captures(none), ptr noalias readonly captures(none), i32, i1) #0
; CHECK-DAG: declare void @_Z21llvm.memcpy.p4.p4.i32PU3AS1memcpy.p4.p4.i32(ptr addrspace(1) noalias writeonly captures(none), ptr addrspace(3) noalias readonly captures(none), i32, i1) #0
; CHECK-DAG: declare void @_Z21llvm.memcpy.p0.p4.i32Pmemcpy.p0.p4.i32(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i32, i1) #0
; CHECK-DAG: declare void @_Z21llvm.memcpy.p0.p4.i32PPU3AS1memcpy.p0.p4.i32(ptr noalias writeonly captures(none), ptr addrspace(1) noalias readonly captures(none), i32, i1) #0

; REPLACE-NOT: declare {{.*}}llvm.memcpy

; CHECK-LABEL: define dso_local spir_kernel void @kern(ptr addrspace(1) align 4 %in)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %cpy = alloca [4 x float], align 4
; CHECK-NEXT:   call void @_Z21llvm.memcpy.p0.p4.i32PPU3AS1memcpy.p0.p4.i32(ptr %cpy, ptr addrspace(1) %in, i32 16, i1 false)
; CHECK-NEXT:   %cpy2 = alloca [4 x float], align 4
; CHECK-NEXT:   call void @_Z21llvm.memcpy.p0.p4.i32Pmemcpy.p0.p4.i32(ptr %cpy2, ptr %cpy, i32 16, i1 false)
; CHECK-NEXT:   ret void

; CHECK-LABEL: define dso_local spir_kernel void @collision(ptr addrspace(1) align 4 %dst, ptr addrspace(3) align 4 %loc)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %priv = alloca [4 x float], align 4
; CHECK-NEXT:   call void @_Z21llvm.memcpy.p4.p4.i32PU3AS1memcpy.p4.p4.i32(ptr addrspace(1) %dst, ptr addrspace(3) %loc, i32 16, i1 false)
; CHECK-NEXT:   call void @_Z21llvm.memcpy.p4.p4.i32PU3AS1memcpy.p4.p4.i32.1(ptr addrspace(1) %dst, ptr %priv, i32 16, i1 false)
; CHECK-NEXT:   call void @_Z21llvm.memcpy.p4.p4.i32PU3AS1memcpy.p4.p4.i32.1(ptr addrspace(1) %dst, ptr %priv, i32 16, i1 false)
; CHECK-NEXT:   ret void

; REPLACE-LABEL: define dso_local spir_kernel void @kern(
; REPLACE-NOT: call
; REPLACE-LABEL: define dso_local spir_kernel void @collision(
; REPLACE-NOT: call

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @kern(ptr addrspace(1) align 4 %in) {
entry:
  %cpy = alloca [4 x float], align 4
  %0 = addrspacecast ptr addrspace(1) %in to ptr addrspace(4)
  call void @llvm.memcpy.p0.p4.i32(ptr align 4 %cpy, ptr addrspace(4) align 4 %0, i32 16, i1 false)
  %cpy2 = alloca [4 x float], align 4
  %1 = addrspacecast ptr %cpy to ptr addrspace(4)
  call void @llvm.memcpy.p0.p4.i32(ptr align 4 %cpy2, ptr addrspace(4) align 4 %1, i32 16, i1 false)
  ret void
}

define dso_local spir_kernel void @collision(ptr addrspace(1) align 4 %dst, ptr addrspace(3) align 4 %loc) {
entry:
  %priv = alloca [4 x float], align 4
  %dst.g = addrspacecast ptr addrspace(1) %dst to ptr addrspace(4)
  %loc.g = addrspacecast ptr addrspace(3) %loc to ptr addrspace(4)
  %priv.g = addrspacecast ptr %priv to ptr addrspace(4)
  call void @llvm.memcpy.p4.p4.i32(ptr addrspace(4) align 4 %dst.g, ptr addrspace(4) align 4 %loc.g, i32 16, i1 false)
  call void @llvm.memcpy.p4.p4.i32(ptr addrspace(4) align 4 %dst.g, ptr addrspace(4) align 4 %priv.g, i32 16, i1 false)
  call void @llvm.memcpy.p4.p4.i32(ptr addrspace(4) align 4 %dst.g, ptr addrspace(4) align 4 %priv.g, i32 16, i1 false)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p4.i32(ptr noalias nocapture writeonly, ptr addrspace(4) noalias nocapture readonly, i32, i1 immarg) #0
declare void @llvm.memcpy.p4.p4.i32(ptr addrspace(4) noalias nocapture writeonly, ptr addrspace(4) noalias nocapture readonly, i32, i1 immarg) #0

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
