; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; RUN: clspv-opt %s -o %t.preserve.ll --passes=spirv-producer -producer-out-file %t.preserve.spv -denorm-preserve=32
; RUN: spirv-dis %t.preserve.spv -o %t.preserve.spvasm
; RUN: FileCheck %s --check-prefix=CHECK-PRESERVE < %t.preserve.spvasm
; RUN: spirv-val --target-env spv1.4 %t.preserve.spv

; CHECK-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-DAG: [[v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[v2uint:%[a-zA-Z0-9_]+]] = OpTypeVector [[uint]] 2
; CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-DAG: [[v2bool:%[a-zA-Z0-9_]+]] = OpTypeVector [[bool]] 2
; CHECK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[v2float]]
; CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[v2float]]
; CHECK: [[sign0:%[a-zA-Z0-9_]+]] = OpBitcast [[v2float]]
; CHECK: [[abs0:%[a-zA-Z0-9_]+]] = OpBitcast [[v2float]]
; CHECK: [[cond0:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[v2bool]] [[abs0]]
; CHECK: [[canon0:%[a-zA-Z0-9_]+]] = OpSelect [[v2float]] [[cond0]] [[sign0]] [[ld0]]
; CHECK: [[sign1:%[a-zA-Z0-9_]+]] = OpBitcast [[v2float]]
; CHECK: [[abs1:%[a-zA-Z0-9_]+]] = OpBitcast [[v2float]]
; CHECK: [[cond1:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[v2bool]] [[abs1]]
; CHECK: [[canon1:%[a-zA-Z0-9_]+]] = OpSelect [[v2float]] [[cond1]] [[sign1]] [[ld1]]
; CHECK: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[v2float]] %{{.*}} NMin [[canon0]] [[canon1]]
; CHECK: OpStore {{.*}} [[min]]

; CHECK-PRESERVE-DAG: [[float:%[a-zA-Z0-9_]+]] = OpTypeFloat 32
; CHECK-PRESERVE-DAG: [[v2float:%[a-zA-Z0-9_]+]] = OpTypeVector [[float]] 2
; CHECK-PRESERVE: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[v2float]]
; CHECK-PRESERVE: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[v2float]]
; CHECK-PRESERVE: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[v2float]] %{{.*}} NMin [[ld0]] [[ld1]]
; CHECK-PRESERVE: OpStore {{.*}} [[min]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 8 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x <2 x float>] } zeroinitializer)
  %1 = getelementptr { [0 x <2 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %ld1 = load <2 x float>, ptr addrspace(1) %1, align 8
  %2 = getelementptr { [0 x <2 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %ld2 = load <2 x float>, ptr addrspace(1) %2, align 8
  %res = call spir_func <2 x float> @_Z4fminDv2_fS_(<2 x float> %ld1, <2 x float> %ld2)
  %3 = getelementptr { [0 x <2 x float>] }, ptr addrspace(1) %0, i32 0, i32 0, i32 2
  store <2 x float> %res, ptr addrspace(1) %3, align 8
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x <2 x float>] })
declare spir_func <2 x float> @_Z4fminDv2_fS_(<2 x float>, <2 x float>)

!8 = !{i32 2}
