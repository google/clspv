; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer --producer-out-file %t.spv --decorate-nonuniform
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

; CHECK: OpCapability ShaderNonUniform
; CHECK: OpExtension "SPV_EXT_descriptor_indexing"
; CHECK: OpDecorate [[select:%[^ ]+]] NonUniform
; CHECK: OpDecorate [[ptr:%[^ ]+]] NonUniform
; CHECK: [[select]] = OpSelect
; CHECK-NEXT: [[ptr]] = OpPtrAccessChain
; CHECK-NEXT: OpLoad {{.*}} [[ptr]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: readwrite, inaccessiblemem: none)
define dso_local spir_kernel void @test(<2 x i8> addrspace(1)* nocapture readonly align 2 %srcA, <2 x i8> addrspace(1)* nocapture readonly align 2 %srcB, i8 addrspace(1)* nocapture readonly align 1 %srcC, <2 x i8> addrspace(1)* nocapture writeonly align 2 %dst) local_unnamed_addr #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !8 !kernel_arg_type_qual !9 !clspv.pod_args_impl !10 {
entry:
  %0 = call { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <2 x i8>] } zeroinitializer)
  %1 = getelementptr { [0 x <2 x i8>] }, { [0 x <2 x i8>] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x <2 x i8>] } zeroinitializer)
  %3 = getelementptr { [0 x <2 x i8>] }, { [0 x <2 x i8>] } addrspace(1)* %2, i32 0, i32 0, i32 0
  %4 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x i8] } zeroinitializer)
  %5 = call { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.3(i32 0, i32 3, i32 0, i32 3, i32 3, i32 0, { [0 x <2 x i8>] } zeroinitializer)
  %6 = getelementptr <3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i32 0, i32 0
  %7 = load i32, i32 addrspace(5)* %6, align 16
  %8 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %4, i32 0, i32 0, i32 %7
  %9 = load i8, i8 addrspace(1)* %8, align 1
  %tobool.not = icmp eq i8 %9, 0
  %srcB.srcA = select i1 %tobool.not, <2 x i8> addrspace(1)* %3, <2 x i8> addrspace(1)* %1
  %cond.in = getelementptr inbounds <2 x i8>, <2 x i8> addrspace(1)* %srcB.srcA, i32 %7
  %cond = load <2 x i8>, <2 x i8> addrspace(1)* %cond.in, align 2
  %10 = getelementptr { [0 x <2 x i8>] }, { [0 x <2 x i8>] } addrspace(1)* %5, i32 0, i32 0, i32 %7
  store <2 x i8> %cond, <2 x i8> addrspace(1)* %10, align 2
  ret void
}

declare { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x i8>] })

declare { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x <2 x i8>] })

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare { [0 x <2 x i8>] } addrspace(1)* @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { [0 x <2 x i8>] })

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: readwrite, inaccessiblemem: none) "frame-pointer"="none" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}
!llvm.ident = !{!2, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3, !3}
!clspv.descriptor.index = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 16.0.0 (https://github.com/llvm/llvm-project afc159bbf12ac96298070f916a35321e7953a7b4)"}
!3 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!4 = !{i32 1}
!5 = !{i32 1, i32 1, i32 1, i32 1}
!6 = !{!"none", !"none", !"none", !"none"}
!7 = !{!"char2*", !"char2*", !"char*", !"char2*"}
!8 = !{!"char __attribute__((ext_vector_type(2)))*", !"char __attribute__((ext_vector_type(2)))*", !"char*", !"char __attribute__((ext_vector_type(2)))*"}
!9 = !{!"", !"", !"", !""}
!10 = !{i32 2}

