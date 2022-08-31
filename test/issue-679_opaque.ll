; RUN: clspv-opt --passes=three-element-vector-lowering %s -o %t --opaque-pointers=true
; RUN: FileCheck %s < %t

@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @test(ptr addrspace(1) %out, ptr addrspace(1) %in) #0 !kernel_arg_addr_space !4 !kernel_arg_access_qual !5 !kernel_arg_type !6 !kernel_arg_base_type !7 !kernel_arg_type_qual !8 !clspv.pod_args_impl !9 {
entry:
  %out.addr = alloca ptr addrspace(1)
  store ptr addrspace(1) null, ptr %out.addr
  %in.addr = alloca ptr addrspace(1)
  store ptr addrspace(1) null, ptr %in.addr
  %gid = alloca i32
  store i32 0, ptr %gid
  %x = alloca <3 x float>
  store <3 x float> zeroinitializer, ptr %x
  store ptr addrspace(1) %out, ptr %out.addr
  store ptr addrspace(1) %in, ptr %in.addr
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId
  store i32 %0, ptr %gid
  %1 = load i32, ptr %gid
  %2 = load ptr addrspace(1), ptr %in.addr
  %3 = mul i32 %1, 3
  %4 = add i32 %3, 0
  %5 = getelementptr float, ptr addrspace(1) %2, i32 %4
  %6 = load float, ptr addrspace(1) %5
  %7 = insertelement <3 x float> undef, float %6, i64 0
  %8 = add i32 %3, 1
  %9 = getelementptr float, ptr addrspace(1) %2, i32 %8
  %10 = load float, ptr addrspace(1) %9
  %11 = insertelement <3 x float> %7, float %10, i64 1
  %12 = add i32 %3, 2
  %13 = getelementptr float, ptr addrspace(1) %2, i32 %12
  %14 = load float, ptr addrspace(1) %13
  %15 = insertelement <3 x float> %11, float %14, i64 2
  store <3 x float> %15, ptr %x
  %16 = load <3 x float>, ptr %x
  %vecext = extractelement <3 x float> %16, i32 0
  %17 = load <3 x float>, ptr %x
  %vecext2 = extractelement <3 x float> %17, i32 1
  %add = fadd float %vecext, %vecext2
  %18 = load <3 x float>, ptr %x
  %vecext3 = extractelement <3 x float> %18, i32 2
  %add4 = fadd float %add, %vecext3
  %19 = load ptr addrspace(1), ptr %out.addr
  %20 = load i32, ptr %gid
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %19, i32 %20
  store float %add4, ptr addrspace(1) %arrayidx
  ret void
}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 15.0.0 (https://github.com/llvm/llvm-project 4c79e1a3f4eb790f40239833ae237e828ce07386)"}
!3 = !{!"clang version 12.0.0 (git@github.com:llvm/llvm-project.git 0c82fa677f24d8a9656af41ac9cc64ea4f818bc0)"}
!4 = !{i32 1, i32 1}
!5 = !{!"none", !"none"}
!6 = !{!"float*", !"float3*"}
!7 = !{!"float*", !"float __attribute__((ext_vector_type(3)))*"}
!8 = !{!"", !""}
!9 = !{i32 2}

; CHECK: %out.addr = alloca ptr addrspace(1)
; CHECK: store ptr addrspace(1) null, ptr %out.addr
; CHECK: %in.addr = alloca ptr addrspace(1)
; CHECK: store ptr addrspace(1) null, ptr %in.addr
; CHECK: %gid = alloca i32
; CHECK: store i32 0, ptr %gid
; CHECK: %x = alloca <4 x float>
; CHECK: store <4 x float> zeroinitializer, ptr %x
; CHECK: store ptr addrspace(1) %out, ptr %out.addr
; CHECK: store ptr addrspace(1) %in, ptr %in.addr
; CHECK: [[localid0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId
; CHECK: store i32 [[localid0]], ptr %gid
; CHECK: [[localid1:%[a-zA-Z0-9_.]+]] = load i32, ptr %gid
; CHECK: [[localid2:%[a-zA-Z0-9_.]+]] = load ptr addrspace(1), ptr %in.addr
; CHECK: [[localid3:%[a-zA-Z0-9_.]+]] = mul i32 [[localid1]], 3
; CHECK: [[localid4:%[a-zA-Z0-9_.]+]] = add i32 [[localid3]], 0
; CHECK: [[localid5:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[localid2]], i32 [[localid4]]
; CHECK: [[localid6:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[localid5]]
; CHECK: [[localid7:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> undef, float [[localid6]], i64 0
; CHECK: [[localid8:%[a-zA-Z0-9_.]+]] = add i32 [[localid3]], 1
; CHECK: [[localid9:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[localid2]], i32 [[localid8]]
; CHECK: [[localid10:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[localid9]]
; CHECK: [[localid11:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[localid7]], float [[localid10]], i64 1
; CHECK: [[localid12:%[a-zA-Z0-9_.]+]] = add i32 [[localid3]], 2
; CHECK: [[localid13:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(1) [[localid2]], i32 [[localid12]]
; CHECK: [[localid14:%[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) [[localid13]]
; CHECK: [[localid15:%[a-zA-Z0-9_.]+]] = insertelement <4 x float> [[localid11]], float [[localid14]], i64 2
; CHECK: store <4 x float> [[localid15]], ptr %x
; CHECK: [[localid16:%[a-zA-Z0-9_.]+]] = load <4 x float>, ptr %x
; CHECK: %vecext = extractelement <4 x float> [[localid16]], i32 0
; CHECK: [[localid17:%[a-zA-Z0-9_.]+]] = load <4 x float>, ptr %x
; CHECK: %vecext2 = extractelement <4 x float> [[localid17]], i32 1
; CHECK: %add = fadd float %vecext, %vecext2
; CHECK: [[localid18:%[a-zA-Z0-9_.]+]] = load <4 x float>, ptr %x
; CHECK: %vecext3 = extractelement <4 x float> [[localid18]], i32 2
; CHECK: %add4 = fadd float %add, %vecext3
; CHECK: [[localid19:%[a-zA-Z0-9_.]+]] = load ptr addrspace(1), ptr %out.addr
; CHECK: [[localid20:%[a-zA-Z0-9_.]+]] = load i32, ptr %gid
; CHECK: %arrayidx = getelementptr inbounds float, ptr addrspace(1) [[localid19]], i32 [[localid20]]
; CHECK: store float %add4, ptr addrspace(1) %arrayidx
