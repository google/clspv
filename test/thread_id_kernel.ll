; RUN: clspv -cl-std=CL2.0 -inline-entry-points -x=ir %s -o %t.spv -arch=spir
; RUN: spirv-dis -o %t.spvasm %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

; ModuleID = 'thread_id_kernel.ll'
target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: noinline nounwind
; CHECK: [[_void:%[a-zA-Z0-9_]+]] = OpTypeVoid
; CHECK: {{.*}} = OpTypeFunction [[_void]]
; CHECK: [[__ptr_StorageBuffer_uint:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer {{.*}}
define spir_kernel void @_Z16thread_id_kernelPKiPi(i32 addrspace(1)* %input.coerce, i32 addrspace(1)* %output.coerce) #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_type_qual !7 !kernel_arg_base_type !6 {
entry:
  %input = alloca i32 addrspace(4)*, align 4
  %output = alloca i32 addrspace(4)*, align 4
  %input.addr = alloca i32 addrspace(4)*, align 4
  %output.addr = alloca i32 addrspace(4)*, align 4
  %input.ascast = addrspacecast i32 addrspace(4)** %input to i32 addrspace(4)* addrspace(4)*
  %output.ascast = addrspacecast i32 addrspace(4)** %output to i32 addrspace(4)* addrspace(4)*
  %input.addr.ascast = addrspacecast i32 addrspace(4)** %input.addr to i32 addrspace(4)* addrspace(4)*
  %output.addr.ascast = addrspacecast i32 addrspace(4)** %output.addr to i32 addrspace(4)* addrspace(4)*
  %0 = addrspacecast i32 addrspace(1)* %input.coerce to i32 addrspace(4)*
  store i32 addrspace(4)* %0, i32 addrspace(4)* addrspace(4)* %input.ascast, align 4
  %input1 = load i32 addrspace(4)*, i32 addrspace(4)* addrspace(4)* %input.ascast, align 4
  %1 = addrspacecast i32 addrspace(1)* %output.coerce to i32 addrspace(4)*
  store i32 addrspace(4)* %1, i32 addrspace(4)* addrspace(4)* %output.ascast, align 4
  %output2 = load i32 addrspace(4)*, i32 addrspace(4)* addrspace(4)* %output.ascast, align 4
  store i32 addrspace(4)* %input1, i32 addrspace(4)* addrspace(4)* %input.addr.ascast, align 4
  store i32 addrspace(4)* %output2, i32 addrspace(4)* addrspace(4)* %output.addr.ascast, align 4
  %2 = load i32 addrspace(4)*, i32 addrspace(4)* addrspace(4)* %input.addr.ascast, align 4
  %3 = call spir_func i32 @_Z13get_global_idj(i32 0) #1
  %4 = insertelement <3 x i32> undef, i32 %3, i32 0
  %5 = call spir_func i32 @_Z13get_global_idj(i32 1) #1
  %6 = insertelement <3 x i32> %4, i32 %5, i32 1
  %7 = call spir_func i32 @_Z13get_global_idj(i32 2) #1
  %8 = insertelement <3 x i32> %6, i32 %7, i32 2
  %call = extractelement <3 x i32> %8, i32 0
  %arrayidx = getelementptr inbounds i32, i32 addrspace(4)* %2, i32 %call
  %9 = load i32, i32 addrspace(4)* %arrayidx, align 4
  ; CHECK: [[_42:%[a-zA-Z0-9_]+]] = OpShiftLeftLogical {{.*}} {{.*}} {{.*}}
  %mul = mul nsw i32 %9, 2
  %10 = load i32 addrspace(4)*, i32 addrspace(4)* addrspace(4)* %output.addr.ascast, align 4
  %11 = call spir_func i32 @_Z13get_global_idj(i32 0) #1
  %12 = insertelement <3 x i32> undef, i32 %11, i32 0
  %13 = call spir_func i32 @_Z13get_global_idj(i32 1) #1
  %14 = insertelement <3 x i32> %12, i32 %13, i32 1
  %15 = call spir_func i32 @_Z13get_global_idj(i32 2) #1
  %16 = insertelement <3 x i32> %14, i32 %15, i32 2
  %call3 = extractelement <3 x i32> %16, i32 0
  %arrayidx4 = getelementptr inbounds i32, i32 addrspace(4)* %10, i32 %call3
  ; CHECK: [[_43:%[a-zA-Z0-9_]+]] = OpAccessChain [[__ptr_StorageBuffer_uint]] {{.*}} {{.*}} {{.*}}
  ; CHECK: OpStore [[_43]] [[_42]]
  store i32 %mul, i32 addrspace(4)* %arrayidx4, align 4
  ret void
}

; Function Attrs: nounwind readnone willreturn
declare spir_func i32 @_Z13get_global_idj(i32) #1

attributes #0 = { noinline nounwind }
attributes #1 = { nounwind readnone willreturn }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!0}
!opencl.ocl.version = !{!0}
!opencl.used.extensions = !{!2}
!opencl.used.optional.core.features = !{!2}
!spirv.Generator = !{!3}

!0 = !{i32 1, i32 2}
!1 = !{i32 3, i32 102000}
!2 = !{}
!3 = !{i16 6, i16 14}
!4 = !{i32 1, i32 1}
!5 = !{!"none", !"none"}
!6 = !{!"int*", !"int*"}
!7 = !{!"", !""}
