; RUN: clspv-opt --passes=three-element-vector-lowering %s -o %t.ll -vec3-to-vec4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(ptr addrspace(1) align 16 %f3, ptr addrspace(1) %image, { <2 x float> } %podargs) !clspv.pod_args_impl !9 !kernel_arg_map !10 {
entry:
  %f3.addr.i = alloca ptr addrspace(1), align 4
  %image.addr.i = alloca ptr addrspace(1), align 4
  %coords.addr.i = alloca <2 x float>, align 8
  %tmp.i = alloca <4 x float>, align 16
  %coords = extractvalue { <2 x float> } %podargs, 0
  call void @llvm.lifetime.start.p0(i64 4, ptr %f3.addr.i)
  call void @llvm.lifetime.start.p0(i64 4, ptr %image.addr.i)
  call void @llvm.lifetime.start.p0(i64 8, ptr %coords.addr.i)
  call void @llvm.lifetime.start.p0(i64 16, ptr %tmp.i)
  store ptr addrspace(1) null, ptr %f3.addr.i, align 4
  store ptr addrspace(1) null, ptr %image.addr.i, align 4
  store <2 x float> zeroinitializer, ptr %coords.addr.i, align 8
  store <4 x float> zeroinitializer, ptr %tmp.i, align 16
  store ptr addrspace(1) %f3, ptr %f3.addr.i, align 4
  store ptr addrspace(1) %image, ptr %image.addr.i, align 4
  store <2 x float> %coords, ptr %coords.addr.i, align 8
  %0 = load ptr addrspace(1), ptr %image.addr.i, align 4
  %1 = call spir_func ptr addrspace(2) @__translate_sampler_initializer(i32 18)
  %2 = load <2 x float>, ptr %coords.addr.i, align 8
  %call.i = call spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1) %0, ptr addrspace(2) %1, <2 x float> %2)
  store <4 x float> %call.i, ptr %tmp.i, align 16
  %3 = load ptr addrspace(1), ptr %f3.addr.i, align 4
  %4 = load <3 x float>, ptr addrspace(1) %3, align 16
  %5 = load <4 x float>, ptr %tmp.i, align 16
  %6 = shufflevector <4 x float> %5, <4 x float> poison, <3 x i32> <i32 0, i32 1, i32 2>
  %call1.i = call spir_func <3 x float> @_Z4fminDv3_fS_(<3 x float> %4, <3 x float> %6)
  %7 = load ptr addrspace(1), ptr %f3.addr.i, align 4
  %arrayidx2.i = getelementptr inbounds <3 x float>, ptr addrspace(1) %7, i32 1
  store <3 x float> %call1.i, ptr addrspace(1) %arrayidx2.i, align 16
  call void @llvm.lifetime.end.p0(i64 4, ptr %f3.addr.i)
  call void @llvm.lifetime.end.p0(i64 4, ptr %image.addr.i)
  call void @llvm.lifetime.end.p0(i64 8, ptr %coords.addr.i)
  call void @llvm.lifetime.end.p0(i64 16, ptr %tmp.i)
  ret void
}

declare spir_func <4 x float> @_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f(ptr addrspace(1), ptr addrspace(2), <2 x float>)

declare spir_func ptr addrspace(2) @__translate_sampler_initializer(i32)

declare spir_func <3 x float> @_Z4fminDv3_fS_(<3 x float>, <3 x float>)

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)


!9 = !{i32 2}
!10 = !{!11, !12, !13}
!11 = !{!"f3", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!12 = !{!"image", i32 1, i32 1, i32 0, i32 0, !"ro_image"}
!13 = !{!"coords", i32 2, i32 2, i32 0, i32 8, !"pod_pushconstant"}


