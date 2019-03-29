; RUN: clspv-opt %s -help > %t.out
; RUN: FileCheck %s < %t.out
; CHECK: -clo-opt=<string>    - Path to LLVM's 'opt' tool (default:
; CHECK: -clo-passes=<string> - Path to libclspv_passes.so (default:
; CHECK: -clo-verbose=<int>   - Verbosity level.  Higher values increase

; RUN: not clspv-opt -clo-opt=/dev/null 2> %t.err
; RUN: FileCheck -check-prefix=ERROR %s < %t.err
; ERROR: Error executing /dev/null:
