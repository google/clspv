; RUN: clspv-opt %s -o %t.spv --passes=spirv-producer


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @main() {
entry:
  ; Allocate space for three characters
  %index1 = alloca i8, align 1
  %index2 = alloca i8, align 1
  %index3 = alloca i8, align 1

 %str = getelementptr inbounds [13 x i8], [13 x i8]* addrspace(1)* @string_constant, i32 0, i32 0

  ; Get first three characters and store them in variables
  %char1 = load i8, i8* addrspace(1)* %str
  store i8 %char1, i8* %index1

  %next_char = getelementptr inbounds i8, i8* addrspace(1)* %str, i32 1
  %char2 = load i8, i8* addrspace(1)* %next_char
  store i8 %char2, i8* %index2

  %next_char2 = getelementptr inbounds i8, i8* addrspace(1)* %next_char, i32 1
  %char3 = load i8, i8* addrspace(1)* %next_char2
  store i8 %char3, i8* %index3
 
  ret i32 0
}

; Constant string
@string_constant = private unnamed_addr addrspace(1) constant [13 x i8] c"Hello World!\00", align 1
