; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @global(ptr addrspace(1) %atomic) {
entry:
  %cast = addrspacecast ptr addrspace(1) %atomic to ptr addrspace(4)

  %add0 = call spir_func i32 @_Z16atomic_fetch_addPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %add1 = call spir_func i32 @_Z25atomic_fetch_add_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %add2 = call spir_func i32 @_Z25atomic_fetch_add_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %sub0 = call spir_func i32 @_Z16atomic_fetch_subPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %sub1 = call spir_func i32 @_Z25atomic_fetch_sub_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %sub2 = call spir_func i32 @_Z25atomic_fetch_sub_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %or0 = call spir_func i32 @_Z15atomic_fetch_orPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %or1 = call spir_func i32 @_Z24atomic_fetch_or_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %or2 = call spir_func i32 @_Z24atomic_fetch_or_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %xor0 = call spir_func i32 @_Z16atomic_fetch_xorPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %xor1 = call spir_func i32 @_Z25atomic_fetch_xor_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %xor2 = call spir_func i32 @_Z25atomic_fetch_xor_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %and0 = call spir_func i32 @_Z16atomic_fetch_andPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %and1 = call spir_func i32 @_Z25atomic_fetch_and_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %and2 = call spir_func i32 @_Z25atomic_fetch_and_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %smin0 = call spir_func i32 @_Z16atomic_fetch_minPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %smin1 = call spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %smin2 = call spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %umin0 = call spir_func i32 @_Z16atomic_fetch_minPU3AS4VU7_Atomicjj(ptr addrspace(4) %cast, i32 100)
  %umin1 = call spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicjj12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %umin2 = call spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicjj12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %smax0 = call spir_func i32 @_Z16atomic_fetch_maxPU3AS4VU7_Atomicii(ptr addrspace(4) %cast, i32 100)
  %smax1 = call spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %smax2 = call spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  %umax0 = call spir_func i32 @_Z16atomic_fetch_maxPU3AS4VU7_Atomicjj(ptr addrspace(4) %cast, i32 100)
  %umax1 = call spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicjj12memory_order(ptr addrspace(4) %cast, i32 101, i32 0)
  %umax2 = call spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicjj12memory_order12memory_scope(ptr addrspace(4) %cast, i32 102, i32 0, i32 4)

  ret void
}

declare spir_func i32 @_Z16atomic_fetch_addPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_add_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_add_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_subPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_sub_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_sub_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4) %cast, i32, i32, i32)
declare spir_func i32 @_Z15atomic_fetch_orPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z24atomic_fetch_or_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z24atomic_fetch_or_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_xorPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_xor_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_xor_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_andPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_and_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_and_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_minPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_minPU3AS4VU7_Atomicjj(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicjj12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_min_explicitPU3AS4VU7_Atomicjj12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_maxPU3AS4VU7_Atomicii(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicii12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicii12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)
declare spir_func i32 @_Z16atomic_fetch_maxPU3AS4VU7_Atomicjj(ptr addrspace(4), i32)
declare spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicjj12memory_order(ptr addrspace(4), i32, i32)
declare spir_func i32 @_Z25atomic_fetch_max_explicitPU3AS4VU7_Atomicjj12memory_order12memory_scope(ptr addrspace(4), i32, i32, i32)

; CHECK-LABEL: global
; CHECK: call i32 @_Z8spirv.op.234.{{.*}}(i32 234, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.234.{{.*}}(i32 234, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.234.{{.*}}(i32 234, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.235.{{.*}}(i32 235, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.235.{{.*}}(i32 235, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.235.{{.*}}(i32 235, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.241.{{.*}}(i32 241, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.241.{{.*}}(i32 241, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.241.{{.*}}(i32 241, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.242.{{.*}}(i32 242, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.242.{{.*}}(i32 242, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.242.{{.*}}(i32 242, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.240.{{.*}}(i32 240, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.240.{{.*}}(i32 240, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.240.{{.*}}(i32 240, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.236.{{.*}}(i32 236, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.236.{{.*}}(i32 236, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.236.{{.*}}(i32 236, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.237.{{.*}}(i32 237, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.237.{{.*}}(i32 237, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.237.{{.*}}(i32 237, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.238.{{.*}}(i32 238, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.238.{{.*}}(i32 238, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.238.{{.*}}(i32 238, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
; CHECK: call i32 @_Z8spirv.op.239.{{.*}}(i32 239, ptr addrspace(1) %atomic, i32 1, i32 72, i32 100)
; CHECK: call i32 @_Z8spirv.op.239.{{.*}}(i32 239, ptr addrspace(1) %atomic, i32 1, i32 0, i32 101)
; CHECK: call i32 @_Z8spirv.op.239.{{.*}}(i32 239, ptr addrspace(1) %atomic, i32 3, i32 0, i32 102)
