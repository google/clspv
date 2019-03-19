; RUN: clspv-opt %s -help > %t.out
; RUN: FileCheck %s < %t.out
; CHECK: -clo-core=<string> - Path to libclspv_core.so.
; CHECK: -clo-opt=<string>  - Path to LLVM's 'opt' tool.
; CHECK: -clo-verbose=<int> - Verbosity level.  Higher values increase
;define spir_kernel void @empty() {
;entry:
;  ret void
;}
