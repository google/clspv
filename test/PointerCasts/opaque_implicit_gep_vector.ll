; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast -untyped-pointers
; RUN: FileCheck --check-prefix=UNTYPED %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK: %[[resource0:[a-zA-Z0-9]+]] = call ptr addrspace(1) @_Z14clspv.resource.0
; CHECK: %[[resource1:[a-zA-Z0-9]+]] = call ptr addrspace(1) @_Z14clspv.resource.1
; CHECK: %[[gep0:[a-zA-Z0-9]+]] = getelementptr { [0 x <4 x i32>] }, ptr addrspace(1) %[[resource0]], i32 0, i32 0, i32 0
; CHECK: load <4 x i32>, ptr addrspace(1) %[[gep0]]
; CHECK: %[[gep1:[a-zA-Z0-9]+]] = getelementptr { [0 x i32] }, ptr addrspace(1) %[[resource1]], i32 0, i32 0, i32 0
; CHECK: store i32 %{{[a-zA-Z0-9]+}}, ptr addrspace(1) %[[gep1]]

; UNTYPED: load <4 x i32>, ptr addrspace(1) %0
; UNTYPED: store i32 %{{.*}}, ptr addrspace(1) %1

define spir_kernel void @test(ptr addrspace(1) nocapture readonly align 16 %in, ptr addrspace(1) nocapture writeonly align 4 %out)  {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <4 x i32>] } zeroinitializer)
  %1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %2 = load <4 x i32>, ptr addrspace(1) %0, align 16
  %3 = extractelement <4 x i32> %2, i64 0
  store i32 %3, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <4 x i32>] })

declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })
