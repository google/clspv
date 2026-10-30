; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; CHECK-DAG: %[[NULL_INT:[a-zA-Z0-9_]+]] = OpConstantNull %_ptr_StorageBuffer_uint
; CHECK-DAG: %[[NULL_FLOAT:[a-zA-Z0-9_]+]] = OpConstantNull %_ptr_StorageBuffer_float
; CHECK-DAG: %[[UNDEF_INT:[a-zA-Z0-9_]+]] = OpUndef %_ptr_StorageBuffer_uint
; CHECK-DAG: %[[UNDEF_FLOAT:[a-zA-Z0-9_]+]] = OpUndef %_ptr_StorageBuffer_float
; CHECK: OpSelect %_ptr_StorageBuffer_uint %{{[a-zA-Z0-9_]+}} %{{[a-zA-Z0-9_]+}} %[[NULL_INT]]
; CHECK: OpSelect %_ptr_StorageBuffer_uint %{{[a-zA-Z0-9_]+}} %[[UNDEF_INT]] %{{[a-zA-Z0-9_]+}}
; CHECK: OpSelect %_ptr_StorageBuffer_float %{{[a-zA-Z0-9_]+}} %[[UNDEF_FLOAT]] %{{[a-zA-Z0-9_]+}}
; CHECK: OpLoad %uint %[[NULL_INT]]
; CHECK: OpLoad %float %[[NULL_FLOAT]]
; CHECK: %[[PHI_INT:[a-zA-Z0-9_]+]] = OpPhi %_ptr_StorageBuffer_uint
; CHECK: %[[PHI_FLOAT:[a-zA-Z0-9_]+]] = OpPhi %_ptr_StorageBuffer_float
; CHECK: OpStore %[[PHI_INT]]
; CHECK: OpStore %[[PHI_FLOAT]]

define spir_kernel void @foo(ptr addrspace(1) %out, ptr addrspace(1) %in, ptr addrspace(1) %fout, { i32 } %podargs) !clspv.pod_args_impl !0 !kernel_arg_map !1 {
entry:
  %res0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %gep0 = getelementptr { [0 x i32] }, ptr addrspace(1) %res0, i32 0, i32 0, i32 0
  %res1 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %gep1 = getelementptr { [0 x i32] }, ptr addrspace(1) %res1, i32 0, i32 0, i32 0
  %res2 = call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0, { [0 x float] } zeroinitializer)
  %gep2 = getelementptr { [0 x float] }, ptr addrspace(1) %res2, i32 0, i32 0, i32 0
  %res3 = call ptr addrspace(9) @_Z14clspv.resource.3(i32 -1, i32 3, i32 5, i32 3, i32 3, i32 0, { { i32 } } zeroinitializer)
  %gep3 = getelementptr { { i32 } }, ptr addrspace(9) %res3, i32 0, i32 0
  %ld = load { i32 }, ptr addrspace(9) %gep3, align 4
  %cond = extractvalue { i32 } %ld, 0
  %cmp = icmp ne i32 %cond, 0
  %sel_null = select i1 %cmp, ptr addrspace(1) %gep0, ptr addrspace(1) null
  %sel_undef = select i1 %cmp, ptr addrspace(1) undef, ptr addrspace(1) %gep1
  %sel_undef_f = select i1 %cmp, ptr addrspace(1) undef, ptr addrspace(1) %gep2
  br i1 %cmp, label %then, label %merge

then:
  %v1 = load volatile i32, ptr addrspace(1) null, align 4
  %v2 = load volatile float, ptr addrspace(1) null, align 4
  %v2i = fptosi float %v2 to i32
  %sum = add i32 %v1, %v2i
  store i32 %sum, ptr addrspace(1) %sel_undef, align 4
  br label %merge

merge:
  %phi_int = phi ptr addrspace(1) [ %sel_null, %entry ], [ null, %then ]
  %phi_float = phi ptr addrspace(1) [ null, %entry ], [ %sel_undef_f, %then ]
  store i32 %cond, ptr addrspace(1) %phi_int, align 4
  store float 1.000000e+00, ptr addrspace(1) %phi_float, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })
declare ptr addrspace(1) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })
declare ptr addrspace(1) @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { [0 x float] })
declare ptr addrspace(9) @_Z14clspv.resource.3(i32, i32, i32, i32, i32, i32, { { i32 } })

!0 = !{i32 2}
!1 = !{!2, !3, !4, !5}
!2 = !{!"out", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!3 = !{!"in", i32 1, i32 1, i32 0, i32 0, !"buffer"}
!4 = !{!"fout", i32 2, i32 2, i32 0, i32 0, !"buffer"}
!5 = !{!"cond", i32 3, i32 3, i32 0, i32 4, !"pod_pushconstant"}
