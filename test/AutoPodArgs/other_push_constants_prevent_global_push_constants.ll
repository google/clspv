; RUN: clspv-opt --passes=auto-pod-args -no-16bit-storage=pushconstant -max-pushconstant-size=32 -global-offset -cl-std=CL2.0 %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Storage restrictions prevent per-kernel push constants and the use of other
; push constants prevents global push constants.

; CHECK: define spir_kernel void @foo(ptr addrspace(1) %out, i16 %pod) !clspv.pod_args_impl [[MD:![0-9]+]]
; CHECK: [[MD]] = !{i32 {{[01]}}}
define spir_kernel void @foo(ptr addrspace(1) %out, i16 %pod) {
entry:
  %ext = zext i16 %pod to i32
  %gid = call i32 @_Z13get_global_idj(i32 0)
  %add = add i32 %ext, %gid
  store i32 %add, ptr addrspace(1) %out
  ret void
}

declare i32 @_Z13get_global_idj(i32)

