; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @global(i32 addrspace(1)* %atomic) {
entry:
  %cast = addrspacecast i32 addrspace(1)* %atomic to i32 addrspace(4)*
  %call0 = call spir_func i32 @_Z15atomic_exchangePU3AS4VU7_Atomicii(i32 addrspace(4)* %cast, i32 100)
  %call1 = call spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order(i32 addrspace(4)* %cast, i32 101, i32 0)
  %call2 = call spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(i32 addrspace(4)* %cast, i32 102, i32 5, i32 3)
  ret void
}

define void @local(i32 addrspace(3)* %atomic) {
entry:
  %cast = addrspacecast i32 addrspace(3)* %atomic to i32 addrspace(4)*
  %call0 = call spir_func i32 @_Z15atomic_exchangePU3AS4VU7_Atomicii(i32 addrspace(4)* %cast, i32 100)
  %call1 = call spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order(i32 addrspace(4)* %cast, i32 101, i32 0)
  %call2 = call spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(i32 addrspace(4)* %cast, i32 102, i32 5, i32 3)
  ret void
}

declare spir_func i32 @_Z15atomic_exchangePU3AS4VU7_Atomicii(i32 addrspace(4)*, i32)
declare spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order(i32 addrspace(4)*, i32, i32)
declare spir_func i32 @_Z24atomic_exchange_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(i32 addrspace(4)*, i32, i32, i32)

; CHECK-LABEL: global
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(1)* %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(1)* %atomic, i32 1, i32 64, i32 101)
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(1)* %atomic, i32 1, i32 72, i32 102)

; CHECK-LABEL: local
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(3)* %atomic, i32 2, i32 264, i32 100)
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(3)* %atomic, i32 2, i32 256, i32 101)
; CHECK: call i32 @_Z8spirv.op.229.{{.*}}(i32 229, i32 addrspace(3)* %atomic, i32 2, i32 264, i32 102)
