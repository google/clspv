; RUN: clspv-opt %s -o %t --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t

; Mid-pipeline IR of the companion .cl test: the kernel takes the address of
; a struct member and indexes through it, so the GEPs arrive LINKED
; (outer_t -> inner_t -> [4 x i32]). Merging the constant offsets yields
; 800 bits over a 128-bit element; the pass must merge into the correct
; member paths instead of truncating the division into the wrong element.

; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 1, i32 0
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 1, i32 1
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 1, i32 2
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 1, i32 3
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 5
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 1, i32 1, i32 %{{[a-zA-Z0-9.]+}}
; CHECK: getelementptr{{( inbounds)?( nuw)?}} %struct.outer_t, ptr %{{[^,]+}}, i32 0, i32 0, i32 0, i32 %{{[a-zA-Z0-9.]+}}


; ModuleID = 'gep_test.cl'
source_filename = "gep_test.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.outer_t = type { %struct.inner_t, %struct.inner_t }
%struct.inner_t = type { [4 x i32], [4 x i32], [4 x i32], [4 x i32], [4 x i32], i32 }

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind denormal_fpenv(dynamic)
define spir_kernel void @repro(ptr addrspace(1) align 4 %out, i32 %seed) #0 !kernel_arg_addr_space !0 !kernel_arg_access_qual !1 !kernel_arg_type !2 !kernel_arg_base_type !2 !kernel_arg_type_qual !3 !kernel_arg_name !77 !clspv.pod_args_impl !78 {
entry:
  %c.i = alloca %struct.outer_t, align 4
  store %struct.outer_t zeroinitializer, ptr %c.i, align 4
  %opad.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %w0.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad.i, i32 0, i32 1
  store i32 %seed, ptr %w0.i, align 4
  %add.i = add nsw i32 %seed, 1
  %opad1.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %w02.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad1.i, i32 0, i32 1
  %arrayidx3.i = getelementptr inbounds [4 x i32], ptr %w02.i, i32 0, i32 1
  store i32 %add.i, ptr %arrayidx3.i, align 4
  %add4.i = add nsw i32 %seed, 2
  %opad5.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %w06.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad5.i, i32 0, i32 1
  %arrayidx7.i = getelementptr inbounds [4 x i32], ptr %w06.i, i32 0, i32 2
  store i32 %add4.i, ptr %arrayidx7.i, align 4
  %add8.i = add nsw i32 %seed, 3
  %opad9.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %w010.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad9.i, i32 0, i32 1
  %arrayidx11.i = getelementptr inbounds [4 x i32], ptr %w010.i, i32 0, i32 3
  store i32 %add8.i, ptr %arrayidx11.i, align 4
  %add12.i = add nsw i32 %seed, 4
  %opad13.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %len.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad13.i, i32 0, i32 5
  store i32 %add12.i, ptr %len.i, align 4
  %opad14.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %w015.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad14.i, i32 0, i32 1
  %and.i = and i32 %seed, 3
  %arrayidx16.i = getelementptr inbounds [4 x i32], ptr %w015.i, i32 0, i32 %and.i
  %0 = load i32, ptr %arrayidx16.i, align 4
  %add17.i = add nsw i32 %0, 1
  %arrayidx18.i = getelementptr inbounds [4 x i32], ptr %w015.i, i32 0, i32 %and.i
  store i32 %add17.i, ptr %arrayidx18.i, align 4
  %1 = load i32, ptr %w015.i, align 4
  %opad20.i = getelementptr inbounds nuw %struct.outer_t, ptr %c.i, i32 0, i32 1
  %len21.i = getelementptr inbounds nuw %struct.inner_t, ptr %opad20.i, i32 0, i32 5
  %2 = load i32, ptr %len21.i, align 4
  %add22.i = add nsw i32 %1, %2
  store i32 %add22.i, ptr addrspace(1) %out, align 4
  %and24.i = and i32 %seed, 3
  %arrayidx25.i = getelementptr inbounds [4 x i32], ptr %c.i, i32 0, i32 %and24.i
  %3 = load i32, ptr %arrayidx25.i, align 4
  %arrayidx26.i = getelementptr inbounds i32, ptr addrspace(1) %out, i32 1
  store i32 %3, ptr addrspace(1) %arrayidx26.i, align 4
  ret void
}

; Function Attrs: alwaysinline convergent norecurse nounwind denormal_fpenv(dynamic)
define spir_func void @__clang_ocl_kern_imp_repro(ptr addrspace(1) align 4 %out, i32 %seed) #1 !kernel_arg_addr_space !0 !kernel_arg_access_qual !1 !kernel_arg_type !2 !kernel_arg_base_type !2 !kernel_arg_type_qual !3 !kernel_arg_name !77 {
entry:
  %c = alloca %struct.outer_t, align 4
  store %struct.outer_t zeroinitializer, ptr %c, align 4
  %opad = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w0 = getelementptr inbounds nuw %struct.inner_t, ptr %opad, i32 0, i32 1
  %arrayidx = getelementptr inbounds [4 x i32], ptr %w0, i32 0, i32 0
  store i32 %seed, ptr %arrayidx, align 4
  %add = add nsw i32 %seed, 1
  %opad1 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w02 = getelementptr inbounds nuw %struct.inner_t, ptr %opad1, i32 0, i32 1
  %arrayidx3 = getelementptr inbounds [4 x i32], ptr %w02, i32 0, i32 1
  store i32 %add, ptr %arrayidx3, align 4
  %add4 = add nsw i32 %seed, 2
  %opad5 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w06 = getelementptr inbounds nuw %struct.inner_t, ptr %opad5, i32 0, i32 1
  %arrayidx7 = getelementptr inbounds [4 x i32], ptr %w06, i32 0, i32 2
  store i32 %add4, ptr %arrayidx7, align 4
  %add8 = add nsw i32 %seed, 3
  %opad9 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w010 = getelementptr inbounds nuw %struct.inner_t, ptr %opad9, i32 0, i32 1
  %arrayidx11 = getelementptr inbounds [4 x i32], ptr %w010, i32 0, i32 3
  store i32 %add8, ptr %arrayidx11, align 4
  %add12 = add nsw i32 %seed, 4
  %opad13 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %len = getelementptr inbounds nuw %struct.inner_t, ptr %opad13, i32 0, i32 5
  store i32 %add12, ptr %len, align 4
  %opad14 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w015 = getelementptr inbounds nuw %struct.inner_t, ptr %opad14, i32 0, i32 1
  %and = and i32 %seed, 3
  %arrayidx16 = getelementptr inbounds [4 x i32], ptr %w015, i32 0, i32 %and
  %0 = load i32, ptr %arrayidx16, align 4
  %add17 = add nsw i32 %0, 1
  %arrayidx18 = getelementptr inbounds [4 x i32], ptr %w015, i32 0, i32 %and
  store i32 %add17, ptr %arrayidx18, align 4
  %arrayidx19 = getelementptr inbounds [4 x i32], ptr %w015, i32 0, i32 0
  %1 = load i32, ptr %arrayidx19, align 4
  %opad20 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %len21 = getelementptr inbounds nuw %struct.inner_t, ptr %opad20, i32 0, i32 5
  %2 = load i32, ptr %len21, align 4
  %add22 = add nsw i32 %1, %2
  %arrayidx23 = getelementptr inbounds i32, ptr addrspace(1) %out, i32 0
  store i32 %add22, ptr addrspace(1) %arrayidx23, align 4
  %ipad = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 0
  %h = getelementptr inbounds nuw %struct.inner_t, ptr %ipad, i32 0, i32 0
  %and24 = and i32 %seed, 3
  %arrayidx25 = getelementptr inbounds [4 x i32], ptr %h, i32 0, i32 %and24
  %3 = load i32, ptr %arrayidx25, align 4
  %arrayidx26 = getelementptr inbounds i32, ptr addrspace(1) %out, i32 1
  store i32 %3, ptr addrspace(1) %arrayidx26, align 4
  ret void
}

attributes #0 = { convergent norecurse nounwind denormal_fpenv(dynamic) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #1 = { alwaysinline convergent norecurse nounwind denormal_fpenv(dynamic) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }

!opencl.ocl.version = !{!4, !6}
!llvm.ident = !{!5}
!llvm.errno.tbaa = !{!11}
!llvm.module.flags = !{!12, !13, !14}
!_Z28clspv.entry_point_attributes = !{!75, !76}

!0 = !{i32 1, i32 0}
!1 = !{!"none", !"none"}
!2 = !{!"int*", !"int"}
!3 = !{!"", !""}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 24.0.0git (https://github.com/llvm/llvm-project 018a9e4a74ba5d383351bda907a8b116bc5d8c47)"}
!6 = !{i32 3, i32 0}
!7 = !{!"Simple C/C++ TBAA"}
!8 = !{!"omnipotent char", !7, i64 0}
!9 = !{!"int", !8, i64 0}
!10 = !{!"__libc_errno", !9, i64 0}
!11 = !{!10, !9, i64 0}
!12 = !{i32 7, !"frame-pointer", i32 2}
!13 = !{i32 1, !"ThinLTO", i32 0}
!14 = !{i32 1, !"EnableSplitLTOUnit", i32 1}
!75 = !{!"repro", !"kernel"}
!76 = !{!"__clang_ocl_kern_imp_repro", !"kernel"}
!77 = !{!"out", !"seed"}
!78 = !{i32 2}
