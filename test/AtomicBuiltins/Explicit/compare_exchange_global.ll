; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <3 x i1> @strong(i32 addrspace(1)* %atomic, i32 addrspace(1)* %expected) {
entry:
  %atomic_cast = addrspacecast i32 addrspace(1)* %atomic to i32 addrspace(4)*
  %expected_cast = addrspacecast i32 addrspace(1)* %expected to i32 addrspace(4)*
  %call0 = call spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPU3AS4VU7_AtomiciPU3AS4ii(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 999)
  %call1 = call spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 998, i32 0, i32 0)
  %call2 = call spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_12memory_scope(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 997, i32 2, i32 0, i32 1)

  %in0 = insertelement <3 x i1> undef, i1 %call0, i32 0
  %in1 = insertelement <3 x i1> %in0, i1 %call1, i32 1
  %in2 = insertelement <3 x i1> %in1, i1 %call2, i32 2
  ret <3 x i1> %in2
}

define <3 x i1> @weak(i32 addrspace(1)* %atomic, i32 addrspace(1)* %expected) {
entry:
  %atomic_cast = addrspacecast i32 addrspace(1)* %atomic to i32 addrspace(4)*
  %expected_cast = addrspacecast i32 addrspace(1)* %expected to i32 addrspace(4)*
  %call0 = call spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomiciPU3AS4ii(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 999)
  %call1 = call spir_func zeroext i1 @_Z37atomic_compare_exchange_weak_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 998, i32 0, i32 0)
  %call2 = call spir_func zeroext i1 @_Z37atomic_compare_exchange_weak_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_12memory_scope(i32 addrspace(4)* %atomic_cast, i32 addrspace(4)* %expected_cast, i32 997, i32 2, i32 0, i32 1)

  %in0 = insertelement <3 x i1> undef, i1 %call0, i32 0
  %in1 = insertelement <3 x i1> %in0, i1 %call1, i32 1
  %in2 = insertelement <3 x i1> %in1, i1 %call2, i32 2
  ret <3 x i1> %in2
}

declare spir_func zeroext i1 @_Z30atomic_compare_exchange_strongPU3AS4VU7_AtomiciPU3AS4ii(i32 addrspace(4)*, i32 addrspace(4)*, i32)
declare spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_(i32 addrspace(4)*, i32 addrspace(4)*, i32, i32, i32)
declare spir_func zeroext i1 @_Z39atomic_compare_exchange_strong_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_12memory_scope(i32 addrspace(4)*, i32 addrspace(4)*, i32, i32, i32, i32)

declare spir_func zeroext i1 @_Z28atomic_compare_exchange_weakPU3AS4VU7_AtomiciPU3AS4ii(i32 addrspace(4)*, i32 addrspace(4)*, i32)
declare spir_func zeroext i1 @_Z37atomic_compare_exchange_weak_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_(i32 addrspace(4)*, i32 addrspace(4)*, i32, i32, i32)
declare spir_func zeroext i1 @_Z37atomic_compare_exchange_weak_explicitPU3AS4VU7_AtomiciPU3AS4ii12memory_orderS4_12memory_scope(i32 addrspace(4)*, i32 addrspace(4)*, i32, i32, i32, i32)

; CHECK-LABEL: strong
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 1, i32 72, i32 66, i32 999, i32 [[load_expected]])
; CHECK: [[cmp0:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp0]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 1, i32 64, i32 64, i32 998, i32 [[load_expected]])
; CHECK: [[cmp1:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp1]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 2, i32 66, i32 64, i32 997, i32 [[load_expected]])
; CHECK: [[cmp2:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp2]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp0]], i32 0
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp1]], i32 1
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp2]], i32 2

; CHECK-LABEL: weak
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 1, i32 72, i32 66, i32 999, i32 [[load_expected]])
; CHECK: [[cmp0:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp0]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 1, i32 64, i32 64, i32 998, i32 [[load_expected]])
; CHECK: [[cmp1:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp1]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: [[load_expected:%[a-zA-Z0-9_.]+]] = load i32, i32 addrspace(1)* %expected
; CHECK: [[cmp_xchg:%[a-zA-Z0-9_.]+]] = call i32 @_Z8spirv.op.230.{{.*}}(i32 230, i32 addrspace(1)* %atomic, i32 2, i32 66, i32 64, i32 997, i32 [[load_expected]])
; CHECK: [[cmp2:%[a-zA-Z0-9_.]+]] = icmp eq i32 [[cmp_xchg]], [[load_expected]]
; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[cmp2]], true
; CHECK: br i1 [[not]], label %[[then:[a-zA-Z0-9_.]+]], label %[[fi:[a-zA-Z0-9_.]+]]
; CHECK: [[then]]:
; CHECK: store i32 [[cmp_xchg]], i32 addrspace(1)* %expected
; CHECK: br label %[[fi]]
; CHECK: [[fi]]:
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp0]], i32 0
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp1]], i32 1
; CHECK: insertelement <3 x i1> {{.*}}, i1 [[cmp2]], i32 2
