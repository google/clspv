; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: declare i32 @_Z8spirv.op.234.PU3AS3jjj(i32, ptr addrspace(3), i32, i32, i32)

; CHECK-NOT: addrspacecast
; CHECK-COUNT-4: call i32 @_Z8spirv.op.234.PU3AS3jjj(i32 234, ptr addrspace(3)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, %1 }
%1 = type { i32, i32 }

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_LocalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @test_atomic_kernel(ptr addrspace(1) align 4 %finalDest, ptr addrspace(1) align 4 %oldValues, ptr addrspace(3) align 4 %destMemory) #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !10 !kernel_arg_type_qual !11 !clspv.pod_args_impl !12 !kernel_arg_map !13 {
entry:
  %threadCount = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 0), align 16
  %0 = call i32 @clspv.wrap_constant_load.0(i32 %threadCount) #4
  %numDestItems = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 2, i32 1), align 4
  %1 = call i32 @clspv.wrap_constant_load.0(i32 %numDestItems) #4
  %2 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  %3 = load i32, ptr addrspace(9) getelementptr (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0), align 16
  %4 = call i32 @clspv.wrap_constant_load.0(i32 %3) #4
  %5 = add i32 %2, %4
  %6 = load i32, ptr addrspace(5) @__spirv_LocalInvocationId, align 16
  %cmp.i = icmp eq i32 %6, 0
  br i1 %cmp.i, label %if.then.i, label %if.end.i

if.then.i:                                        ; preds = %entry
  br label %for.cond.i

for.cond.i:                                       ; preds = %for.body.i, %if.then.i
  %dstItemIdx.0.i = phi i32 [ 0, %if.then.i ], [ %inc.i, %for.body.i ]
  %cmp2.i = icmp ult i32 %dstItemIdx.0.i, %1
  br i1 %cmp2.i, label %for.body.i, label %for.end.i

for.body.i:                                       ; preds = %for.cond.i
  %add.ptr.i = getelementptr inbounds i32, ptr addrspace(3) %destMemory, i32 %dstItemIdx.0.i
  %arrayidx.i = getelementptr inbounds i32, ptr addrspace(1) %finalDest, i32 %dstItemIdx.0.i
  %7 = load i32, ptr addrspace(1) %arrayidx.i, align 4
  call void @_Z8spirv.op.228.PU3AS3jjj(i32 228, ptr addrspace(3) %add.ptr.i, i32 2, i32 256, i32 %7) #4
  %inc.i = add i32 %dstItemIdx.0.i, 1
  br label %for.cond.i

for.end.i:                                        ; preds = %for.cond.i
  br label %if.end.i

if.end.i:                                         ; preds = %for.end.i, %entry
  call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #4
  %8 = addrspacecast ptr addrspace(3) %destMemory to ptr addrspace(4)
  %add.i = add nsw i32 %5, 3
  %9 = call i32 @_Z8spirv.op.234.PU3AS4jjj(i32 234, ptr addrspace(4) %8, i32 2, i32 256, i32 %add.i) #4
  %arrayidx1.i = getelementptr inbounds i32, ptr addrspace(1) %oldValues, i32 %5
  store i32 %9, ptr addrspace(1) %arrayidx1.i, align 4
  %add3.i = add nsw i32 %5, 3
  %10 = call i32 @_Z8spirv.op.234.PU3AS4jjj(i32 234, ptr addrspace(4) %8, i32 2, i32 256, i32 %add3.i) #4
  %add6.i = add nsw i32 %5, 3
  %11 = call i32 @_Z8spirv.op.234.PU3AS4jjj(i32 234, ptr addrspace(4) %8, i32 2, i32 256, i32 %add6.i) #4
  %add9.i = shl i32 %5, 24
  %shl.i = add i32 %add9.i, 50331648
  %12 = call i32 @_Z8spirv.op.234.PU3AS4jjj(i32 234, ptr addrspace(4) %8, i32 2, i32 256, i32 %shl.i) #4
  call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 264) #4
  %13 = load i32, ptr addrspace(5) @__spirv_LocalInvocationId, align 16
  %cmp4.i = icmp eq i32 %13, 0
  br i1 %cmp4.i, label %if.then5.i, label %test_atomic_kernel.inner.exit

if.then5.i:                                       ; preds = %if.end.i
  br label %for.cond7.i

for.cond7.i:                                      ; preds = %for.body9.i, %if.then5.i
  %dstItemIdx6.0.i = phi i32 [ 0, %if.then5.i ], [ %inc14.i, %for.body9.i ]
  %cmp8.i = icmp ult i32 %dstItemIdx6.0.i, %1
  br i1 %cmp8.i, label %for.body9.i, label %for.end15.i

for.body9.i:                                      ; preds = %for.cond7.i
  %add.ptr10.i = getelementptr inbounds i32, ptr addrspace(3) %destMemory, i32 %dstItemIdx6.0.i
  %14 = call i32 @_Z8spirv.op.227.PU3AS3jj(i32 227, ptr addrspace(3) %add.ptr10.i, i32 2, i32 256) #4
  %arrayidx12.i = getelementptr inbounds i32, ptr addrspace(1) %finalDest, i32 %dstItemIdx6.0.i
  store i32 %14, ptr addrspace(1) %arrayidx12.i, align 4
  %inc14.i = add i32 %dstItemIdx6.0.i, 1
  br label %for.cond7.i

for.end15.i:                                      ; preds = %for.cond7.i
  br label %test_atomic_kernel.inner.exit

test_atomic_kernel.inner.exit:                    ; preds = %if.end.i, %for.end15.i
  ret void
}

; Function Attrs: convergent
declare i32 @_Z8spirv.op.234.PU3AS4jjj(i32, ptr addrspace(4), i32, i32, i32) #1

; Function Attrs: convergent
declare void @_Z8spirv.op.228.PU3AS3jjj(i32, ptr addrspace(3), i32, i32, i32) #1

; Function Attrs: convergent noduplicate
declare void @_Z8spirv.op.224.jjj(i32, i32, i32, i32) #2

; Function Attrs: convergent
declare i32 @_Z8spirv.op.227.PU3AS3jj(i32, ptr addrspace(3), i32, i32) #1

; Function Attrs: memory(read)
declare i32 @clspv.wrap_constant_load.0(i32) #3

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent }
attributes #2 = { convergent noduplicate }
attributes #3 = { memory(read) }
attributes #4 = { nounwind }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 1, i32 4, i32 7}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 3, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ade3c6a6a88ed3a9b06c076406f196da9d3cc1b9)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = !{i32 0, i32 0, i32 1, i32 1, i32 3}
!8 = !{!"none", !"none", !"none", !"none", !"none"}
!9 = !{!"uint", !"uint", !"int*", !"int*", !"atomic_int*"}
!10 = !{!"uint", !"uint", !"int*", !"int*", !"_Atomic(int)*"}
!11 = !{!"", !"", !"", !"", !"volatile"}
!12 = !{i32 3}
!13 = !{!14, !15, !16, !17, !18}
!14 = !{!"finalDest", i32 2, i32 0, i32 0, i32 0, !"buffer"}
!15 = !{!"oldValues", i32 3, i32 1, i32 0, i32 0, !"buffer"}
!16 = !{!"destMemory", i32 4, i32 2, i32 0, i32 0, !"local"}
!17 = !{!"threadCount", i32 0, i32 -1, i32 32, i32 4, !"pod_pushconstant"}
!18 = !{!"numDestItems", i32 1, i32 -1, i32 36, i32 4, !"pod_pushconstant"}
