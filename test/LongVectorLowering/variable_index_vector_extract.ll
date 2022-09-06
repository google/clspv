; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @variable_index_vector_extract(i8* %out1, i8* %out2, i32 %index) {
  %arr_ptr = alloca <16 x i8>
  %arr = load <16 x i8>, <16 x i8>* %arr_ptr, align 16

  ; with load instruction as equivalent value instruction for the vector.
  %element1 = extractelement <16 x i8> %arr, i32 %index
  store i8 %element1, i8* %out1, align 1

  ; without load instruction as equivalent value instruction for the vector.
  %element2 = extractelement <16 x i8> undef, i32 %index
  store i8 %element2, i8* %out2, align 1

  ret void
}

; CHECK-NOT: <16 x i8>

; CHECK:  define spir_kernel void @variable_index_vector_extract(i8* %out1, i8* %out2, i32 %index)
; CHECK:  [[alloca:%[^ ]+]] = alloca [16 x i8], align 1

; with load instruction as equivalent value instruction for the vector.
; CHECK:  [[gep1:%[^ ]+]] = getelementptr inbounds [16 x i8], [16 x i8]* %arr_ptr, i32 0, i32 %index
; CHECK:  %element1 = load i8, i8* [[gep1]], align 1  

; without load instruction as equivalent value instruction for the vector.
; CHECK:  store [16 x i8] undef, [16 x i8]* [[alloca]], align 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr inbounds [16 x i8], [16 x i8]* [[alloca]], i32 0, i32 %index
; CHECK:  %element2 = load i8, i8* [[gep2]], align 1
