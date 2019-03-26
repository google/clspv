; RUN: clspv-opt %s -help > %t.out
; RUN: FileCheck %s < %t.out
; CHECK: -clo-opt=<string>    - Path to LLVM's 'opt' tool.
; CHECK: -clo-passes=<string> - Path to libclspv_passes.so.
; CHECK: -clo-verbose=<int>   - Verbosity level.  Higher values increase
;define spir_kernel void @empty() {
;entry:
;  ret void
;}
