; RUN: clspv-opt %s -o %t.ll --passes=three-element-vector-lowering

; CHECK: call { <4 x i8>, <4 x i8> } @_Z8spirv.op{{.*}}(i32 151, <4 x i8> %{{.*}}, <4 x i8>
; CHECK: call { <4 x i8>, <4 x i8> } @_Z8spirv.op{{.*}}(i32 149, <4 x i8> %{{.*}}, <4 x i8>

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @sample_test(ptr addrspace(1) align 1 %sourceA, ptr addrspace(1) align 1 %sourceB, ptr addrspace(1) align 1 %sourceC, ptr addrspace(1) align 1 %destValues) #0 !kernel_arg_addr_space !7 !kernel_arg_access_qual !8 !kernel_arg_type !9 !kernel_arg_base_type !9 !kernel_arg_type_qual !10 !clspv.pod_args_impl !11 {
entry:
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) getelementptr inbounds (%0, ptr addrspace(9) @__push_constants, i32 0, i32 1), align 4
  %2 = add i32 %0, %1
  %3 = mul i32 %2, 3
  %4 = add i32 %3, 0
  %5 = getelementptr i8, ptr addrspace(1) %sourceA, i32 %4
  %6 = load i8, ptr addrspace(1) %5, align 1
  %7 = insertelement <3 x i8> poison, i8 %6, i64 0
  %8 = add i32 %3, 1
  %9 = getelementptr i8, ptr addrspace(1) %sourceA, i32 %8
  %10 = load i8, ptr addrspace(1) %9, align 1
  %11 = insertelement <3 x i8> %7, i8 %10, i64 1
  %12 = add i32 %3, 2
  %13 = getelementptr i8, ptr addrspace(1) %sourceA, i32 %12
  %14 = load i8, ptr addrspace(1) %13, align 1
  %15 = insertelement <3 x i8> %11, i8 %14, i64 2
  %16 = mul i32 %2, 3
  %17 = add i32 %16, 0
  %18 = getelementptr i8, ptr addrspace(1) %sourceB, i32 %17
  %19 = load i8, ptr addrspace(1) %18, align 1
  %20 = insertelement <3 x i8> poison, i8 %19, i64 0
  %21 = add i32 %16, 1
  %22 = getelementptr i8, ptr addrspace(1) %sourceB, i32 %21
  %23 = load i8, ptr addrspace(1) %22, align 1
  %24 = insertelement <3 x i8> %20, i8 %23, i64 1
  %25 = add i32 %16, 2
  %26 = getelementptr i8, ptr addrspace(1) %sourceB, i32 %25
  %27 = load i8, ptr addrspace(1) %26, align 1
  %28 = insertelement <3 x i8> %24, i8 %27, i64 2
  %29 = mul i32 %2, 3
  %30 = add i32 %29, 0
  %31 = getelementptr i8, ptr addrspace(1) %sourceC, i32 %30
  %32 = load i8, ptr addrspace(1) %31, align 1
  %33 = insertelement <3 x i8> poison, i8 %32, i64 0
  %34 = add i32 %29, 1
  %35 = getelementptr i8, ptr addrspace(1) %sourceC, i32 %34
  %36 = load i8, ptr addrspace(1) %35, align 1
  %37 = insertelement <3 x i8> %33, i8 %36, i64 1
  %38 = add i32 %29, 2
  %39 = getelementptr i8, ptr addrspace(1) %sourceC, i32 %38
  %40 = load i8, ptr addrspace(1) %39, align 1
  %41 = insertelement <3 x i8> %37, i8 %40, i64 2
  %42 = call { <3 x i8>, <3 x i8> } @_Z8spirv.op.151.Dv3_hDv3_h(i32 151, <3 x i8> %15, <3 x i8> %28)
  %43 = extractvalue { <3 x i8>, <3 x i8> } %42, 0
  %44 = extractvalue { <3 x i8>, <3 x i8> } %42, 1
  %45 = call { <3 x i8>, <3 x i8> } @_Z8spirv.op.149.Dv3_hDv3_h(i32 149, <3 x i8> %43, <3 x i8> %41)
  %46 = extractvalue { <3 x i8>, <3 x i8> } %45, 0
  %47 = extractvalue { <3 x i8>, <3 x i8> } %45, 1
  %48 = or <3 x i8> %44, %47
  %49 = icmp eq <3 x i8> %48, zeroinitializer
  %50 = select <3 x i1> %49, <3 x i8> %46, <3 x i8> <i8 -1, i8 -1, i8 -1>
  %51 = mul i32 %2, 3
  %52 = add i32 %51, 0
  %53 = getelementptr i8, ptr addrspace(1) %destValues, i32 %52
  %54 = extractelement <3 x i8> %50, i64 0
  store i8 %54, ptr addrspace(1) %53, align 1
  %55 = add i32 %51, 1
  %56 = getelementptr i8, ptr addrspace(1) %destValues, i32 %55
  %57 = extractelement <3 x i8> %50, i64 1
  store i8 %57, ptr addrspace(1) %56, align 1
  %58 = add i32 %51, 2
  %59 = getelementptr i8, ptr addrspace(1) %destValues, i32 %58
  %60 = extractelement <3 x i8> %50, i64 2
  store i8 %60, ptr addrspace(1) %59, align 1
  ret void
}

; Function Attrs: memory(none)
declare { <3 x i8>, <3 x i8> } @_Z8spirv.op.151.Dv3_hDv3_h(i32, <3 x i8>, <3 x i8>) #1

; Function Attrs: memory(none)
declare { <3 x i8>, <3 x i8> } @_Z8spirv.op.149.Dv3_hDv3_h(i32, <3 x i8>, <3 x i8>) #1

attributes #0 = { convergent norecurse nounwind "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="false" }
attributes #1 = { memory(none) }

!llvm.module.flags = !{!1, !2}
!opencl.ocl.version = !{!3}
!opencl.spir.version = !{!3, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4, !4}
!llvm.ident = !{!5, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6, !6}

!0 = !{i32 1, i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 3, i32 0}
!4 = !{i32 1, i32 2}
!5 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project fc78ebad051ac3e7564efc1a38a5e1faa8f30bf1)"}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 22b564c64b736f5a422b3967720c871c8f9eee9b)"}
!7 = !{i32 1, i32 1, i32 1, i32 1}
!8 = !{!"none", !"none", !"none", !"none"}
!9 = !{!"uchar*", !"uchar*", !"uchar*", !"uchar*"}
!10 = !{!"", !"", !"", !""}
!11 = !{i32 3}

