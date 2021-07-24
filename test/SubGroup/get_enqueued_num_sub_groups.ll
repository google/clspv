; RUN: clspv-opt -DefineOpenCLWorkItemBuiltins %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

define dso_local spir_kernel void @test(i32 addrspace(1)* %c) !clspv.pod_args_impl !10 {
entry:
  %c.addr = alloca i32 addrspace(1)*, align 4
  store i32 addrspace(1)* null, i32 addrspace(1)** %c.addr, align 4
  store i32 addrspace(1)* %c, i32 addrspace(1)** %c.addr, align 4
  %call = call spir_func i32 @_Z27get_enqueued_num_sub_groupsv() #2
  %0 = load i32 addrspace(1)*, i32 addrspace(1)** %c.addr, align 4
  store i32 %call, i32 addrspace(1)* %0, align 4
  ret void
}

declare spir_func i32 @_Z27get_enqueued_num_sub_groupsv()

!0 = !{i32 2}
!10 = !{i32 3}

; CHECK: define spir_func i32 @_Z27get_enqueued_num_sub_groupsv() {
; CHECK: body:
; CHECK:   %0 = call spir_func i32 @_Z23get_enqueued_local_sizej(i32 0)
; CHECK:   %1 = call spir_func i32 @_Z23get_enqueued_local_sizej(i32 1)
; CHECK:   %2 = call spir_func i32 @_Z23get_enqueued_local_sizej(i32 2)
; CHECK:   %3 = mul i32 %0, %1
; CHECK:   %4 = mul i32 %3, %2
; CHECK:   %5 = call spir_func i32 @_Z22get_max_sub_group_sizev()
; CHECK:   %6 = add i32 %4, %5
; CHECK:   %7 = sub i32 %6, 1
; CHECK:   %8 = udiv i32 %7, %5
; CHECK:   ret i32 %8
; CHECK: }

; CHECK: define spir_func i32 @_Z23get_enqueued_local_sizej(i32 %0) {
; CHECK: define spir_func i32 @_Z22get_max_sub_group_sizev() {
