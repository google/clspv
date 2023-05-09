; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: declare spir_func float @_Z5frexpfPU3AS1i(float, ptr addrspace(1))

; CHECK-NOT: addrspacecast
; CHECK: call spir_func float @_Z5frexpfPU3AS1i(float {{.*}}, ptr addrspace(1)
; CHECK-NOT: addrspacecast

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @math_kernel(ptr addrspace(1) align 4 %out1, ptr addrspace(1) align 4 %out2, ptr addrspace(1) align 4 %in1) #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 16
  %1 = load i32, ptr addrspace(9) getelementptr (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1, i32 0), align 16
  %2 = call i32 @clspv.wrap_constant_load.0(i32 %1) #3
  %3 = add i32 %0, %2
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %in1, i32 %3
  %4 = load float, ptr addrspace(1) %arrayidx, align 4
  %add.ptr = getelementptr inbounds i32, ptr addrspace(1) %out2, i32 %3
  %add.ptr.ascast = addrspacecast ptr addrspace(1) %add.ptr to ptr addrspace(4)
  %call1 = call spir_func float @_Z5frexpfPU3AS4i(float %4, ptr addrspace(4) %add.ptr.ascast) #4
  %arrayidx2 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %3
  store float %call1, ptr addrspace(1) %arrayidx2, align 4
  ret void
}

; Function Attrs: convergent nounwind
declare spir_func float @_Z5frexpfPU3AS4i(float, ptr addrspace(4)) #1

; Function Attrs: memory(read)
declare i32 @clspv.wrap_constant_load.0(i32) #2

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { convergent nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { memory(read) }
attributes #3 = { nounwind }
attributes #4 = { convergent nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 1, i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 3, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project ade3c6a6a88ed3a9b06c076406f196da9d3cc1b9)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = !{i32 1, i32 1, i32 1}
!8 = !{!"none", !"none", !"none"}
!9 = !{!"float*", !"int*", !"float*"}
!10 = !{!"", !"", !""}
!11 = !{i32 3}
