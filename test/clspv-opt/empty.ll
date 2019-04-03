; RUN: clspv-opt %s -help > %t.out
; RUN: FileCheck %s < %t.out
; CHECK: OVERVIEW: clspv IR to IR modular optimizer
; CHECK: USAGE: clspv-opt [options] <input LLVM IR file>
