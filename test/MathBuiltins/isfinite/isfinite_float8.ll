; RUN: clspv-opt --passes=replace-opencl-builtin,long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

declare spir_func <8 x i32> @_Z8isfiniteDv8_f(<8 x float>)

define spir_kernel void @test(<8 x float> %val, ptr addrspace(1) nocapture %out) {
entry:
  %call = tail call spir_func <8 x i32> @_Z8isfiniteDv8_f(<8 x float> %val)
  store <8 x i32> %call, ptr addrspace(1) %out, align 32
  ret void
}

; CHECK-LABEL: define spir_kernel void @test(
; CHECK-SAME: [[FLOAT8:\[8 x float\]]] [[VAL:%[^ ,]+]],
; CHECK-SAME: ptr addrspace(1) nocapture [[OUT:%[^ )]+]]
; CHECK-SAME: )

; CHECK-DAG: [[V0:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 0
; CHECK-DAG: [[V1:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 1
; CHECK-DAG: [[V2:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 2
; CHECK-DAG: [[V3:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 3
; CHECK-DAG: [[V4:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 4
; CHECK-DAG: [[V5:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 5
; CHECK-DAG: [[V6:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 6
; CHECK-DAG: [[V7:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 7

; CHECK-DAG: [[A0:%[^ ]+]] = bitcast float [[V0]] to i32
; CHECK-DAG: [[A1:%[^ ]+]] = bitcast float [[V1]] to i32
; CHECK-DAG: [[A2:%[^ ]+]] = bitcast float [[V2]] to i32
; CHECK-DAG: [[A3:%[^ ]+]] = bitcast float [[V3]] to i32
; CHECK-DAG: [[A4:%[^ ]+]] = bitcast float [[V4]] to i32
; CHECK-DAG: [[A5:%[^ ]+]] = bitcast float [[V5]] to i32
; CHECK-DAG: [[A6:%[^ ]+]] = bitcast float [[V6]] to i32
; CHECK-DAG: [[A7:%[^ ]+]] = bitcast float [[V7]] to i32

; CHECK-DAG: [[B0:%[^ ]+]] = and i32 [[A0]], 2139095040
; CHECK-DAG: [[B1:%[^ ]+]] = and i32 [[A1]], 2139095040
; CHECK-DAG: [[B2:%[^ ]+]] = and i32 [[A2]], 2139095040
; CHECK-DAG: [[B3:%[^ ]+]] = and i32 [[A3]], 2139095040
; CHECK-DAG: [[B4:%[^ ]+]] = and i32 [[A4]], 2139095040
; CHECK-DAG: [[B5:%[^ ]+]] = and i32 [[A5]], 2139095040
; CHECK-DAG: [[B6:%[^ ]+]] = and i32 [[A6]], 2139095040
; CHECK-DAG: [[B7:%[^ ]+]] = and i32 [[A7]], 2139095040

; CHECK-DAG: [[C0:%[^ ]+]] = icmp ne i32 [[B0]], 2139095040
; CHECK-DAG: [[C1:%[^ ]+]] = icmp ne i32 [[B1]], 2139095040
; CHECK-DAG: [[C2:%[^ ]+]] = icmp ne i32 [[B2]], 2139095040
; CHECK-DAG: [[C3:%[^ ]+]] = icmp ne i32 [[B3]], 2139095040
; CHECK-DAG: [[C4:%[^ ]+]] = icmp ne i32 [[B4]], 2139095040
; CHECK-DAG: [[C5:%[^ ]+]] = icmp ne i32 [[B5]], 2139095040
; CHECK-DAG: [[C6:%[^ ]+]] = icmp ne i32 [[B6]], 2139095040
; CHECK-DAG: [[C7:%[^ ]+]] = icmp ne i32 [[B7]], 2139095040

; CHECK-DAG: [[D0:%[^ ]+]] = sext i1 [[C0]] to i32
; CHECK-DAG: [[D1:%[^ ]+]] = sext i1 [[C1]] to i32
; CHECK-DAG: [[D2:%[^ ]+]] = sext i1 [[C2]] to i32
; CHECK-DAG: [[D3:%[^ ]+]] = sext i1 [[C3]] to i32
; CHECK-DAG: [[D4:%[^ ]+]] = sext i1 [[C4]] to i32
; CHECK-DAG: [[D5:%[^ ]+]] = sext i1 [[C5]] to i32
; CHECK-DAG: [[D6:%[^ ]+]] = sext i1 [[C6]] to i32
; CHECK-DAG: [[D7:%[^ ]+]] = sext i1 [[C7]] to i32

; CHECK-DAG: [[E1:%[^ ]+]] = getelementptr inbounds [[INT8:i8]], ptr addrspace(1) [[OUT]], i64 4
; CHECK-DAG: [[E2:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 8
; CHECK-DAG: [[E3:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 12
; CHECK-DAG: [[E4:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 16
; CHECK-DAG: [[E5:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 20
; CHECK-DAG: [[E6:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 24
; CHECK-DAG: [[E7:%[^ ]+]] = getelementptr inbounds [[INT8]], ptr addrspace(1) [[OUT]], i64 28

; CHECK-DAG: store i32 [[D0]], ptr addrspace(1) %out
; CHECK-DAG: store i32 [[D1]], ptr addrspace(1) [[E1]]
; CHECK-DAG: store i32 [[D2]], ptr addrspace(1) [[E2]]
; CHECK-DAG: store i32 [[D3]], ptr addrspace(1) [[E3]]
; CHECK-DAG: store i32 [[D4]], ptr addrspace(1) [[E4]]
; CHECK-DAG: store i32 [[D5]], ptr addrspace(1) [[E5]]
; CHECK-DAG: store i32 [[D6]], ptr addrspace(1) [[E6]]
; CHECK-DAG: store i32 [[D7]], ptr addrspace(1) [[E7]]

; CHECK: ret void

