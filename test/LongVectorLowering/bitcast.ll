; RUN: clspv-opt --passes=long-vector-lowering,instcombine %s -o %t
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

define spir_func <4 x i64> @v2v_C(<8 x i32> %x) {
    %y = bitcast <8 x i32> %x to <4 x i64>
    ret <4 x i64> %y
}

define spir_func <8 x i64> @v2v_D(<16 x i32> %x) {
    %y = bitcast <16 x i32> %x to <8 x i64>
    ret <8 x i64> %y
}

define spir_func i64 @v2s_A(<8 x i8> %x) {
    %y = bitcast <8 x i8> %x to i64
    ret i64 %y
}

; This function is unchanged.
define spir_func i32 @v2s_B(<4 x i8> %x) {
    %y = bitcast <4 x i8> %x to i32
    ret i32 %y
}

define spir_func <8 x i8> @s2v_A(i64 %x) {
    %y = bitcast i64 %x to <8 x i8>
    ret <8 x i8> %y
}

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
; CHECK-SAME: [[OUT:\[8 x i8\]]]
; CHECK-SAME: @s2v_A(
; CHECK-SAME: [[IN:i64]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[BITCAST:%[^ ]+]] = bitcast [[IN]] [[X]] to <4 x i16>
; CHECK-NEXT: [[SHUFFLE1:%[^ ]+]] = shufflevector <4 x i16> [[BITCAST]], <4 x i16> poison, <2 x i32> <i32 0, i32 1>
; CHECK-NEXT: [[SHUFFLE2:%[^ ]+]] = shufflevector <4 x i16> [[BITCAST]], <4 x i16> poison, <2 x i32> <i32 2, i32 3>
; CHECK-NEXT: [[BITCAST1:%[^ ]+]] = bitcast <2 x i16> [[SHUFFLE1]] to <4 x i8>
; CHECK-NEXT: [[BITCAST2:%[^ ]+]] = bitcast <2 x i16> [[SHUFFLE2]] to <4 x i8>
; CHECK-NEXT: [[Y0:%[^ ]+]] = extractelement <4 x i8> [[BITCAST1]], i64 0
; CHECK-NEXT: [[Y1:%[^ ]+]] = extractelement <4 x i8> [[BITCAST1]], i64 1
; CHECK-NEXT: [[Y2:%[^ ]+]] = extractelement <4 x i8> [[BITCAST1]], i64 2
; CHECK-NEXT: [[Y3:%[^ ]+]] = extractelement <4 x i8> [[BITCAST1]], i64 3
; CHECK-NEXT: [[Y4:%[^ ]+]] = extractelement <4 x i8> [[BITCAST2]], i64 0
; CHECK-NEXT: [[Y5:%[^ ]+]] = extractelement <4 x i8> [[BITCAST2]], i64 1
; CHECK-NEXT: [[Y6:%[^ ]+]] = extractelement <4 x i8> [[BITCAST2]], i64 2
; CHECK-NEXT: [[Y7:%[^ ]+]] = extractelement <4 x i8> [[BITCAST2]], i64 3
; CHECK-NEXT: [[TMP0:%[^ ]+]] = insertvalue [8 x i8] undef, i8 [[Y0]], 0
; CHECK-NEXT: [[TMP1:%[^ ]+]] = insertvalue [8 x i8] [[TMP0]], i8 [[Y1]], 1
; CHECK-NEXT: [[TMP2:%[^ ]+]] = insertvalue [8 x i8] [[TMP1]], i8 [[Y2]], 2
; CHECK-NEXT: [[TMP3:%[^ ]+]] = insertvalue [8 x i8] [[TMP2]], i8 [[Y3]], 3
; CHECK-NEXT: [[TMP4:%[^ ]+]] = insertvalue [8 x i8] [[TMP3]], i8 [[Y4]], 4
; CHECK-NEXT: [[TMP5:%[^ ]+]] = insertvalue [8 x i8] [[TMP4]], i8 [[Y5]], 5
; CHECK-NEXT: [[TMP6:%[^ ]+]] = insertvalue [8 x i8] [[TMP5]], i8 [[Y6]], 6
; CHECK-NEXT: [[TMP7:%[^ ]+]] = insertvalue [8 x i8] [[TMP6]], i8 [[Y7]], 7
; CHECK: ret [[OUT]] [[TMP7]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:i64]]
; CHECK-SAME: @v2s_A(
; CHECK-SAME: [[IN:\[8 x i8\]]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[X0:%[^ ]+]] = extractvalue [[IN]] [[X]], 0
; CHECK-NEXT: [[X1:%[^ ]+]] = extractvalue [[IN]] [[X]], 1
; CHECK-NEXT: [[X2:%[^ ]+]] = extractvalue [[IN]] [[X]], 2
; CHECK-NEXT: [[X3:%[^ ]+]] = extractvalue [[IN]] [[X]], 3
; CHECK-NEXT: [[X4:%[^ ]+]] = extractvalue [[IN]] [[X]], 4
; CHECK-NEXT: [[X5:%[^ ]+]] = extractvalue [[IN]] [[X]], 5
; CHECK-NEXT: [[X6:%[^ ]+]] = extractvalue [[IN]] [[X]], 6
; CHECK-NEXT: [[X7:%[^ ]+]] = extractvalue [[IN]] [[X]], 7
; CHECK-NEXT: [[TMP0:%[^ ]+]] = insertelement <4 x i8> undef, i8 [[X0]], i64 0
; CHECK-NEXT: [[TMP1:%[^ ]+]] = insertelement <4 x i8> [[TMP0]], i8 [[X1]], i64 1
; CHECK-NEXT: [[TMP2:%[^ ]+]] = insertelement <4 x i8> [[TMP1]], i8 [[X2]], i64 2
; CHECK-NEXT: [[TMP3:%[^ ]+]] = insertelement <4 x i8> [[TMP2]], i8 [[X3]], i64 3
; CHECK-NEXT: [[TMP4:%[^ ]+]] = insertelement <4 x i8> undef, i8 [[X4]], i64 0
; CHECK-NEXT: [[TMP5:%[^ ]+]] = insertelement <4 x i8> [[TMP4]], i8 [[X5]], i64 1
; CHECK-NEXT: [[TMP6:%[^ ]+]] = insertelement <4 x i8> [[TMP5]], i8 [[X6]], i64 2
; CHECK-NEXT: [[TMP7:%[^ ]+]] = insertelement <4 x i8> [[TMP6]], i8 [[X7]], i64 3
; CHECK-NEXT: [[BITCAST1:%[^ ]+]] = bitcast <4 x i8> [[TMP3]] to <2 x i16>
; CHECK-NEXT: [[BITCAST2:%[^ ]+]] = bitcast <4 x i8> [[TMP7]] to <2 x i16>
; CHECK-NEXT: [[SHUFFLE:%[^ ]+]] = shufflevector <2 x i16> [[BITCAST1]], <2 x i16> [[BITCAST2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK-NEXT: [[BITCAST:%[^ ]+]] = bitcast <4 x i16> [[SHUFFLE]] to i64
; CHECK: ret [[OUT]] [[BITCAST]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:\[8 x i64\]]]
; CHECK-SAME: @v2v_D(
; CHECK-SAME: [[IN:\[16 x i32\]]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[X0:%[^ ]+]] = extractvalue [[IN]] [[X]], 0
; CHECK-NEXT: [[X1:%[^ ]+]] = extractvalue [[IN]] [[X]], 1
; CHECK-NEXT: [[X2:%[^ ]+]] = extractvalue [[IN]] [[X]], 2
; CHECK-NEXT: [[X3:%[^ ]+]] = extractvalue [[IN]] [[X]], 3
; CHECK-NEXT: [[X4:%[^ ]+]] = extractvalue [[IN]] [[X]], 4
; CHECK-NEXT: [[X5:%[^ ]+]] = extractvalue [[IN]] [[X]], 5
; CHECK-NEXT: [[X6:%[^ ]+]] = extractvalue [[IN]] [[X]], 6
; CHECK-NEXT: [[X7:%[^ ]+]] = extractvalue [[IN]] [[X]], 7
; CHECK-NEXT: [[X8:%[^ ]+]] = extractvalue [[IN]] [[X]], 8
; CHECK-NEXT: [[X9:%[^ ]+]] = extractvalue [[IN]] [[X]], 9
; CHECK-NEXT: [[X10:%[^ ]+]] = extractvalue [[IN]] [[X]], 10
; CHECK-NEXT: [[X11:%[^ ]+]] = extractvalue [[IN]] [[X]], 11
; CHECK-NEXT: [[X12:%[^ ]+]] = extractvalue [[IN]] [[X]], 12
; CHECK-NEXT: [[X13:%[^ ]+]] = extractvalue [[IN]] [[X]], 13
; CHECK-NEXT: [[X14:%[^ ]+]] = extractvalue [[IN]] [[X]], 14
; CHECK-NEXT: [[X15:%[^ ]+]] = extractvalue [[IN]] [[X]], 15
; CHECK-NEXT: [[TMP0:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X0]], i64 0
; CHECK-NEXT: [[TMP1:%[^ ]+]] = insertelement <2 x i32> [[TMP0]], i32 [[X1]], i64 1
; CHECK-NEXT: [[TMP2:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X2]], i64 0
; CHECK-NEXT: [[TMP3:%[^ ]+]] = insertelement <2 x i32> [[TMP2]], i32 [[X3]], i64 1
; CHECK-NEXT: [[TMP4:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X4]], i64 0
; CHECK-NEXT: [[TMP5:%[^ ]+]] = insertelement <2 x i32> [[TMP4]], i32 [[X5]], i64 1
; CHECK-NEXT: [[TMP6:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X6]], i64 0
; CHECK-NEXT: [[TMP7:%[^ ]+]] = insertelement <2 x i32> [[TMP6]], i32 [[X7]], i64 1
; CHECK-NEXT: [[TMP8:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X8]], i64 0
; CHECK-NEXT: [[TMP9:%[^ ]+]] = insertelement <2 x i32> [[TMP8]], i32 [[X9]], i64 1
; CHECK-NEXT: [[TMP10:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X10]], i64 0
; CHECK-NEXT: [[TMP11:%[^ ]+]] = insertelement <2 x i32> [[TMP10]], i32 [[X11]], i64 1
; CHECK-NEXT: [[TMP12:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X12]], i64 0
; CHECK-NEXT: [[TMP13:%[^ ]+]] = insertelement <2 x i32> [[TMP12]], i32 [[X13]], i64 1
; CHECK-NEXT: [[TMP14:%[^ ]+]] = insertelement <2 x i32> undef, i32 [[X14]], i64 0
; CHECK-NEXT: [[TMP15:%[^ ]+]] = insertelement <2 x i32> [[TMP14]], i32 [[X15]], i64 1
; CHECK-NEXT: [[Y0:%[^ ]+]] = bitcast <2 x i32> [[TMP1]] to i64
; CHECK-NEXT: [[Y1:%[^ ]+]] = bitcast <2 x i32> [[TMP3]] to i64
; CHECK-NEXT: [[Y2:%[^ ]+]] = bitcast <2 x i32> [[TMP5]] to i64
; CHECK-NEXT: [[Y3:%[^ ]+]] = bitcast <2 x i32> [[TMP7]] to i64
; CHECK-NEXT: [[Y4:%[^ ]+]] = bitcast <2 x i32> [[TMP9]] to i64
; CHECK-NEXT: [[Y5:%[^ ]+]] = bitcast <2 x i32> [[TMP11]] to i64
; CHECK-NEXT: [[Y6:%[^ ]+]] = bitcast <2 x i32> [[TMP13]] to i64
; CHECK-NEXT: [[Y7:%[^ ]+]] = bitcast <2 x i32> [[TMP15]] to i64
; CHECK-NEXT: [[TMP0:%[^ ]+]] = insertvalue [8 x i64] undef, i64 [[Y0]], 0
; CHECK-NEXT: [[TMP1:%[^ ]+]] = insertvalue [8 x i64] [[TMP0]], i64 [[Y1]], 1
; CHECK-NEXT: [[TMP2:%[^ ]+]] = insertvalue [8 x i64] [[TMP1]], i64 [[Y2]], 2
; CHECK-NEXT: [[TMP3:%[^ ]+]] = insertvalue [8 x i64] [[TMP2]], i64 [[Y3]], 3
; CHECK-NEXT: [[TMP4:%[^ ]+]] = insertvalue [8 x i64] [[TMP3]], i64 [[Y4]], 4
; CHECK-NEXT: [[TMP5:%[^ ]+]] = insertvalue [8 x i64] [[TMP4]], i64 [[Y5]], 5
; CHECK-NEXT: [[TMP6:%[^ ]+]] = insertvalue [8 x i64] [[TMP5]], i64 [[Y6]], 6
; CHECK-NEXT: [[TMP7:%[^ ]+]] = insertvalue [8 x i64] [[TMP6]], i64 [[Y7]], 7
; CHECK: ret [[OUT]] [[TMP7]]

; CHECK-LABEL: define spir_func
; CHECK-SAME: [[OUT:<4 x i64>]]
; CHECK-SAME: @v2v_C(
; CHECK-SAME: [[IN:\[8 x i32\]]]
; CHECK-SAME: [[X:%[^ ]+]])
; CHECK-NEXT: [[X0:%[^ ]+]] = extractvalue [[IN]] [[X]], 0
; CHECK-NEXT: [[X1:%[^ ]+]] = extractvalue [[IN]] [[X]], 1
; CHECK-NEXT: [[X2:%[^ ]+]] = extractvalue [[IN]] [[X]], 2
; CHECK-NEXT: [[X3:%[^ ]+]] = extractvalue [[IN]] [[X]], 3
; CHECK-NEXT: [[X4:%[^ ]+]] = extractvalue [[IN]] [[X]], 4
; CHECK-NEXT: [[X5:%[^ ]+]] = extractvalue [[IN]] [[X]], 5
; CHECK-NEXT: [[X6:%[^ ]+]] = extractvalue [[IN]] [[X]], 6
; CHECK-NEXT: [[X7:%[^ ]+]] = extractvalue [[IN]] [[X]], 7
; CHECK-NEXT: [[TMP0:%[^ ]+]] = insertelement <4 x i32> undef, i32 [[X0]], i64 0
; CHECK-NEXT: [[TMP1:%[^ ]+]] = insertelement <4 x i32> [[TMP0]], i32 [[X1]], i64 1
; CHECK-NEXT: [[TMP2:%[^ ]+]] = insertelement <4 x i32> [[TMP1]], i32 [[X2]], i64 2
; CHECK-NEXT: [[TMP3:%[^ ]+]] = insertelement <4 x i32> [[TMP2]], i32 [[X3]], i64 3
; CHECK-NEXT: [[TMP4:%[^ ]+]] = insertelement <4 x i32> undef, i32 [[X4]], i64 0
; CHECK-NEXT: [[TMP5:%[^ ]+]] = insertelement <4 x i32> [[TMP4]], i32 [[X5]], i64 1
; CHECK-NEXT: [[TMP6:%[^ ]+]] = insertelement <4 x i32> [[TMP5]], i32 [[X6]], i64 2
; CHECK-NEXT: [[TMP7:%[^ ]+]] = insertelement <4 x i32> [[TMP6]], i32 [[X7]], i64 3
; CHECK-NEXT: [[BITCAST1:%[^ ]+]] = bitcast <4 x i32> [[TMP3]] to <2 x i64>
; CHECK-NEXT: [[BITCAST2:%[^ ]+]] = bitcast <4 x i32> [[TMP7]] to <2 x i64>
; CHECK-NEXT: [[SHUFFLE:%[^ ]+]] = shufflevector <2 x i64> [[BITCAST1]], <2 x i64> [[BITCAST2]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK: ret [[OUT]] [[SHUFFLE]]

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
