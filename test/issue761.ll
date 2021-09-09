; RUN: clspv -x ir %s -o %t
; RUN: spirv-val %t

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir-unknown-unknown"

%"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer" = type { float addrspace(1)* }

; Function Attrs: nounwind
define spir_kernel void @_D8dcompute5tests12dummykernels5saxpyFS3ldcQBp__T7PointerVEQuQCh9AddrSpacei1TfZQBefQBtQBwkZv(float addrspace(1)* %0, float %1, float addrspace(1)* %2, float addrspace(1)* %3, i32 %4) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_type_qual !8 !kernel_arg_base_type !7 {
  %6 = alloca %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", align 4
  %7 = alloca float, align 4
  %8 = alloca %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", align 4
  %9 = alloca %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = bitcast %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %6 to float addrspace(1)**
  store float addrspace(1)* %0, float addrspace(1)** %12, align 4
  store float %1, float* %7, align 4
  %13 = bitcast %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %8 to float addrspace(1)**
  store float addrspace(1)* %2, float addrspace(1)** %13, align 4
  %14 = bitcast %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %9 to float addrspace(1)**
  store float addrspace(1)* %3, float addrspace(1)** %14, align 4
  store i32 %4, i32* %10, align 4
  %15 = call spir_func i32 @_D8dcompute3std5index11GlobalIndex__T1xZQdFNaNbNdNiZk() #0
  store i32 %15, i32* %11, align 4
  %16 = load i32, i32* %11, align 4
  %17 = load i32, i32* %10, align 4
  %18 = icmp uge i32 %16, %17
  br i1 %18, label %19, label %21

19:                                               ; preds = %5
  ret void

20:                                               ; No predecessors!
  br label %21

21:                                               ; preds = %20, %5
  %22 = getelementptr inbounds %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %6, i32 0, i32 0
  %23 = load float addrspace(1)*, float addrspace(1)** %22, align 4
  %24 = load i32, i32* %11, align 4
  %25 = getelementptr inbounds float, float addrspace(1)* %23, i32 %24
  %26 = load float, float* %7, align 4
  %27 = getelementptr inbounds %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %8, i32 0, i32 0
  %28 = load float addrspace(1)*, float addrspace(1)** %27, align 4
  %29 = load i32, i32* %11, align 4
  %30 = getelementptr inbounds float, float addrspace(1)* %28, i32 %29
  %31 = load float, float addrspace(1)* %30, align 4
  %32 = fmul float %26, %31
  %33 = getelementptr inbounds %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer", %"ldc.dcompute.Pointer!(AddrSpace.Global, float).Pointer"* %9, i32 0, i32 0
  %34 = load float addrspace(1)*, float addrspace(1)** %33, align 4
  %35 = load i32, i32* %11, align 4
  %36 = getelementptr inbounds float, float addrspace(1)* %34, i32 %35
  %37 = load float, float addrspace(1)* %36, align 4
  %38 = fadd float %32, %37
  store float %38, float addrspace(1)* %25, align 4
  ret void
}

; Function Attrs: nounwind
define spir_func i32 @_D8dcompute3std5index11GlobalIndex__T1xZQdFNaNbNdNiZk() #0 {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0) #1
  %2 = insertelement <3 x i32> undef, i32 %1, i32 0
  %3 = call spir_func i32 @_Z13get_global_idj(i32 1) #1
  %4 = insertelement <3 x i32> %2, i32 %3, i32 1
  %5 = call spir_func i32 @_Z13get_global_idj(i32 2) #1
  %6 = insertelement <3 x i32> %4, i32 %5, i32 2
  %7 = extractelement <3 x i32> %6, i32 0
  ret i32 %7
}

; Function Attrs: nounwind readnone willreturn
declare spir_func i32 @_Z13get_global_idj(i32) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone willreturn }

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.ocl.version = !{!2}
!opencl.used.extensions = !{!3}
!opencl.used.optional.core.features = !{!3}
!spirv.Generator = !{!4}

!0 = !{i32 1, i32 2}
!1 = !{i32 3, i32 200000}
!2 = !{i32 2, i32 0}
!3 = !{}
!4 = !{i16 6, i16 14}
!5 = !{i32 1, i32 0, i32 1, i32 1, i32 0}
!6 = !{!"none", !"none", !"none", !"none", !"none"}
!7 = !{!"float*", !"float", !"float*", !"float*", !"int"}
!8 = !{!"", !"", !"", !"", !""}
