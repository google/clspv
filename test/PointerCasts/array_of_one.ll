; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll
; CHECK: [[gep:%[^ ]+]] = getelementptr [1 x [8 x float]], ptr addrspace(3) @gain_offset, i32 0, i32 %add151.i.i, i32 0
; CHECK: store float 1.000000e+00, ptr addrspace(3) [[gep]], align 32
; CHECK: [[gep:%[^ ]+]] = getelementptr [1 x [8 x float]], ptr addrspace(3) @gain_offset, i32 0, i32 %add151.i.i, i32 1
; CHECK: store float 1.000000e+00, ptr addrspace(3) [[gep]], align 4
; CHECK: [[gep:%[^ ]+]] = getelementptr [1 x [8 x float]], ptr addrspace(3) @gain_offset, i32 0, i32 %add151.i.i, i32 2
; CHECK: store float 1.000000e+00, ptr addrspace(3) [[gep]], align 8
; CHECK: [[gep:%[^ ]+]] = getelementptr [1 x [8 x float]], ptr addrspace(3) @gain_offset, i32 0, i32 %add151.i.i, i32 3
; CHECK: store float 1.000000e+00, ptr addrspace(3) [[gep]], align 4

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-G1"
target triple = "spir-unknown-unknown"

@gain_offset = internal unnamed_addr addrspace(3) global [1 x [8 x float]] undef, align 32
@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_LocalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer

define spir_kernel void @foo(target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %base_guide_image, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %alt_guide_image, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %alignment, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 0) %unblocker_image, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %snr_map_out, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %pixel_diff_out, target("spirv.Image", void, 1, 0, 0, 0, 0, 0, 1) %rejection_out) {
entry:
  %lid_0 = load i32, ptr addrspace(5) @__spirv_LocalInvocationId, align 16
  %lid_1 = load i32, ptr addrspace(5) getelementptr inbounds nuw (i8, ptr addrspace(5) @__spirv_LocalInvocationId, i32 4), align 4
  %div.i.i = sdiv i32 %lid_0, 8
  %div11.i.i = sdiv i32 %lid_1, 2
  %add151.i.i = add nsw i32 %div11.i.i, %div.i.i
  %arrayidx222.i.i = getelementptr inbounds [8 x float], ptr addrspace(3) @gain_offset, i32 %add151.i.i
  store float 1.000000e+00, ptr addrspace(3) %arrayidx222.i.i, align 32
  %arrayidx222.i.i.repack98 = getelementptr inbounds nuw i8, ptr addrspace(3) %arrayidx222.i.i, i32 4
  store float 1.000000e+00, ptr addrspace(3) %arrayidx222.i.i.repack98, align 4
  %arrayidx222.i.i.repack99 = getelementptr inbounds nuw i8, ptr addrspace(3) %arrayidx222.i.i, i32 8
  store float 1.000000e+00, ptr addrspace(3) %arrayidx222.i.i.repack99, align 8
  %arrayidx222.i.i.repack100 = getelementptr inbounds nuw i8, ptr addrspace(3) %arrayidx222.i.i, i32 12
  store float 1.000000e+00, ptr addrspace(3) %arrayidx222.i.i.repack100, align 4
  ret void
}
