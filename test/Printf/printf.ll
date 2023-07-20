; RUN: clspv-opt %s -o %t.ll --passes=printf-pass --printf-buffer-size=128
; RUN: FileCheck %s < %t.ll

; CHECK: define i32 @__clspv.printf.0(i32 [[arg0:%[^ ]+]], i32 [[arg1:%[^ ]+]]) {
; CHECK-NEXT: [[entryBB:.*]]:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { [0 x i32] }, ptr addrspace(1) @__clspv_printf_buffer, i32 0, i32 0, i32 0
; CHECK-NEXT:   [[atomicadd:%[^ ]+]] = atomicrmw add ptr addrspace(1) [[gep]], i32 3 seq_cst, align 4
; atomicrmw add of 3: 1 word (32bit) for the printf id, 2 word for the args
; CHECK-NEXT:   [[offset:%[^ ]+]] = add i32 [[atomicadd]], 1
; CHECK-NEXT:   [[endoffset:%[^ ]+]] = add i32 [[offset]], 3
; CHECK-NEXT:   [[argsoffset:%[^ ]+]] = add i32 [[offset]], 1
; CHECK-NEXT:   [[cmp:%[^ ]+]] = icmp ule i32 [[endoffset]], 32
; icmp with 32: buffer size is 128 which makes 32 (128/4) words
; CHECK-NEXT:   br i1 [[cmp]], label %[[CopyArgsBB:.*]], label %[[TestPrintfIdBB:.*]]

; CHECK: [[CopyArgsBB]]:
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { [0 x i32] }, ptr addrspace(1) @__clspv_printf_buffer, i32 0, i32 0, i32 [[argsoffset]]
; CHECK-NEXT:   store i32 [[arg0]], ptr addrspace(1) [[gep]], align 4
; CHECK-NEXT:   [[add:%[^ ]+]] = add i32 [[argsoffset]], 1
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { [0 x i32] }, ptr addrspace(1) @__clspv_printf_buffer, i32 0, i32 0, i32 [[add]]
; CHECK-NEXT:   store i32 [[arg1]], ptr addrspace(1) [[gep]], align 4
; CHECK-NEXT:   br label %[[CopyPrintfIdBB:.*]]

; CHECK: [[CopyPrintfIdBB]]:
; CHECK-NEXT:   [[phi:%[^ ]+]] = phi i32 [ 1, %[[CopyArgsBB]] ], [ -1, %[[TestPrintfIdBB]] ]
; CHECK-NEXT:   [[gep:%[^ ]+]] = getelementptr { [0 x i32] }, ptr addrspace(1) @__clspv_printf_buffer, i32 0, i32 0, i32 [[offset]]
; CHECK-NEXT:   store i32 0, ptr addrspace(1) [[gep]], align 4
; '0' is the printf id as we have only 1 printf in this test
; CHECK-NEXT:   br label %[[ExitBB:.*]]

; CHECK: [[TestPrintfIdBB]]:
; CHECK-NEXT:   [[cmp:%[^ ]+]] = icmp ule i32 [[argsoffset]], 32
; CHECK-NEXT:   br i1 [[cmp]], label %[[CopyPrintfIdBB]], label %[[ExitBB]]

; CHECK: [[ExitBB]]:
; CHECK-NEXT:   [[ret:%[^ ]+]] = phi i32 [ [[phi]], %[[CopyPrintfIdBB]] ], [ -1, %[[TestPrintfIdBB]] ]
; CHECK-NEXT:   ret i32 [[ret]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@.str = private unnamed_addr addrspace(2) constant [24 x i8] c"get_global_id(%u) = %u\0A\00", align 1
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test_printf() #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !7 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !7 !kernel_arg_name !7 !clspv.pod_args_impl !8 {
entry:
  %i = alloca i32, align 4
  store i32 0, ptr %i, align 4
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, ptr %i, align 4
  %cmp = icmp ult i32 %0, 3
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %1 = load i32, ptr %i, align 4
  %2 = load i32, ptr %i, align 4
  %call = call spir_func i32 @_Z13get_global_idj(i32 %2) #3
  %call1 = call spir_func i32 (ptr addrspace(2), ...) @printf(ptr addrspace(2) @.str, i32 %1, i32 %call) #4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %3 = load i32, ptr %i, align 4
  %inc = add i32 %3, 1
  store i32 %inc, ptr %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !9 spir_func i32 @printf(ptr addrspace(2), ...) #1

; Function Attrs: convergent nounwind willreturn memory(none)
define spir_func i32 @_Z13get_global_idj(i32 %0) #2 !kernel_arg_name !9 {
body:
  %1 = icmp ult i32 %0, 3
  %2 = select i1 %1, i32 %0, i32 0
  %3 = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_GlobalInvocationId, i32 0, i32 %2
  %4 = load i32, ptr addrspace(5) %3, align 4
  %5 = icmp ult i32 %0, 3
  %6 = select i1 %5, i32 %4, i32 0
  ret i32 %6
}

define spir_func i32 @_Z17get_global_offsetj(i32 %0) {
body:
  ret i32 0
}

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nounwind willreturn memory(none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #3 = { convergent nobuiltin nounwind willreturn memory(none) "no-builtins" }
attributes #4 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!_Z28clspv.entry_point_attributes = !{!6}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!6 = !{!"test_printf", !" kernel"}
!7 = !{}
!8 = !{i32 2}
!9 = !{!""}
