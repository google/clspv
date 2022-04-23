; RUN: clspv-opt -GepLoopVar %s -o %t.ll
; RUN: FileCheck %s < %t.ll
; ModuleID = '/home/pedols01/src/clspv/test/private_ptr_phi.cl'
source_filename = "private_ptr_phi.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @test(i32 addrspace(1)* %buffer, i32 addrspace(2)* %ends) #0 !kernel_arg_addr_space !1 !kernel_arg_access_qual !2 !kernel_arg_type !3 !kernel_arg_base_type !3 !kernel_arg_type_qual !4 !clspv.pod_args_impl !5 {
entry:
  %data = alloca [16 x i32], align 4
  %data.repack = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 0
  store i32 0, i32* %data.repack, align 4
  %data.repack1 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 1
  store i32 0, i32* %data.repack1, align 4
  %data.repack2 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 2
  store i32 0, i32* %data.repack2, align 4
  %data.repack3 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 3
  store i32 0, i32* %data.repack3, align 4
  %data.repack4 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 4
  store i32 0, i32* %data.repack4, align 4
  %data.repack5 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 5
  store i32 0, i32* %data.repack5, align 4
  %data.repack6 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 6
  store i32 0, i32* %data.repack6, align 4
  %data.repack7 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 7
  store i32 0, i32* %data.repack7, align 4
  %data.repack8 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 8
  store i32 0, i32* %data.repack8, align 4
  %data.repack9 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 9
  store i32 0, i32* %data.repack9, align 4
  %data.repack10 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 10
  store i32 0, i32* %data.repack10, align 4
  %data.repack11 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 11
  store i32 0, i32* %data.repack11, align 4
  %data.repack12 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 12
  store i32 0, i32* %data.repack12, align 4
  %data.repack13 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 13
  store i32 0, i32* %data.repack13, align 4
  %data.repack14 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 14
  store i32 0, i32* %data.repack14, align 4
  %data.repack15 = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 15
  store i32 0, i32* %data.repack15, align 4
  %arraydecay = getelementptr inbounds [16 x i32], [16 x i32]* %data, i32 0, i32 0
  %0 = load i32, i32 addrspace(2)* %ends, align 4
  %1 = call i32 @clspv.wrap_constant_load.0(i32 %0) #2
  br label %for.cond.i

for.cond.i:                                       ; preds = %for.body.i, %entry
  %i.0.i = phi i32 [ 0, %entry ], [ %inc.i, %for.body.i ]
  ; CHECK: %LoopGEPOffset = phi i32 [ 0, %entry ], [ %LoopGEPInc, %for.body.i ]
  ; CHECK-NOT: %data.addr.0.i = phi i32* [ %arraydecay, %entry ], [ %add.ptr4.i, %for.body.i ]
  %data.addr.0.i = phi i32* [ %arraydecay, %entry ], [ %add.ptr4.i, %for.body.i ]
  %buffer.addr.0.i = phi i32 addrspace(1)* [ %buffer, %entry ], [ %add.ptr.i, %for.body.i ]
  %cmp.i = icmp slt i32 %i.0.i, %1
  br i1 %cmp.i, label %for.body.i, label %load_data.exit

for.body.i:                                       ; preds = %for.cond.i
  ; CHECK: %LoopGEPReplacement = getelementptr [16 x i32], [16 x i32]* %data, i32 0, i32 %LoopGEPOffset
  %arrayidx.i = getelementptr inbounds i32, i32 addrspace(1)* %buffer.addr.0.i, i32 %i.0.i
  %2 = load i32, i32 addrspace(1)* %arrayidx.i, align 4
  ; CHECK: %arrayidx1.i = getelementptr inbounds i32, i32* %LoopGEPReplacement, i32 %i.0.i
  ; CHECK-NOT: %arrayidx1.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 %i.0.i
  %arrayidx1.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 %i.0.i
  store i32 %2, i32* %arrayidx1.i, align 4
  %arrayidx2.i = getelementptr inbounds i32, i32 addrspace(1)* %buffer.addr.0.i, i32 %i.0.i
  %3 = load i32, i32 addrspace(1)* %arrayidx2.i, align 4
  ; CHECK: %arrayidx3.i = getelementptr inbounds i32, i32* %LoopGEPReplacement, i32 %i.0.i
  ; CHECK-NOT: %arrayidx3.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 %i.0.i
  %arrayidx3.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 %i.0.i
  store i32 %3, i32* %arrayidx3.i, align 4
  ; CHECK: %LoopGEPInc = add i32 %LoopGEPOffset, 2
  ; CHECK-NOT: %add.ptr4.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 2
  %add.ptr4.i = getelementptr inbounds i32, i32* %data.addr.0.i, i32 2
  %add.ptr.i = getelementptr inbounds i32, i32 addrspace(1)* %buffer.addr.0.i, i32 2
  %inc.i = add nuw nsw i32 %i.0.i, 1
  br label %for.cond.i

load_data.exit:                                   ; preds = %for.cond.i
  ret void
}

; Function Attrs: readonly
declare i32 @clspv.wrap_constant_load.0(i32 %0) #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { readonly }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"none", !"none"}
!3 = !{!"int*", !"int*"}
!4 = !{!"", !"const"}
!5 = !{i32 2}

