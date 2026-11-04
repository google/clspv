; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll
; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast,replace-pointer-bitcast
; RUN: FileCheck %s --check-prefix=REPLACE < %t.ll

; The high halves of the 64-bit global variables @x and @y are stored through
; GEPs with constant offsets that point inside their scalar i64 elements. They
; cannot be turned into GEPs of the types of the global variables, which used to
; reach an unreachable in GetIdxsForTyFromOffset. They are upgraded to GEPs of
; the stored type instead, which lets ReplacePointerBitcastPass lower the
; global variables to [2 x i32] rather than [8 x i8].

; CHECK-LABEL: @scalar
; CHECK: [[lo:%[^ ]+]] = getelementptr i64, ptr addrspace(3) @x, i32 0
; CHECK: store i32 %a, ptr addrspace(3) [[lo]], align 8
; CHECK: [[hi:%[^ ]+]] = getelementptr i32, ptr addrspace(3) @x, i32 1
; CHECK: store i32 %b, ptr addrspace(3) [[hi]], align 4
; CHECK: load i64, ptr addrspace(3) @x, align 8

; CHECK-LABEL: @struct
; CHECK: [[lo:%[^ ]+]] = getelementptr %struct.S, ptr addrspace(3) @y, i32 0, i32 0
; CHECK: store i32 %a, ptr addrspace(3) [[lo]], align 8
; CHECK: [[hi:%[^ ]+]] = getelementptr i32, ptr addrspace(3) @y, i32 1
; CHECK: store i32 %b, ptr addrspace(3) [[hi]], align 4

; REPLACE: @x = internal addrspace(3) global [2 x i32] undef
; REPLACE: @y = internal addrspace(3) global [2 x i32] undef
; REPLACE-LABEL: @scalar
; REPLACE: store i32 %a, ptr addrspace(3) @x, align 4
; REPLACE: store i32 %b, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @x, i32 4), align 4
; REPLACE: [[ld:%[^ ]+]] = load [2 x i32], ptr addrspace(3) @x
; REPLACE: [[ld_lo:%[^ ]+]] = extractvalue [2 x i32] [[ld]], 0
; REPLACE: [[ld_hi:%[^ ]+]] = extractvalue [2 x i32] [[ld]], 1
; REPLACE: [[vec_lo:%[^ ]+]] = insertelement <2 x i32> poison, i32 [[ld_lo]], i32 0
; REPLACE: [[vec:%[^ ]+]] = insertelement <2 x i32> [[vec_lo]], i32 [[ld_hi]], i32 1
; REPLACE: bitcast <2 x i32> [[vec]] to i64
; REPLACE-LABEL: @struct
; REPLACE: store i32 %a, ptr addrspace(3) @y, align 4
; REPLACE: store i32 %b, ptr addrspace(3) getelementptr (i8, ptr addrspace(3) @y, i32 4), align 4
; REPLACE: load [2 x i32], ptr addrspace(3) @y

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.S = type { i64 }

@x = internal addrspace(3) global i64 undef, align 8
@y = internal addrspace(3) global %struct.S undef, align 8

define spir_kernel void @scalar(ptr addrspace(1) %out, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr addrspace(3) @x, align 8
  store i32 %b, ptr addrspace(3) getelementptr inbounds nuw (i8, ptr addrspace(3) @x, i32 4), align 4
  %v = load i64, ptr addrspace(3) @x, align 8
  store i64 %v, ptr addrspace(1) %out, align 8
  ret void
}

define spir_kernel void @struct(ptr addrspace(1) %out, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr addrspace(3) @y, align 8
  store i32 %b, ptr addrspace(3) getelementptr inbounds nuw (i8, ptr addrspace(3) @y, i32 4), align 4
  %v = load i64, ptr addrspace(3) @y, align 8
  store i64 %v, ptr addrspace(1) %out, align 8
  ret void
}
