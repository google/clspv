; RUN: clspv-opt %s -o %t.ll --passes=physical-pointer-args
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func void @test_kernel_to_call.inner

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test_kernel_to_call(ptr addrspace(1) align 4 %output, ptr addrspace(1) align 4 %input, i32 %where) #0 !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !clspv.pod_args_impl !13 {
entry:
  %output.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %output.addr, align 8
  %input.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %input.addr, align 8
  %where.addr = alloca i32, align 4
  store i32 0, ptr %where.addr, align 4
  %b = alloca i32, align 4
  store i32 0, ptr %b, align 4
  store ptr addrspace(1) %output, ptr %output.addr, align 8
  store ptr addrspace(1) %input, ptr %input.addr, align 8
  store i32 %where, ptr %where.addr, align 4
  %0 = load i32, ptr %where.addr, align 4
  %cmp = icmp eq i32 %0, 0
  br i1 %cmp, label %if.then, label %if.end

if.then:                                          ; preds = %entry
  %1 = load ptr addrspace(1), ptr %output.addr, align 8
  %2 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %3 = zext i32 %2 to i64
  %4 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), align 4
  %5 = zext i32 %4 to i64
  %6 = add i64 %3, %5
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %1, i64 %6
  store i32 0, ptr addrspace(1) %arrayidx, align 4
  br label %if.end

if.end:                                           ; preds = %if.then, %entry
  store i32 0, ptr %b, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %if.end
  %7 = load i32, ptr %b, align 4
  %8 = load i32, ptr %where.addr, align 4
  %cmp1 = icmp slt i32 %7, %8
  br i1 %cmp1, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %9 = load ptr addrspace(1), ptr %input.addr, align 8
  %10 = load i32, ptr %b, align 4
  %idxprom = sext i32 %10 to i64
  %arrayidx2 = getelementptr inbounds i32, ptr addrspace(1) %9, i64 %idxprom
  %11 = load i32, ptr addrspace(1) %arrayidx2, align 4
  %12 = load ptr addrspace(1), ptr %output.addr, align 8
  %13 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %14 = zext i32 %13 to i64
  %15 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), align 4
  %16 = zext i32 %15 to i64
  %17 = add i64 %14, %16
  %arrayidx4 = getelementptr inbounds i32, ptr addrspace(1) %12, i64 %17
  %18 = load i32, ptr addrspace(1) %arrayidx4, align 4
  %add = add nsw i32 %18, %11
  store i32 %add, ptr addrspace(1) %arrayidx4, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %19 = load i32, ptr %b, align 4
  %inc = add nsw i32 %19, 1
  store i32 %inc, ptr %b, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test_call_kernel(ptr addrspace(1) align 4 %src, ptr addrspace(1) align 4 %dst, i32 %times) #0 !kernel_arg_addr_space !9 !kernel_arg_access_qual !10 !kernel_arg_type !11 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !clspv.pod_args_impl !13 {
entry:
  %src.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %src.addr, align 8
  %dst.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %dst.addr, align 8
  %times.addr = alloca i32, align 4
  store i32 0, ptr %times.addr, align 4
  %tid = alloca i32, align 4
  store i32 0, ptr %tid, align 4
  %a = alloca i32, align 4
  store i32 0, ptr %a, align 4
  store ptr addrspace(1) %src, ptr %src.addr, align 8
  store ptr addrspace(1) %dst, ptr %dst.addr, align 8
  store i32 %times, ptr %times.addr, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = zext i32 %0 to i64
  %2 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), align 4
  %3 = zext i32 %2 to i64
  %4 = add i64 %1, %3
  %conv = trunc i64 %4 to i32
  store i32 %conv, ptr %tid, align 4
  %5 = load ptr addrspace(1), ptr %dst.addr, align 8
  %6 = load i32, ptr %tid, align 4
  %idxprom = sext i32 %6 to i64
  %arrayidx = getelementptr inbounds i32, ptr addrspace(1) %5, i64 %idxprom
  store i32 1, ptr addrspace(1) %arrayidx, align 4
  store i32 0, ptr %a, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %7 = load i32, ptr %a, align 4
  %8 = load i32, ptr %times.addr, align 4
  %cmp = icmp slt i32 %7, %8
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %9 = load ptr addrspace(1), ptr %dst.addr, align 8
  %10 = load ptr addrspace(1), ptr %src.addr, align 8
  %11 = load i32, ptr %tid, align 4
  call spir_kernel void @test_kernel_to_call(ptr addrspace(1) align 4 %9, ptr addrspace(1) align 4 %10, i32 %11) #1
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %12 = load i32, ptr %a, align 4
  %inc = add nsw i32 %12, 1
  store i32 %inc, ptr %a, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nobuiltin nounwind "no-builtins" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7, !8}

!0 = !{i32 1, i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 3401a5f7584a2f12a90a7538aee2ae37038c82a9)"}
!7 = !{!"test_kernel_to_call", !" __kernel"}
!8 = !{!"test_call_kernel", !" __kernel"}
!9 = !{i32 1, i32 1, i32 0}
!10 = !{!"none", !"none", !"none"}
!11 = !{!"int*", !"int*", !"int"}
!12 = !{!"", !"", !""}
!13 = !{i32 3}
