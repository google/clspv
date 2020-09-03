; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck --enable-var-scope %s < %t

; This test covers various forms of bitcasts.
; TODO Add support for bitcast between scalar and vector types.
; TODO Add support for bitcast between vector types
; TODO Add support for vector of pointers, and bitcast between them.

; define spir_func <8 x i32> @v2v_A(<8 x float> %x) {
;     %y = bitcast <8 x float> %x to <8 x i32>
;     ret <8 x i32> %y
; }

; This function is unchanged.
define spir_func <4 x i32> @v2v_B(<4 x float> %x) {
    %y = bitcast <4 x float> %x to <4 x i32>
    ret <4 x i32> %y
}

; define spir_func i64 @v2s_A(<8 x i8> %x) {
;     %y = bitcast <8 x i8> %x to i64
;     ret i64 %y
; }

; This function is unchanged.
define spir_func i32 @v2s_B(<4 x i8> %x) {
    %y = bitcast <4 x i8> %x to i32
    ret i32 %y
}

; define spir_func <8 x i8> @s2v_A(i64 %x) {
;     %y = bitcast i64 %x to <8 x i8>
;     ret <8 x i8> %y
; }

; This function is unchanged.
define spir_func <2 x i32> @s2v_B(i64 %x) {
    %y = bitcast i64 %x to <2 x i32>
    ret <2 x i32> %y
}

define spir_func <8 x i32>* @ps2ps_A(<8 x float>* %x) {
    %y = bitcast <8 x float>* %x to <8 x i32>*
    ret <8 x i32>* %y
}

define spir_func <16 x i32> addrspace(5)* @ps2ps_B(<16 x float> addrspace(5)* %x) {
    %y = bitcast <16 x float> addrspace(5)* %x to <16 x i32> addrspace(5)*
    ret <16 x i32> addrspace(5)* %y
}

; This function is unchanged.
define spir_func <2 x i32> addrspace(5)* @ps2ps_C(<2 x float> addrspace(5)* %x) {
    %y = bitcast <2 x float> addrspace(5)* %x to <2 x i32> addrspace(5)*
    ret <2 x i32> addrspace(5)* %y
}

; define spir_func <8 x i32*> @pv2pv_A(<8 x float*> %x) {
;     %y = bitcast <8 x float*> %x to <8 x i32*>
;     ret <8 x i32*> %y
; }

; define spir_func <16 x i16 addrspace(5)*> @pv2pv_B(<16 x half addrspace(5)*> %x) {
;     %y = bitcast <16 x half addrspace(5)*> %x to <16 x i16 addrspace(5)*>
;     ret <16 x i16 addrspace(5)*> %y
; }

; This function is unchanged.
define spir_func <2 x i32 addrspace(5)*> @pv2pv_C(<2 x float addrspace(5)*> %x) {
    %y = bitcast <2 x float addrspace(5)*> %x to <2 x i32 addrspace(5)*>
    ret <2 x i32 addrspace(5)*> %y
}

; Note, the order of tests is dictated by the lowering phase: some functions
; are lowered and replaced by an equivalent, others are kept as-is. In this
; process re-order functions in the module.

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:{ i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 } addrspace\(5\)\*]]
; CHECK-SAME: @ps2ps_B(
; CHECK-SAME: [[IN:{ float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float } addrspace\(5\)\*]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:{ i32, i32, i32, i32, i32, i32, i32, i32 }\*]]
; CHECK-SAME: @ps2ps_A(
; CHECK-SAME: [[IN:{ float, float, float, float, float, float, float, float }\*]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:<4 x i32>]]
; CHECK-SAME: @v2v_B(
; CHECK-SAME: [[IN:<4 x float>]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:i32]]
; CHECK-SAME: @v2s_B(
; CHECK-SAME: [[IN:<4 x i8>]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:<2 x i32>]]
; CHECK-SAME: @s2v_B(
; CHECK-SAME: [[IN:i64]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:<2 x i32> addrspace\(5\)\*]]
; CHECK-SAME: @ps2ps_C(
; CHECK-SAME: [[IN:<2 x float> addrspace\(5\)\*]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:<2 x i32 addrspace\(5\)\*>]]
; CHECK-SAME: @pv2pv_C(
; CHECK-SAME: [[IN:<2 x float addrspace\(5\)\*>]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]
