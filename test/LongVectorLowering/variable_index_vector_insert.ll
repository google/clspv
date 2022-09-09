; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @variable_index_vector_insert(<16 x i8>* %out1, <16 x i8>* %out2, i32 %index) {
  %arr_ptr = alloca <16 x i8>
  %arr = load <16 x i8>, <16 x i8>* %arr_ptr, align 16

  ; with load instruction as equivalent value instruction for the vector.
  %modified_arr1 = insertelement <16 x i8> %arr, i8 10, i32 %index
  store <16 x i8> %modified_arr1, <16 x i8>* %out1, align 16

  ; without load instruction as equivalent value instruction for the vector.
  %modified_arr2 = insertelement <16 x i8> undef, i8 20, i32 %index
  store <16 x i8> %modified_arr2, <16 x i8>* %out2, align 16

  ret void
}

; CHECK-NOT: <16 x i8>

; CHECK:  define spir_kernel void @variable_index_vector_insert([16 x i8]* %out1, [16 x i8]* %out2, i32 %index)
; CHECK:  [[alloca:%[^ ]+]] = alloca [16 x i8], align 1

; with load instruction as equivalent value instruction for the vector. 
; CHECK:  [[gep1:%[^ ]+]] = getelementptr inbounds [16 x i8], [16 x i8]* %arr_ptr.i, i32 0, i32 %index
; CHECK:  store i8 10, i8* [[gep1]], align 1

; without load instruction as equivalent value instruction for the vector.
; CHECK:  store [16 x i8] undef, [16 x i8]* [[alloca]], align 1
; CHECK:  [[gep2:%[^ ]+]] = getelementptr inbounds [16 x i8], [16 x i8]* [[alloca]], i32 0, i32 %index
; CHECK:  store i8 20, i8* [[gep2]], align 1
