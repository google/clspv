; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define i32 @isnormal_double(double %x) {
entry:
  %call = call spir_func i32 @_Z8isnormald(double %x)
  ret i32 %call
}

declare spir_func i32 @_Z8isnormald(double)

; CHECK: [[cast:%[a-zA-Z0-9_.]+]] = bitcast double %x to i64
; CHECK: [[abs:%[a-zA-Z0-9_.]+]] = and i64 [[cast]], 9223372036854775807
; CHECK: [[lt:%[a-zA-Z0-9_.]+]] = icmp ult i64 [[abs]], 9218868437227405312
; CHECK: [[ge:%[a-zA-Z0-9_.]+]] = icmp uge i64 [[abs]], 4503599627370496
; CHECK: [[and:%[a-zA-Z0-9_.]+]] = and i1 [[lt]], [[ge]]
; CHECK: [[zext:%[a-zA-Z0-9_]+]] = zext i1 [[and]] to i32
; CHECK: ret i32 [[zext]]

