; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%s = type { { { i32 } } }

@mem1 = internal addrspace(3) global [1 x i32] undef, align 4
@mem2 = internal addrspace(3) global [2 x [2 x i32]] undef, align 4
@mem3 = internal addrspace(3) global %s undef, align 4

define void @test() {
entry:
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [1 x i32], ptr addrspace(3) @mem1, i32 0, i32 0
  ; CHECK: call void @_Z8spirv.op.{{.*}}(i32 228, ptr addrspace(3) [[gep]],
  call void @_Z8spirv.op.228(i32 228, ptr addrspace(3) @mem1, i32 2, i32 256, i32 0)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [1 x i32], ptr addrspace(3) @mem1, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 227, ptr addrspace(3) [[gep]],
  %ld = call i32 @_Z8spirv.op.227(i32 227, ptr addrspace(3) @mem1, i32 2, i32 256, i32 0)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [1 x i32], ptr addrspace(3) @mem1, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 229, ptr addrspace(3) [[gep]],
  %ex = call i32 @_Z8spirv.op.229(i32 229, ptr addrspace(3) @mem1, i32 2, i32 256, i32 0)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [1 x i32], ptr addrspace(3) @mem1, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 230, ptr addrspace(3) [[gep]],
  %cmp_ex = call i32 @_Z8spirv.op.230(i32 230, ptr addrspace(3) @mem1, i32 2, i32 256, i32 256, i32 0)

  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [2 x [2 x i32]], ptr addrspace(3) @mem2, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 232, ptr addrspace(3) [[gep]],
  %inc = call i32 @_Z8spirv.op.232(i32 232, ptr addrspace(3) @mem2, i32 2, i32 256)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [2 x [2 x i32]], ptr addrspace(3) @mem2, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 233, ptr addrspace(3) [[gep]],
  %dec = call i32 @_Z8spirv.op.233(i32 233, ptr addrspace(3) @mem2, i32 2, i32 256)

  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %s, ptr addrspace(3) @mem3, i32 0, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 234, ptr addrspace(3) [[gep]],
  %add = call i32 @_Z8spirv.op.234(i32 234, ptr addrspace(3) @mem3, i32 2, i32 256, i32 1)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %s, ptr addrspace(3) @mem3, i32 0, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 235, ptr addrspace(3) [[gep]],
  %sub = call i32 @_Z8spirv.op.235(i32 235, ptr addrspace(3) @mem3, i32 2, i32 256, i32 1)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %s, ptr addrspace(3) @mem3, i32 0, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 240, ptr addrspace(3) [[gep]],
  %and = call i32 @_Z8spirv.op.240(i32 240, ptr addrspace(3) @mem3, i32 2, i32 256, i32 1)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %s, ptr addrspace(3) @mem3, i32 0, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 241, ptr addrspace(3) [[gep]],
  %or = call i32 @_Z8spirv.op.241(i32 241, ptr addrspace(3) @mem3, i32 2, i32 256, i32 1)
  ; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr %s, ptr addrspace(3) @mem3, i32 0, i32 0, i32 0, i32 0
  ; CHECK: call i32 @_Z8spirv.op.{{.*}}(i32 242, ptr addrspace(3) [[gep]],
  %xor = call i32 @_Z8spirv.op.242(i32 242, ptr addrspace(3) @mem3, i32 2, i32 256, i32 1)
  ret void
}

declare i32 @_Z8spirv.op.227(i32, ptr addrspace(3), i32, i32, i32)
declare void @_Z8spirv.op.228(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.229(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.230(i32, ptr addrspace(3), i32, i32, i32, i32)
declare i32 @_Z8spirv.op.232(i32, ptr addrspace(3), i32, i32)
declare i32 @_Z8spirv.op.233(i32, ptr addrspace(3), i32, i32)
declare i32 @_Z8spirv.op.234(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.235(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.240(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.241(i32, ptr addrspace(3), i32, i32, i32)
declare i32 @_Z8spirv.op.242(i32, ptr addrspace(3), i32, i32, i32)
