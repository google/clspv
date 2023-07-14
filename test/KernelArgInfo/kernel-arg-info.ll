; RUN: clspv-opt %s -o %t.ll --passes=kernel-argnames-to-metadata
; RUN: FileCheck %s < %t.ll

; CHECK: !kernel_arg_name [[id:![0-9]*]]
; CHECK: [[id]] = !{!"A", !"SEC", !"TER", !"QUA", !"im0", !"im1", !"ptr"}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

@.str = private unnamed_addr addrspace(2) constant [8 x i8] c" kernel\00", section "llvm.metadata"
@.str.1 = private unnamed_addr addrspace(2) constant [118 x i8] c"/usr/local/google/home/rjodin/work/clvk/external/clspv/test/KernelArgInfo/kernel-arg-info-physical-storage-buffers.cl\00", section "llvm.metadata"
@llvm.global.annotations = appending global [1 x { ptr, ptr addrspace(2), ptr addrspace(2), i32, ptr addrspace(2) }] [{ ptr, ptr addrspace(2), ptr addrspace(2), i32, ptr addrspace(2) } { ptr @foo, ptr addrspace(2) @.str, ptr addrspace(2) @.str.1, i32 6, ptr addrspace(2) null }], section "llvm.metadata"

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @foo(ptr addrspace(1) align 16 %A, ptr addrspace(3) align 4 %SEC, ptr addrspace(2) align 4 %TER, i32 %QUA, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %im0, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %im1, ptr addrspace(1) noalias align 4 %ptr) #0 !kernel_arg_addr_space !6 !kernel_arg_access_qual !7 !kernel_arg_type !8 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 {
entry:
  %A.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %A.addr, align 8
  %SEC.addr = alloca ptr addrspace(3), align 8
  store ptr addrspace(3) null, ptr %SEC.addr, align 8
  %TER.addr = alloca ptr addrspace(2), align 8
  store ptr addrspace(2) null, ptr %TER.addr, align 8
  %QUA.addr = alloca i32, align 4
  store i32 0, ptr %QUA.addr, align 4
  %im0.addr = alloca target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), align 8
  store target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) zeroinitializer, ptr %im0.addr, align 8
  %im1.addr = alloca target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), align 8
  store target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) zeroinitializer, ptr %im1.addr, align 8
  %ptr.addr = alloca ptr addrspace(1), align 8
  store ptr addrspace(1) null, ptr %ptr.addr, align 8
  %tmp = alloca <4 x float>, align 16
  store <4 x float> zeroinitializer, ptr %tmp, align 16
  %.compoundliteral = alloca <4 x i32>, align 16
  store <4 x i32> zeroinitializer, ptr %.compoundliteral, align 16
  %.compoundliteral1 = alloca <4 x i32>, align 16
  store <4 x i32> zeroinitializer, ptr %.compoundliteral1, align 16
  %.compoundliteral10 = alloca <2 x i32>, align 8
  store <2 x i32> zeroinitializer, ptr %.compoundliteral10, align 8
  %.compoundliteral11 = alloca <2 x i32>, align 8
  store <2 x i32> zeroinitializer, ptr %.compoundliteral11, align 8
  store ptr addrspace(1) %A, ptr %A.addr, align 8
  store ptr addrspace(3) %SEC, ptr %SEC.addr, align 8
  store ptr addrspace(2) %TER, ptr %TER.addr, align 8
  store i32 %QUA, ptr %QUA.addr, align 4
  store target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %im0, ptr %im0.addr, align 8
  store target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %im1, ptr %im1.addr, align 8
  store ptr addrspace(1) %ptr, ptr %ptr.addr, align 8
  store <4 x i32> zeroinitializer, ptr %.compoundliteral, align 16
  %0 = load <4 x i32>, ptr %.compoundliteral, align 16
  %1 = load ptr addrspace(1), ptr %A.addr, align 8
  %arrayidx = getelementptr inbounds <4 x i32>, ptr addrspace(1) %1, i64 0
  store <4 x i32> %0, ptr addrspace(1) %arrayidx, align 16
  %2 = load ptr addrspace(3), ptr %SEC.addr, align 8
  store float 0.000000e+00, ptr addrspace(3) %2, align 4
  %3 = load ptr addrspace(2), ptr %TER.addr, align 8
  %4 = load <2 x i16>, ptr addrspace(2) %3, align 4
  %5 = extractelement <2 x i16> %4, i64 0
  %conv = sext i16 %5 to i32
  %vecinit = insertelement <4 x i32> undef, i32 %conv, i32 0
  %vecinit2 = insertelement <4 x i32> %vecinit, i32 0, i32 1
  %vecinit3 = insertelement <4 x i32> %vecinit2, i32 0, i32 2
  %vecinit4 = insertelement <4 x i32> %vecinit3, i32 0, i32 3
  store <4 x i32> %vecinit4, ptr %.compoundliteral1, align 16
  %6 = load <4 x i32>, ptr %.compoundliteral1, align 16
  %7 = load ptr addrspace(1), ptr %A.addr, align 8
  %arrayidx5 = getelementptr inbounds <4 x i32>, ptr addrspace(1) %7, i64 1
  store <4 x i32> %6, ptr addrspace(1) %arrayidx5, align 16
  %8 = load i32, ptr %QUA.addr, align 4
  %splat.splatinsert = insertelement <4 x i32> poison, i32 %8, i64 0
  %splat.splat = shufflevector <4 x i32> %splat.splatinsert, <4 x i32> poison, <4 x i32> zeroinitializer
  %9 = load ptr addrspace(1), ptr %A.addr, align 8
  %arrayidx6 = getelementptr inbounds <4 x i32>, ptr addrspace(1) %9, i64 2
  store <4 x i32> %splat.splat, ptr addrspace(1) %arrayidx6, align 16
  %10 = load ptr addrspace(1), ptr %ptr.addr, align 8
  %11 = load volatile i32, ptr addrspace(1) %10, align 4
  %splat.splatinsert7 = insertelement <4 x i32> poison, i32 %11, i64 0
  %splat.splat8 = shufflevector <4 x i32> %splat.splatinsert7, <4 x i32> poison, <4 x i32> zeroinitializer
  %12 = load ptr addrspace(1), ptr %A.addr, align 8
  %arrayidx9 = getelementptr inbounds <4 x i32>, ptr addrspace(1) %12, i64 3
  store <4 x i32> %splat.splat8, ptr addrspace(1) %arrayidx9, align 16
  %13 = load target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), ptr %im0.addr, align 8
  store <2 x i32> zeroinitializer, ptr %.compoundliteral10, align 8
  %14 = load <2 x i32>, ptr %.compoundliteral10, align 8
  %call = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %13, <2 x i32> %14) #3
  store <4 x float> %call, ptr %tmp, align 16
  %15 = load target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), ptr %im1.addr, align 8
  store <2 x i32> zeroinitializer, ptr %.compoundliteral11, align 8
  %16 = load <2 x i32>, ptr %.compoundliteral11, align 8
  %17 = load <4 x float>, ptr %tmp, align 16
  call spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %15, <2 x i32> %16, <4 x float> %17) #4
  ret void
}

; Function Attrs: convergent nounwind willreturn memory(read)
declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_roDv2_i(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0), <2 x i32>) #1

; Function Attrs: convergent nounwind
declare spir_func void @_Z12write_imagef14ocl_image2d_woDv2_iDv4_f(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1), <2 x i32>, <4 x float>) #2

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind willreturn memory(read) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #3 = { convergent nobuiltin nounwind willreturn memory(read) "no-builtins" }
attributes #4 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!llvm.ident = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"direct-access-external-data", i32 0}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 1, i32 2}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ab674234c440ed27302f58eeccc612c83b32c43f)"}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 3401a5f7584a2f12a90a7538aee2ae37038c82a9)"}
!6 = !{i32 1, i32 3, i32 2, i32 0, i32 1, i32 1, i32 1}
!7 = !{!"none", !"none", !"none", !"none", !"read_only", !"write_only", !"none"}
!8 = !{!"int4*", !"float*", !"short2*", !"int", !"image2d_t", !"image2d_t", !"int*"}
!9 = !{!"int __attribute__((ext_vector_type(4)))*", !"float*", !"short __attribute__((ext_vector_type(2)))*", !"int", !"image2d_t", !"image2d_t", !"int*"}
!10 = !{!"", !"", !"const", !"", !"", !"", !"restrict const volatile"}
