; RUN: clspv-opt %s -o %t.ll --passes=long-vector-lowering
; RUN: FileCheck %s < %t.ll

; CHECK-COUNT-24: call spir_func float @_Z5atan2ff(float

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @atan2LongVecTest(ptr addrspace(1) align 32 %inout8, ptr addrspace(1) align 64 %inout16) #0 !kernel_arg_addr_space !8 !kernel_arg_access_qual !9 !kernel_arg_type !10 !kernel_arg_base_type !11 !kernel_arg_type_qual !12 !kernel_arg_name !13 !clspv.pod_args_impl !14 {
entry:
  %arrayidx = getelementptr inbounds <8 x float>, ptr addrspace(1) %inout8, i32 0
  %0 = load <8 x float>, ptr addrspace(1) %arrayidx, align 32
  %arrayidx1 = getelementptr inbounds <8 x float>, ptr addrspace(1) %inout8, i32 1
  %1 = load <8 x float>, ptr addrspace(1) %arrayidx1, align 32
  %call = call spir_func <8 x float> @_Z5atan2Dv8_fS_(<8 x float> %0, <8 x float> %1) #2
  %arrayidx2 = getelementptr inbounds <8 x float>, ptr addrspace(1) %inout8, i32 0
  store <8 x float> %call, ptr addrspace(1) %arrayidx2, align 32
  %arrayidx3 = getelementptr inbounds <16 x float>, ptr addrspace(1) %inout16, i32 0
  %2 = load <16 x float>, ptr addrspace(1) %arrayidx3, align 64
  %arrayidx4 = getelementptr inbounds <16 x float>, ptr addrspace(1) %inout16, i32 1
  %3 = load <16 x float>, ptr addrspace(1) %arrayidx4, align 64
  %call5 = call spir_func <16 x float> @_Z5atan2Dv16_fS_(<16 x float> %2, <16 x float> %3) #2
  %arrayidx6 = getelementptr inbounds <16 x float>, ptr addrspace(1) %inout16, i32 0
  store <16 x float> %call5, ptr addrspace(1) %arrayidx6, align 64
  ret void
}

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !12 dso_local spir_func <8 x float> @_Z5atan2Dv8_fS_(<8 x float> noundef, <8 x float> noundef) #1

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !12 dso_local spir_func <16 x float> @_Z5atan2Dv16_fS_(<16 x float> noundef, <16 x float> noundef) #1

attributes #0 = { convergent mustprogress norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent noinline norecurse nounwind "frame-pointer"="all" "llvm.assume"="clspv_libclc_builtin" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #2 = { convergent nobuiltin nounwind willreturn memory(none) "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}
!_Z28clspv.entry_point_attributes = !{!7}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 2, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 76f20099a5ab72a261661ecb545dceed52e5592d)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 3401a5f7584a2f12a90a7538aee2ae37038c82a9)"}
!7 = !{!"atan2LongVecTest", !" __kernel"}
!8 = !{i32 1, i32 1}
!9 = !{!"none", !"none"}
!10 = !{!"float8*", !"float16*"}
!11 = !{!"float __attribute__((ext_vector_type(8)))*", !"float __attribute__((ext_vector_type(16)))*"}
!12 = !{!"", !""}
!13 = !{!"inout8", !"inout16"}
!14 = !{i32 2}
