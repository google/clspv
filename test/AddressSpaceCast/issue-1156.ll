; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: call spir_func float @_Z5frexpfPi(float
; CHECK: call spir_func float @_Z6remquoffPi(float
; CHECK: call spir_func float @_Z4modffPf(float
; CHECK: call spir_func float @_Z5fractfPf(float

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32> }

@clspv.builtins.used = appending global [12 x ptr] [ptr @_Z5frexpfPi, ptr @_Z5frexpfPU3AS1i, ptr @_Z5frexpfPU3AS3i, ptr @_Z6remquoffPi, ptr @_Z6remquoffPU3AS1i, ptr @_Z6remquoffPU3AS3i, ptr @_Z4modffPf, ptr @_Z4modffPU3AS1f, ptr @_Z4modffPU3AS3f, ptr @_Z5fractfPf, ptr @_Z5fractfPU3AS1f, ptr @_Z5fractfPU3AS3f], section "llvm.metadata"
@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_GlobalInvocationId = addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @test1(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out1, ptr addrspace(1) align 4 %out2) #0 !kernel_arg_addr_space !12 !kernel_arg_access_qual !13 !kernel_arg_type !14 !kernel_arg_base_type !14 !kernel_arg_type_qual !15 !kernel_arg_name !16 !clspv.pod_args_impl !17 {
entry:
  %iexp = alloca i32, align 4
  store i32 0, ptr %iexp, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) @__push_constants, align 4
  %2 = add i32 %0, %1
  store i32 0, ptr %iexp, align 4
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %in, i32 %2
  %3 = load float, ptr addrspace(1) %arrayidx, align 4
  %iexp.ascast = addrspacecast ptr %iexp to ptr addrspace(4)
  %call1 = call spir_func float @_Z5frexpfPU3AS4i(float %3, ptr addrspace(4) %iexp.ascast) #8
  %4 = load i32, ptr %iexp, align 4
  %call2 = call spir_func float @_Z5ldexpfi(float %call1, i32 %4) #9
  %mul = mul i32 2, %2
  %add = add i32 %mul, 0
  %arrayidx3 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add
  store float %call1, ptr addrspace(1) %arrayidx3, align 4
  %mul4 = mul i32 2, %2
  %add5 = add i32 %mul4, 1
  %arrayidx6 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add5
  store float %call2, ptr addrspace(1) %arrayidx6, align 4
  %5 = load i32, ptr %iexp, align 4
  %arrayidx7 = getelementptr inbounds i32, ptr addrspace(1) %out2, i32 %2
  store i32 %5, ptr addrspace(1) %arrayidx7, align 4
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !18 spir_func float @_Z5frexpfPU3AS4i(float, ptr addrspace(4)) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @test2(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out1, ptr addrspace(1) align 4 %out2) #0 !kernel_arg_addr_space !12 !kernel_arg_access_qual !13 !kernel_arg_type !14 !kernel_arg_base_type !14 !kernel_arg_type_qual !15 !kernel_arg_name !16 !clspv.pod_args_impl !17 {
entry:
  %quo = alloca i32, align 4
  store i32 0, ptr %quo, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) @__push_constants, align 4
  %2 = add i32 %0, %1
  store i32 0, ptr %quo, align 4
  %mul = mul i32 2, %2
  %add = add i32 %mul, 0
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %in, i32 %add
  %3 = load float, ptr addrspace(1) %arrayidx, align 4
  %mul1 = mul i32 2, %2
  %add2 = add i32 %mul1, 1
  %arrayidx3 = getelementptr inbounds float, ptr addrspace(1) %in, i32 %add2
  %4 = load float, ptr addrspace(1) %arrayidx3, align 4
  %quo.ascast = addrspacecast ptr %quo to ptr addrspace(4)
  %call4 = call spir_func float @_Z6remquoffPU3AS4i(float %3, float %4, ptr addrspace(4) %quo.ascast) #8
  %arrayidx5 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %2
  store float %call4, ptr addrspace(1) %arrayidx5, align 4
  %5 = load i32, ptr %quo, align 4
  %arrayidx6 = getelementptr inbounds i32, ptr addrspace(1) %out2, i32 %2
  store i32 %5, ptr addrspace(1) %arrayidx6, align 4
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !19 spir_func float @_Z6remquoffPU3AS4i(float, float, ptr addrspace(4)) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @test3(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out1) #0 !kernel_arg_addr_space !20 !kernel_arg_access_qual !21 !kernel_arg_type !22 !kernel_arg_base_type !22 !kernel_arg_type_qual !23 !kernel_arg_name !24 !clspv.pod_args_impl !17 {
entry:
  %iexp = alloca float, align 4
  store float 0.000000e+00, ptr %iexp, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) @__push_constants, align 4
  %2 = add i32 %0, %1
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %in, i32 %2
  %3 = load float, ptr addrspace(1) %arrayidx, align 4
  store float 0.000000e+00, ptr %iexp, align 4
  %iexp.ascast = addrspacecast ptr %iexp to ptr addrspace(4)
  %call1 = call spir_func float @_Z4modffPU3AS4f(float %3, ptr addrspace(4) %iexp.ascast) #8
  %mul = mul i32 2, %2
  %add = add i32 %mul, 0
  %arrayidx2 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add
  store float %call1, ptr addrspace(1) %arrayidx2, align 4
  %4 = load float, ptr %iexp, align 4
  %mul3 = mul i32 2, %2
  %add4 = add i32 %mul3, 1
  %arrayidx5 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add4
  store float %4, ptr addrspace(1) %arrayidx5, align 4
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !18 spir_func float @_Z4modffPU3AS4f(float, ptr addrspace(4)) #1

; Function Attrs: convergent mustprogress norecurse nounwind
define dso_local spir_kernel void @test4(ptr addrspace(1) align 4 %in, ptr addrspace(1) align 4 %out1) #0 !kernel_arg_addr_space !20 !kernel_arg_access_qual !21 !kernel_arg_type !22 !kernel_arg_base_type !22 !kernel_arg_type_qual !23 !kernel_arg_name !24 !clspv.pod_args_impl !17 {
entry:
  %iexp = alloca float, align 4
  store float 0.000000e+00, ptr %iexp, align 4
  %0 = load i32, ptr addrspace(5) @__spirv_GlobalInvocationId, align 4
  %1 = load i32, ptr addrspace(9) @__push_constants, align 4
  %2 = add i32 %0, %1
  %arrayidx = getelementptr inbounds float, ptr addrspace(1) %in, i32 %2
  %3 = load float, ptr addrspace(1) %arrayidx, align 4
  store float 0.000000e+00, ptr %iexp, align 4
  %iexp.ascast = addrspacecast ptr %iexp to ptr addrspace(4)
  %call1 = call spir_func float @_Z5fractfPU3AS4f(float %3, ptr addrspace(4) %iexp.ascast) #8
  %mul = mul i32 2, %2
  %add = add i32 %mul, 0
  %arrayidx2 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add
  store float %call1, ptr addrspace(1) %arrayidx2, align 4
  %4 = load float, ptr %iexp, align 4
  %mul3 = mul i32 2, %2
  %add4 = add i32 %mul3, 1
  %arrayidx5 = getelementptr inbounds float, ptr addrspace(1) %out1, i32 %add4
  store float %4, ptr addrspace(1) %arrayidx5, align 4
  ret void
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !18 spir_func float @_Z5fractfPU3AS4f(float, ptr addrspace(4)) #1

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5fractfPf(float noundef, ptr nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5fractfPU3AS3f(float noundef, ptr addrspace(3) nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5fractfPU3AS1f(float noundef, ptr addrspace(1) nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5frexpfPi(float noundef, ptr nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5frexpfPU3AS1i(float noundef, ptr addrspace(1) nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5frexpfPU3AS3i(float noundef, ptr addrspace(3) nocapture noundef writeonly) #2

; Function Attrs: convergent noinline norecurse nounwind
declare !kernel_arg_name !18 dso_local spir_func float @_Z5ldexpfi(float noundef, i32 noundef) #2

; Function Attrs: convergent nounwind
declare !kernel_arg_name !18 dso_local spir_func i32 @_Z7add_satii(i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: convergent nounwind
declare !kernel_arg_name !19 dso_local spir_func i32 @_Z5clampiii(i32 noundef, i32 noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: convergent norecurse nounwind
define linkonce_odr dso_local spir_func float @_Z4modffPf(float noundef %0, ptr nocapture noundef %1) #4 !kernel_arg_name !18 {
  %3 = tail call spir_func float @_Z5truncf(float noundef %0) #8
  store float %3, ptr %1, align 4, !tbaa !25
  %4 = call i1 @_Z8spirv.op.157.f(i32 157, float %0)
  %5 = select i1 %4, i32 1, i32 0
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %2
  %8 = load float, ptr %1, align 4, !tbaa !25
  %9 = fsub float %0, %8
  br label %10

10:                                               ; preds = %7, %2
  %11 = phi float [ %9, %7 ], [ 0.000000e+00, %2 ]
  %12 = call float @llvm.copysign.f32(float %11, float %0)
  ret float %12
}

; Function Attrs: convergent nounwind
declare !kernel_arg_name !29 dso_local spir_func float @_Z5truncf(float noundef) local_unnamed_addr #3

; Function Attrs: convergent norecurse nounwind
define linkonce_odr dso_local spir_func float @_Z4modffPU3AS3f(float noundef %0, ptr addrspace(3) nocapture noundef writeonly %1) #4 !kernel_arg_name !18 {
  %3 = call spir_func float @_Z5truncf(float noundef %0) #8
  %4 = call i1 @_Z8spirv.op.157.f(i32 157, float %0)
  %5 = select i1 %4, i32 1, i32 0
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %_Z4modffPf.exit

7:                                                ; preds = %2
  %8 = fsub float %0, %3
  br label %_Z4modffPf.exit

_Z4modffPf.exit:                                  ; preds = %2, %7
  %9 = phi float [ %8, %7 ], [ 0.000000e+00, %2 ]
  %10 = call float @llvm.copysign.f32(float %9, float %0)
  store float %3, ptr addrspace(3) %1, align 4, !tbaa !25
  ret float %10
}

; Function Attrs: convergent norecurse nounwind
define linkonce_odr dso_local spir_func float @_Z4modffPU3AS1f(float noundef %0, ptr addrspace(1) nocapture noundef writeonly %1) #4 !kernel_arg_name !18 {
  %3 = call spir_func float @_Z5truncf(float noundef %0) #8
  %4 = call i1 @_Z8spirv.op.157.f(i32 157, float %0)
  %5 = select i1 %4, i32 1, i32 0
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %_Z4modffPf.exit

7:                                                ; preds = %2
  %8 = fsub float %0, %3
  br label %_Z4modffPf.exit

_Z4modffPf.exit:                                  ; preds = %2, %7
  %9 = phi float [ %8, %7 ], [ 0.000000e+00, %2 ]
  %10 = call float @llvm.copysign.f32(float %9, float %0)
  store float %3, ptr addrspace(1) %1, align 4, !tbaa !25
  ret float %10
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write)
define linkonce_odr dso_local spir_func float @_Z6remquoffPU3AS1i(float noundef %0, float noundef %1, ptr addrspace(1) nocapture noundef writeonly %2) #5 !kernel_arg_name !19 {
  %4 = insertelement <2 x float> poison, float %0, i64 0
  %5 = insertelement <2 x float> %4, float %1, i64 1
  %6 = bitcast <2 x float> %5 to <2 x i32>
  %7 = and <2 x i32> %6, <i32 2139095040, i32 2139095040>
  %8 = icmp ne <2 x i32> %7, zeroinitializer
  %9 = and <2 x i32> %6, <i32 8388607, i32 8388607>
  %10 = icmp eq <2 x i32> %9, zeroinitializer
  %11 = or <2 x i1> %10, %8
  %12 = and <2 x i32> %6, <i32 -2147483648, i32 -2147483648>
  %13 = select <2 x i1> %11, <2 x i32> %6, <2 x i32> %12
  %14 = and <2 x i32> %13, <i32 2147483647, i32 2147483647>
  %15 = lshr <2 x i32> %14, <i32 23, i32 23>
  %16 = extractelement <2 x i32> %13, i64 0
  %17 = and i32 %16, 8388607
  %18 = or i32 %17, 1065353216
  %19 = bitcast i32 %18 to float
  %20 = extractelement <2 x i32> %13, i64 1
  %21 = and i32 %20, 8388607
  %22 = or i32 %21, 1065353216
  %23 = bitcast i32 %22 to float
  %24 = extractelement <2 x i32> %15, i64 0
  %25 = extractelement <2 x i32> %15, i64 1
  %26 = sub nsw i32 %24, %25
  %27 = icmp sgt i32 %26, 0
  br i1 %27, label %.preheader.i, label %_Z12__clc_remquoffPi.exit

.preheader.i:                                     ; preds = %.preheader.i, %3
  %28 = phi float [ %37, %.preheader.i ], [ %19, %3 ]
  %29 = phi i32 [ %38, %.preheader.i ], [ %26, %3 ]
  %30 = phi i32 [ %34, %.preheader.i ], [ 0, %3 ]
  %31 = fcmp oge float %28, %23
  %32 = zext i1 %31 to i32
  %33 = shl i32 %30, 1
  %34 = or i32 %33, %32
  %35 = select i1 %31, float %23, float 0.000000e+00
  %36 = fsub float %28, %35
  %37 = fadd float %36, %36
  %38 = add nsw i32 %29, -1
  %39 = icmp ugt i32 %29, 1
  br i1 %39, label %.preheader.i, label %40

40:                                               ; preds = %.preheader.i
  %41 = shl i32 %34, 1
  br label %_Z12__clc_remquoffPi.exit

_Z12__clc_remquoffPi.exit:                        ; preds = %3, %40
  %42 = phi i32 [ 0, %3 ], [ %41, %40 ]
  %43 = phi float [ %19, %3 ], [ %37, %40 ]
  %44 = extractelement <2 x i32> %14, i64 1
  %45 = bitcast i32 %44 to float
  %46 = extractelement <2 x i32> %14, i64 0
  %47 = bitcast i32 %46 to float
  %48 = fcmp ogt float %43, %23
  %49 = zext i1 %48 to i32
  %50 = or i32 %42, %49
  %51 = select i1 %48, float %23, float 0.000000e+00
  %52 = fsub float %43, %51
  %53 = icmp ult i32 %24, %25
  %54 = select i1 %53, i32 0, i32 %50
  %55 = select i1 %53, float %47, float %52
  %56 = select i1 %53, float %45, float %23
  %57 = fmul float %55, 2.000000e+00
  %58 = fcmp olt float %56, %57
  %59 = zext i1 %58 to i32
  %60 = fcmp oeq float %56, %57
  %61 = zext i1 %60 to i32
  %62 = and i32 %54, %61
  %63 = or i32 %62, %59
  %64 = icmp eq i32 %63, 0
  %65 = select i1 %64, float 0.000000e+00, float %56
  %66 = fsub float %55, %65
  %67 = add i32 %63, %54
  %68 = and i32 %20, 2139095040
  %69 = bitcast i32 %68 to float
  %70 = select i1 %53, float 1.000000e+00, float %69
  %71 = fmul float %70, %66
  %72 = extractelement <2 x i32> %12, i64 0
  %73 = extractelement <2 x i32> %12, i64 1
  %74 = icmp eq i32 %72, %73
  %75 = and i32 %67, 127
  %76 = icmp eq i32 %46, %44
  %77 = select i1 %76, i32 1, i32 %75
  %78 = sub nsw i32 0, %77
  %79 = select i1 %74, i32 %77, i32 %78
  %80 = bitcast float %71 to i32
  %81 = select i1 %76, i32 0, i32 %80
  %82 = xor i32 %81, %72
  %83 = bitcast i32 %82 to float
  %84 = icmp ugt i32 %46, 2139095039
  %85 = add nsw i32 %44, -2139095041
  %86 = icmp ult i32 %85, -2139095040
  %87 = or i1 %84, %86
  %88 = select i1 %87, i32 0, i32 %79
  %89 = select i1 %87, float 0x7FF8000000000000, float %83
  store i32 %88, ptr addrspace(1) %2, align 4, !tbaa !30
  ret float %89
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write)
define linkonce_odr dso_local spir_func float @_Z6remquoffPU3AS3i(float noundef %0, float noundef %1, ptr addrspace(3) nocapture noundef writeonly %2) #5 !kernel_arg_name !19 {
  %4 = insertelement <2 x float> poison, float %0, i64 0
  %5 = insertelement <2 x float> %4, float %1, i64 1
  %6 = bitcast <2 x float> %5 to <2 x i32>
  %7 = and <2 x i32> %6, <i32 2139095040, i32 2139095040>
  %8 = icmp ne <2 x i32> %7, zeroinitializer
  %9 = and <2 x i32> %6, <i32 8388607, i32 8388607>
  %10 = icmp eq <2 x i32> %9, zeroinitializer
  %11 = or <2 x i1> %10, %8
  %12 = and <2 x i32> %6, <i32 -2147483648, i32 -2147483648>
  %13 = select <2 x i1> %11, <2 x i32> %6, <2 x i32> %12
  %14 = and <2 x i32> %13, <i32 2147483647, i32 2147483647>
  %15 = lshr <2 x i32> %14, <i32 23, i32 23>
  %16 = extractelement <2 x i32> %13, i64 0
  %17 = and i32 %16, 8388607
  %18 = or i32 %17, 1065353216
  %19 = bitcast i32 %18 to float
  %20 = extractelement <2 x i32> %13, i64 1
  %21 = and i32 %20, 8388607
  %22 = or i32 %21, 1065353216
  %23 = bitcast i32 %22 to float
  %24 = extractelement <2 x i32> %15, i64 0
  %25 = extractelement <2 x i32> %15, i64 1
  %26 = sub nsw i32 %24, %25
  %27 = icmp sgt i32 %26, 0
  br i1 %27, label %.preheader.i, label %_Z12__clc_remquoffPi.exit

.preheader.i:                                     ; preds = %.preheader.i, %3
  %28 = phi float [ %37, %.preheader.i ], [ %19, %3 ]
  %29 = phi i32 [ %38, %.preheader.i ], [ %26, %3 ]
  %30 = phi i32 [ %34, %.preheader.i ], [ 0, %3 ]
  %31 = fcmp oge float %28, %23
  %32 = zext i1 %31 to i32
  %33 = shl i32 %30, 1
  %34 = or i32 %33, %32
  %35 = select i1 %31, float %23, float 0.000000e+00
  %36 = fsub float %28, %35
  %37 = fadd float %36, %36
  %38 = add nsw i32 %29, -1
  %39 = icmp ugt i32 %29, 1
  br i1 %39, label %.preheader.i, label %40

40:                                               ; preds = %.preheader.i
  %41 = shl i32 %34, 1
  br label %_Z12__clc_remquoffPi.exit

_Z12__clc_remquoffPi.exit:                        ; preds = %3, %40
  %42 = phi i32 [ 0, %3 ], [ %41, %40 ]
  %43 = phi float [ %19, %3 ], [ %37, %40 ]
  %44 = extractelement <2 x i32> %14, i64 1
  %45 = bitcast i32 %44 to float
  %46 = extractelement <2 x i32> %14, i64 0
  %47 = bitcast i32 %46 to float
  %48 = fcmp ogt float %43, %23
  %49 = zext i1 %48 to i32
  %50 = or i32 %42, %49
  %51 = select i1 %48, float %23, float 0.000000e+00
  %52 = fsub float %43, %51
  %53 = icmp ult i32 %24, %25
  %54 = select i1 %53, i32 0, i32 %50
  %55 = select i1 %53, float %47, float %52
  %56 = select i1 %53, float %45, float %23
  %57 = fmul float %55, 2.000000e+00
  %58 = fcmp olt float %56, %57
  %59 = zext i1 %58 to i32
  %60 = fcmp oeq float %56, %57
  %61 = zext i1 %60 to i32
  %62 = and i32 %54, %61
  %63 = or i32 %62, %59
  %64 = icmp eq i32 %63, 0
  %65 = select i1 %64, float 0.000000e+00, float %56
  %66 = fsub float %55, %65
  %67 = add i32 %63, %54
  %68 = and i32 %20, 2139095040
  %69 = bitcast i32 %68 to float
  %70 = select i1 %53, float 1.000000e+00, float %69
  %71 = fmul float %70, %66
  %72 = extractelement <2 x i32> %12, i64 0
  %73 = extractelement <2 x i32> %12, i64 1
  %74 = icmp eq i32 %72, %73
  %75 = and i32 %67, 127
  %76 = icmp eq i32 %46, %44
  %77 = select i1 %76, i32 1, i32 %75
  %78 = sub nsw i32 0, %77
  %79 = select i1 %74, i32 %77, i32 %78
  %80 = bitcast float %71 to i32
  %81 = select i1 %76, i32 0, i32 %80
  %82 = xor i32 %81, %72
  %83 = bitcast i32 %82 to float
  %84 = icmp ugt i32 %46, 2139095039
  %85 = add nsw i32 %44, -2139095041
  %86 = icmp ult i32 %85, -2139095040
  %87 = or i1 %84, %86
  %88 = select i1 %87, i32 0, i32 %79
  %89 = select i1 %87, float 0x7FF8000000000000, float %83
  store i32 %88, ptr addrspace(3) %2, align 4, !tbaa !30
  ret float %89
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write)
define linkonce_odr dso_local spir_func float @_Z6remquoffPi(float noundef %0, float noundef %1, ptr nocapture noundef writeonly %2) #5 !kernel_arg_name !19 {
  %4 = insertelement <2 x float> poison, float %0, i64 0
  %5 = insertelement <2 x float> %4, float %1, i64 1
  %6 = bitcast <2 x float> %5 to <2 x i32>
  %7 = and <2 x i32> %6, <i32 2139095040, i32 2139095040>
  %8 = icmp ne <2 x i32> %7, zeroinitializer
  %9 = and <2 x i32> %6, <i32 8388607, i32 8388607>
  %10 = icmp eq <2 x i32> %9, zeroinitializer
  %11 = or <2 x i1> %10, %8
  %12 = and <2 x i32> %6, <i32 -2147483648, i32 -2147483648>
  %13 = select <2 x i1> %11, <2 x i32> %6, <2 x i32> %12
  %14 = and <2 x i32> %13, <i32 2147483647, i32 2147483647>
  %15 = lshr <2 x i32> %14, <i32 23, i32 23>
  %16 = extractelement <2 x i32> %13, i64 0
  %17 = and i32 %16, 8388607
  %18 = or i32 %17, 1065353216
  %19 = bitcast i32 %18 to float
  %20 = extractelement <2 x i32> %13, i64 1
  %21 = and i32 %20, 8388607
  %22 = or i32 %21, 1065353216
  %23 = bitcast i32 %22 to float
  %24 = extractelement <2 x i32> %15, i64 0
  %25 = extractelement <2 x i32> %15, i64 1
  %26 = sub nsw i32 %24, %25
  %27 = icmp sgt i32 %26, 0
  br i1 %27, label %.preheader.i, label %_Z12__clc_remquoffPi.exit

.preheader.i:                                     ; preds = %.preheader.i, %3
  %28 = phi float [ %37, %.preheader.i ], [ %19, %3 ]
  %29 = phi i32 [ %38, %.preheader.i ], [ %26, %3 ]
  %30 = phi i32 [ %34, %.preheader.i ], [ 0, %3 ]
  %31 = fcmp oge float %28, %23
  %32 = zext i1 %31 to i32
  %33 = shl i32 %30, 1
  %34 = or i32 %33, %32
  %35 = select i1 %31, float %23, float 0.000000e+00
  %36 = fsub float %28, %35
  %37 = fadd float %36, %36
  %38 = add nsw i32 %29, -1
  %39 = icmp ugt i32 %29, 1
  br i1 %39, label %.preheader.i, label %40

40:                                               ; preds = %.preheader.i
  %41 = shl i32 %34, 1
  br label %_Z12__clc_remquoffPi.exit

_Z12__clc_remquoffPi.exit:                        ; preds = %3, %40
  %42 = phi i32 [ 0, %3 ], [ %41, %40 ]
  %43 = phi float [ %19, %3 ], [ %37, %40 ]
  %44 = extractelement <2 x i32> %14, i64 1
  %45 = bitcast i32 %44 to float
  %46 = extractelement <2 x i32> %14, i64 0
  %47 = bitcast i32 %46 to float
  %48 = fcmp ogt float %43, %23
  %49 = zext i1 %48 to i32
  %50 = or i32 %42, %49
  %51 = select i1 %48, float %23, float 0.000000e+00
  %52 = fsub float %43, %51
  %53 = icmp ult i32 %24, %25
  %54 = select i1 %53, i32 0, i32 %50
  %55 = select i1 %53, float %47, float %52
  %56 = select i1 %53, float %45, float %23
  %57 = fmul float %55, 2.000000e+00
  %58 = fcmp olt float %56, %57
  %59 = zext i1 %58 to i32
  %60 = fcmp oeq float %56, %57
  %61 = zext i1 %60 to i32
  %62 = and i32 %54, %61
  %63 = or i32 %62, %59
  %64 = icmp eq i32 %63, 0
  %65 = select i1 %64, float 0.000000e+00, float %56
  %66 = fsub float %55, %65
  %67 = add i32 %63, %54
  %68 = and i32 %20, 2139095040
  %69 = bitcast i32 %68 to float
  %70 = select i1 %53, float 1.000000e+00, float %69
  %71 = fmul float %70, %66
  %72 = extractelement <2 x i32> %12, i64 0
  %73 = extractelement <2 x i32> %12, i64 1
  %74 = icmp eq i32 %72, %73
  %75 = and i32 %67, 127
  %76 = icmp eq i32 %46, %44
  %77 = select i1 %76, i32 1, i32 %75
  %78 = sub nsw i32 0, %77
  %79 = select i1 %74, i32 %77, i32 %78
  %80 = bitcast float %71 to i32
  %81 = select i1 %76, i32 0, i32 %80
  %82 = xor i32 %81, %72
  %83 = bitcast i32 %82 to float
  %84 = icmp ugt i32 %46, 2139095039
  %85 = add nsw i32 %44, -2139095041
  %86 = icmp ult i32 %85, -2139095040
  %87 = or i1 %84, %86
  %88 = select i1 %87, i32 0, i32 %79
  %89 = select i1 %87, float 0x7FF8000000000000, float %83
  store i32 %88, ptr %2, align 4, !tbaa !30
  ret float %89
}

; Function Attrs: memory(none)
declare i1 @_Z8spirv.op.157.f(i32, float) #6

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.copysign.f32(float, float) #7

attributes #0 = { convergent mustprogress norecurse nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { convergent nounwind "less-precise-fpmad"="true" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" }
attributes #2 = { convergent noinline norecurse nounwind "frame-pointer"="all" "llvm.assume"="clspv_libclc_builtin" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #3 = { convergent nounwind "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #4 = { convergent norecurse nounwind "frame-pointer"="all" "llvm.assume"="clspv_libclc_builtin" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #5 = { nofree norecurse nosync nounwind memory(argmem: write) "frame-pointer"="all" "llvm.assume"="clspv_libclc_builtin" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #6 = { memory(none) }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { convergent nobuiltin nounwind "no-builtins" }
attributes #9 = { convergent nobuiltin nounwind willreturn memory(none) "no-builtins" }

!llvm.module.flags = !{!1, !2, !3}
!opencl.ocl.version = !{!4}
!opencl.spir.version = !{!4, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5, !5}
!llvm.ident = !{!6, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7, !7}
!_Z28clspv.entry_point_attributes = !{!8, !9, !10, !11}

!0 = !{i32 4}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"direct-access-external-data", i32 0}
!3 = !{i32 7, !"frame-pointer", i32 2}
!4 = !{i32 2, i32 0}
!5 = !{i32 1, i32 2}
!6 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 76f20099a5ab72a261661ecb545dceed52e5592d)"}
!7 = !{!"clang version 17.0.0 (https://github.com/llvm/llvm-project 3401a5f7584a2f12a90a7538aee2ae37038c82a9)"}
!8 = !{!"test1", !" __kernel"}
!9 = !{!"test2", !" __kernel"}
!10 = !{!"test3", !" __kernel"}
!11 = !{!"test4", !" __kernel"}
!12 = !{i32 1, i32 1, i32 1}
!13 = !{!"none", !"none", !"none"}
!14 = !{!"float*", !"float*", !"int*"}
!15 = !{!"const", !"", !""}
!16 = !{!"in", !"out1", !"out2"}
!17 = !{i32 3}
!18 = !{!"", !""}
!19 = !{!"", !"", !""}
!20 = !{i32 1, i32 1}
!21 = !{!"none", !"none"}
!22 = !{!"float*", !"float*"}
!23 = !{!"const", !""}
!24 = !{!"in", !"out1"}
!25 = !{!26, !26, i64 0}
!26 = !{!"float", !27, i64 0}
!27 = !{!"omnipotent char", !28, i64 0}
!28 = !{!"Simple C/C++ TBAA"}
!29 = !{!""}
!30 = !{!31, !31, i64 0}
!31 = !{!"int", !27, i64 0}
