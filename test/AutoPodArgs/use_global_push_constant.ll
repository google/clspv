; RUN: clspv-opt --passes=auto-pod-args -no-16bit-storage=pushconstant -no-8bit-storage=pushconstant %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Type-mangled arguments don't need to worry about 8- or 16-bit storage restrictions.

; CHECK: define spir_kernel void @foo(i32 addrspace(1)* %out, i16 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
define spir_kernel void @foo(i32 addrspace(1)* %out, i16 %pod) {
entry:
  %ext = zext i16 %pod to i32
  store i32 %ext, i32 addrspace(1)* %out
  ret void
}

; CHECK: define spir_kernel void @bar(i32 addrspace(1)* %out, i8 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
define spir_kernel void @bar(i32 addrspace(1)* %out, i8 %pod) {
entry:
  %ext = zext i8 %pod to i32
  store i32 %ext, i32 addrspace(1)* %out
  ret void
}

; CHECK: [[MD]] = !{i32 3}

