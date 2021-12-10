; RUN: clspv-opt -LongVectorLowering -instcombine %s -o %t
; RUN: FileCheck --enable-var-scope %s < %t

; This test covers various forms of bitcasts.
; TODO Add support for bitcast between scalar and vector types.
; TODO Add support for bitcast between vectors of different lengths
;      (e.g. from <8 x i32> to <4 x i64>).
; TODO Add support for vector of pointers, and bitcast between them.

define spir_func <8 x i32> @v2v_A(<8 x float> %x) {
    %y = bitcast <8 x float> %x to <8 x i32>
    ret <8 x i32> %y
}

; This function is unchanged.
define spir_func <4 x i32> @v2v_B(<4 x float> %x) {
    %y = bitcast <4 x float> %x to <4 x i32>
    ret <4 x i32> %y
}

; define spir_func <4 x i64> @v2v_C(<8 x i32> %x) {
;     %y = bitcast <8 x i32> %x to <4 x i64>
;     ret <4 x i64> %y
; }

; define spir_func <8 x i64> @v2v_D(<16 x i32> %x) {
;     %y = bitcast <16 x i32> %x to <8 x i64>
;     ret <8 x i64> %y
; }

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
; are lowered and replaced by an equivalent, others are kept as-is. This
; process re-orders functions in the module.

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:\[16 x i32\] addrspace\(5\)\*]]
; CHECK-SAME: @ps2ps_B(
; CHECK-SAME: [[IN:\[16 x float\] addrspace\(5\)\*]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:\[8 x i32\]\*]]
; CHECK-SAME: @ps2ps_A(
; CHECK-SAME: [[IN:\[8 x float\]\*]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[Y:%[^ ]+]] = bitcast [[IN]] [[X]] to [[OUT]]
; CHECK-NEXT: ret [[OUT]] [[Y]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:\[8 x i32\]]]
; CHECK-SAME: @v2v_A(
; CHECK-SAME: [[IN:\[8 x float\]]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-DAG: [[X0:%[^ ]+]] = extractvalue [[IN]] [[X]], 0
; CHECK-DAG: [[X1:%[^ ]+]] = extractvalue [[IN]] [[X]], 1
; CHECK-DAG: [[X2:%[^ ]+]] = extractvalue [[IN]] [[X]], 2
; CHECK-DAG: [[X3:%[^ ]+]] = extractvalue [[IN]] [[X]], 3
; CHECK-DAG: [[X4:%[^ ]+]] = extractvalue [[IN]] [[X]], 4
; CHECK-DAG: [[X5:%[^ ]+]] = extractvalue [[IN]] [[X]], 5
; CHECK-DAG: [[X6:%[^ ]+]] = extractvalue [[IN]] [[X]], 6
; CHECK-DAG: [[X7:%[^ ]+]] = extractvalue [[IN]] [[X]], 7
; CHECK-DAG: [[Y0:%[^ ]+]] = bitcast float [[X0]] to i32
; CHECK-DAG: [[Y1:%[^ ]+]] = bitcast float [[X1]] to i32
; CHECK-DAG: [[Y2:%[^ ]+]] = bitcast float [[X2]] to i32
; CHECK-DAG: [[Y3:%[^ ]+]] = bitcast float [[X3]] to i32
; CHECK-DAG: [[Y4:%[^ ]+]] = bitcast float [[X4]] to i32
; CHECK-DAG: [[Y5:%[^ ]+]] = bitcast float [[X5]] to i32
; CHECK-DAG: [[Y6:%[^ ]+]] = bitcast float [[X6]] to i32
; CHECK-DAG: [[Y7:%[^ ]+]] = bitcast float [[X7]] to i32
; CHECK-DAG: [[TMP0:%[^ ]+]] = insertvalue [[OUT]] undef, i32 [[Y0]], 0
; CHECK-DAG: [[TMP1:%[^ ]+]] = insertvalue [[OUT]] [[TMP0]], i32 [[Y1]], 1
; CHECK-DAG: [[TMP2:%[^ ]+]] = insertvalue [[OUT]] [[TMP1]], i32 [[Y2]], 2
; CHECK-DAG: [[TMP3:%[^ ]+]] = insertvalue [[OUT]] [[TMP2]], i32 [[Y3]], 3
; CHECK-DAG: [[TMP4:%[^ ]+]] = insertvalue [[OUT]] [[TMP3]], i32 [[Y4]], 4
; CHECK-DAG: [[TMP5:%[^ ]+]] = insertvalue [[OUT]] [[TMP4]], i32 [[Y5]], 5
; CHECK-DAG: [[TMP6:%[^ ]+]] = insertvalue [[OUT]] [[TMP5]], i32 [[Y6]], 6
; CHECK-DAG: [[TMP7:%[^ ]+]] = insertvalue [[OUT]] [[TMP6]], i32 [[Y7]], 7
; CHECK: ret [[OUT]] [[TMP7]]

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
