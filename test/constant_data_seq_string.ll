; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer --producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm

; CHECK-DAG: [[uchar:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[uint_13:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 13
; CHECK-DAG: [[arr_uchar_13:%[a-zA-Z0-9_]+]] = OpTypeArray [[uchar]] [[uint_13]]
; CHECK-DAG: [[ptr_private_arr:%[a-zA-Z0-9_]+]] = OpTypePointer Private [[arr_uchar_13]]
; CHECK-DAG: [[uchar_72:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 72
; CHECK-DAG: [[uchar_101:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 101
; CHECK-DAG: [[uchar_108:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 108
; CHECK-DAG: [[uchar_111:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 111
; CHECK-DAG: [[uchar_32:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 32
; CHECK-DAG: [[uchar_87:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 87
; CHECK-DAG: [[uchar_114:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 114
; CHECK-DAG: [[uchar_100:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 100
; CHECK-DAG: [[uchar_33:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 33
; CHECK-DAG: [[uchar_0:%[a-zA-Z0-9_]+]] = OpConstant [[uchar]] 0
; CHECK-DAG: [[str_cst:%[a-zA-Z0-9_]+]] = OpConstantComposite [[arr_uchar_13]] [[uchar_72]] [[uchar_101]] [[uchar_108]] [[uchar_108]] [[uchar_111]] [[uchar_32]] [[uchar_87]] [[uchar_111]] [[uchar_114]] [[uchar_108]] [[uchar_100]] [[uchar_33]] [[uchar_0]]
; CHECK: [[var:%[a-zA-Z0-9_]+]] = OpVariable [[ptr_private_arr]] Private [[str_cst]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define i32 @main() {
entry:
  ; Allocate space for three characters
  %index1 = alloca i8, align 1
  %index2 = alloca i8, align 1
  %index3 = alloca i8, align 1

  %str = getelementptr inbounds [13 x i8], ptr addrspace(1) @string_constant, i32 0, i32 0

  ; Get first three characters and store them in variables
  %char1 = load i8, ptr addrspace(1) %str
  store i8 %char1, ptr %index1

  %next_char = getelementptr inbounds [13 x i8], ptr addrspace(1) @string_constant, i32 0, i32 1
  %char2 = load i8, ptr addrspace(1) %next_char
  store i8 %char2, ptr %index2

  %next_char2 = getelementptr inbounds [13 x i8], ptr addrspace(1) @string_constant, i32 0, i32 2
  %char3 = load i8, ptr addrspace(1) %next_char2
  store i8 %char3, ptr %index3

  ret i32 0
}

; Constant string
@string_constant = private unnamed_addr addrspace(1) constant [13 x i8] c"Hello World!\00", align 1
