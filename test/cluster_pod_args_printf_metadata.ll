; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: define spir_kernel void @test11()
; CHECK-SAME: !clspv.kernel_uses_printf

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { i64, i64 }

@.str = private unnamed_addr addrspace(2) constant [4 x i8] c"%d\0A\00", align 1
@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test11(i64 %0) #0 !kernel_arg_addr_space !11 !kernel_arg_access_qual !12 !kernel_arg_type !13 !kernel_arg_base_type !13 !kernel_arg_type_qual !14 !kernel_arg_name !15 !clspv.pod_args_impl !16 !clspv.kernel_uses_printf !17 {
entry:
  %x.addr.i = alloca ptr addrspace(1), align 8
  %1 = inttoptr i64 %0 to ptr addrspace(1), !clspv.pointer_from_pod !17
  call void @llvm.lifetime.start.p0(i64 8, ptr %x.addr.i)
  store ptr addrspace(1) null, ptr %x.addr.i, align 8
  store ptr addrspace(1) %1, ptr %x.addr.i, align 8
  %2 = load ptr addrspace(1), ptr %x.addr.i, align 8
  %3 = load i32, ptr addrspace(1) %2, align 4
  %4 = call i32 @__clspv.printf.0(i32 %3) #2
  call void @llvm.lifetime.end.p0(i64 8, ptr %x.addr.i)
  ret void
}

define i32 @__clspv.printf.0(i32 %0) {
entry:
  %1 = load i64, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), align 8
  %2 = inttoptr i64 %1 to ptr addrspace(1)
  %3 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 0
  %4 = atomicrmw add ptr addrspace(1) %3, i32 2 seq_cst, align 4
  %5 = add i32 %4, 1
  %6 = icmp ult i32 %5, 1048576
  br i1 %6, label %body, label %exit

body:                                             ; preds = %entry
  %7 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 %5
  store i32 0, ptr addrspace(1) %7, align 4
  %8 = add i32 %5, 1
  %9 = getelementptr { [0 x i32] }, ptr addrspace(1) %2, i32 0, i32 0, i32 %8
  store i32 %0, ptr addrspace(1) %9, align 4
  %10 = add i32 %8, 1
  br label %exit

exit:                                             ; preds = %body, %entry
  %11 = phi i32 [ 0, %body ], [ -1, %entry ]
  ret i32 %11
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7}
!_Z28clspv.entry_point_attributes = !{!8}
!clspv.printf_metadata = !{!9}

!0 = !{i32 9, i32 10}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 3, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 1e6fc9626c0f49ce952a67aef47e86253d13f74a)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!8 = !{!"test11", !" __kernel"}
!9 = !{i32 0, !"%d\0A", !10}
!10 = !{i32 4}
!11 = !{i32 1}
!12 = !{!"none"}
!13 = !{!"int*"}
!14 = !{!""}
!15 = !{!"x"}
!16 = !{i32 3}
!17 = !{}
