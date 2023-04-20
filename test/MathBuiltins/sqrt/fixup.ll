; RUN: clspv-opt --passes=fixup-builtins %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; CHECK: spir_kernel void @k1
; CHECK: store float 0xFFF8000000000000
define dso_local spir_kernel void @k1(ptr addrspace(1) align 4 %out) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %call = call spir_func float @_Z4sqrtf(float -1.000000e+00) #2
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 0
  store float %call, ptr addrspace(1) %arrayidx, align 4
  ret void
}

declare spir_func float @_Z4sqrtf(float) #1
declare spir_func float @_Z5rsqrtf(float) #1

; CHECK: spir_kernel void @k2
; CHECK: store float 0x3FF6A09E60000000
define dso_local spir_kernel void @k2(ptr addrspace(1) align 4 %out) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %call = call spir_func float @_Z4sqrtf(float 2.000000e+00) #2
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 0
  store float %call, ptr addrspace(1) %arrayidx, align 4
  ret void
}

; CHECK: spir_kernel void @kr2
; CHECK: store float 0x3FE6A09E60000000
define dso_local spir_kernel void @kr2(ptr addrspace(1) align 4 %out) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %call = call spir_func float @_Z5rsqrtf(float 2.000000e+00) #2
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 0
  store float %call, ptr addrspace(1) %arrayidx, align 4
  ret void
}

; CHECK: spir_kernel void @k3
; CHECK: [[fcmp:%[^ ]+]] = fcmp oge
; CHECK: [[sqrt:%[^ ]+]] = call spir_func float @_Z4sqrtf
; CHECK: [[select:%[^ ]+]] = select i1 [[fcmp]], float [[sqrt]], float 0x7FF8000000000000
; CHECK: store float [[select]]
define dso_local spir_kernel void @k3(ptr addrspace(1) align 4 %out) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %out, i32 0
  %0 = load float, ptr addrspace(1) %arrayidx, align 4
  %call = call spir_func float @_Z4sqrtf(float %0) #2
  %arrayidx1 = getelementptr inbounds float, ptr addrspace(1) %out, i32 0
  store float %call, ptr addrspace(1) %arrayidx1, align 4
  ret void
}

; CHECK: spir_kernel void @k4
; CHECK: store <2 x float> <float 0x3FF6A09E60000000, float 0xFFF8000000000000>
define dso_local spir_kernel void @k4(ptr addrspace(1) align 8 %out) #0 !kernel_arg_addr_space !5 !kernel_arg_access_qual !6 !kernel_arg_type !7 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %call = call spir_func <2 x float> @_Z4sqrtDv2_f(<2 x float> <float 2.000000e+00, float -1.000000e+00>) #2
  %arrayidx = getelementptr inbounds <2 x float>, ptr addrspace(1) %out, i32 0
  store <2 x float> %call, ptr addrspace(1) %arrayidx, align 8
  ret void
}

declare spir_func <2 x float> @_Z4sqrtDv2_f(<2 x float>) #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind willreturn memory(none) "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent nobuiltin nounwind willreturn memory(none) "no-builtins" }

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!opencl.spir.version = !{!2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2, !2}
!llvm.ident = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{i32 1, i32 2}
!3 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project be3764fecc263f7180bfada7ac61c5f8d799610e)"}
!4 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!5 = !{i32 1}
!6 = !{!"none"}
!7 = !{!"float*"}
!8 = !{!""}
!9 = !{i32 2}
