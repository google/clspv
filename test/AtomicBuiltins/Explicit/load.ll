; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@local_mem = internal addrspace(3) global i32 0

define void @global(i32 addrspace(1)* %atomic) {
entry:
  %cast = addrspacecast i32 addrspace(1)* %atomic to i32 addrspace(4)*
  %ld0 = call spir_func i32 @_Z11atomic_loadPU3AS4VU7_Atomici(i32 addrspace(4)* %cast)
  %ld1 = call spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order(i32 addrspace(4)* %cast, i32 0)
  %ld2 = call spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order12memory_scope(i32 addrspace(4)* %cast, i32 2, i32 3)
  ret void
}

define void @local(i32 addrspace(3)* %atomic) {
entry:
  %cast = addrspacecast i32 addrspace(3)* %atomic to i32 addrspace(4)*
  %ld0 = call spir_func i32 @_Z11atomic_loadPU3AS4VU7_Atomici(i32 addrspace(4)* %cast)
  %ld1 = call spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order(i32 addrspace(4)* %cast, i32 0)
  %ld2 = call spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order12memory_scope(i32 addrspace(4)* %cast, i32 2, i32 4)
  %ld3 = call spir_func i32 @_Z11atomic_loadPU3AS4VU7_Atomici(i32 addrspace(4)* addrspacecast (i32 addrspace(3)* @local_mem to i32 addrspace(4)*))
  ret void
}

declare spir_func i32 @_Z11atomic_loadPU3AS4VU7_Atomici(i32 addrspace(4)*)
declare spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order(i32 addrspace(4)*, i32)
declare spir_func i32 @_Z20atomic_load_explicitPU3AS4VU7_Atomici12memory_order12memory_scope(i32 addrspace(4)*, i32, i32)

; CHECK-LABEL: global
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(1)* %atomic, i32 1, i32 66)
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(1)* %atomic, i32 1, i32 64)
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(1)* %atomic, i32 1, i32 66)

; CHECK-LABEL: local
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(3)* %atomic, i32 2, i32 258)
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(3)* %atomic, i32 2, i32 256)
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(3)* %atomic, i32 2, i32 258)
; CHECK: call i32 @_Z8spirv.op.227.{{.*}}(i32 227, i32 addrspace(3)* @local_mem, i32 2, i32 258)
