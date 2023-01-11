; RUN: clspv -x ir %s -o %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: = OpFunction
; CHECK-NOT: = OpFunction

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@local_data = internal addrspace(3) global [1024 x i32] undef, align 4

define spir_kernel void @test() {
entry:
  call void @bar(i32 addrspace(4)* addrspacecast (i32 addrspace(3)* getelementptr ([1024 x i32], [1024 x i32] addrspace(3)* @local_data, i32 0, i32 0) to i32 addrspace(4)*))
  ret void
}

define spir_func void @bar(i32 addrspace(4)* %data) {
entry:
  call spir_func void @_Z7vstore4Dv4_iiPU3AS4i(<4 x i32> zeroinitializer, i32 0, i32 addrspace(4)* %data)
  ret void
}

declare spir_func void @_Z7vstore4Dv4_iiPU3AS4i(<4 x i32>, i32, i32 addrspace(4)*)
