; RUN: clspv-opt --passes=replace-opencl-builtin,long-vector-lowering,instcombine %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

declare spir_func <8 x i32> @_Z8isfiniteDv8_f(<8 x float>)

define spir_kernel void @test(<8 x float> %val, ptr addrspace(1) %out) {
entry:
  %call = tail call spir_func <8 x i32> @_Z8isfiniteDv8_f(<8 x float> %val)
  store <8 x i32> %call, ptr addrspace(1) %out, align 32
  ret void
}

; CHECK-LABEL: define spir_kernel void @test(
; CHECK-SAME: [[FLOAT8:\[8 x float\]]] [[VAL:%[^ ,]+]],
; CHECK-SAME: ptr addrspace(1) [[OUT:%[^ )]+]]
; CHECK-SAME: )

; CHECK-DAG: [[V0:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 0
; CHECK-DAG: [[V1:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 1
; CHECK-DAG: [[V2:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 2
; CHECK-DAG: [[V3:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 3
; CHECK-DAG: [[V4:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 4
; CHECK-DAG: [[V5:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 5
; CHECK-DAG: [[V6:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 6
; CHECK-DAG: [[V7:%[^ ]+]] = extractvalue [[FLOAT8]] [[VAL]], 7

; CHECK-DAG: [[ABS0:%[^ ]+]] = call float @llvm.fabs.f32(float [[V0]])
; CHECK-DAG: [[ABS1:%[^ ]+]] = call float @llvm.fabs.f32(float [[V1]])
; CHECK-DAG: [[ABS2:%[^ ]+]] = call float @llvm.fabs.f32(float [[V2]])
; CHECK-DAG: [[ABS3:%[^ ]+]] = call float @llvm.fabs.f32(float [[V3]])
; CHECK-DAG: [[ABS4:%[^ ]+]] = call float @llvm.fabs.f32(float [[V4]])
; CHECK-DAG: [[ABS5:%[^ ]+]] = call float @llvm.fabs.f32(float [[V5]])
; CHECK-DAG: [[ABS6:%[^ ]+]] = call float @llvm.fabs.f32(float [[V6]])
; CHECK-DAG: [[ABS7:%[^ ]+]] = call float @llvm.fabs.f32(float [[V7]])

; CHECK-DAG: [[CMP0:%[^ ]+]] = fcmp one float [[ABS0]], 0x7FF0000000000000
; CHECK-DAG: [[CMP1:%[^ ]+]] = fcmp one float [[ABS1]], 0x7FF0000000000000
; CHECK-DAG: [[CMP2:%[^ ]+]] = fcmp one float [[ABS2]], 0x7FF0000000000000
; CHECK-DAG: [[CMP3:%[^ ]+]] = fcmp one float [[ABS3]], 0x7FF0000000000000
; CHECK-DAG: [[CMP4:%[^ ]+]] = fcmp one float [[ABS4]], 0x7FF0000000000000
; CHECK-DAG: [[CMP5:%[^ ]+]] = fcmp one float [[ABS5]], 0x7FF0000000000000
; CHECK-DAG: [[CMP6:%[^ ]+]] = fcmp one float [[ABS6]], 0x7FF0000000000000
; CHECK-DAG: [[CMP7:%[^ ]+]] = fcmp one float [[ABS7]], 0x7FF0000000000000

; CHECK-DAG: [[D0:%[^ ]+]] = sext i1 [[CMP0]] to i32
; CHECK-DAG: [[D1:%[^ ]+]] = sext i1 [[CMP1]] to i32
; CHECK-DAG: [[D2:%[^ ]+]] = sext i1 [[CMP2]] to i32
; CHECK-DAG: [[D3:%[^ ]+]] = sext i1 [[CMP3]] to i32
; CHECK-DAG: [[D4:%[^ ]+]] = sext i1 [[CMP4]] to i32
; CHECK-DAG: [[D5:%[^ ]+]] = sext i1 [[CMP5]] to i32
; CHECK-DAG: [[D6:%[^ ]+]] = sext i1 [[CMP6]] to i32
; CHECK-DAG: [[D7:%[^ ]+]] = sext i1 [[CMP7]] to i32

; CHECK-DAG: [[E1:%[^ ]+]] = getelementptr inbounds nuw [[INT8:i8]], ptr addrspace(1) [[OUT]], i64 4
; CHECK-DAG: [[E2:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 8
; CHECK-DAG: [[E3:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 12
; CHECK-DAG: [[E4:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 16
; CHECK-DAG: [[E5:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 20
; CHECK-DAG: [[E6:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 24
; CHECK-DAG: [[E7:%[^ ]+]] = getelementptr inbounds nuw [[INT8]], ptr addrspace(1) [[OUT]], i64 28

; CHECK-DAG: store i32 [[D0]], ptr addrspace(1) %out
; CHECK-DAG: store i32 [[D1]], ptr addrspace(1) [[E1]]
; CHECK-DAG: store i32 [[D2]], ptr addrspace(1) [[E2]]
; CHECK-DAG: store i32 [[D3]], ptr addrspace(1) [[E3]]
; CHECK-DAG: store i32 [[D4]], ptr addrspace(1) [[E4]]
; CHECK-DAG: store i32 [[D5]], ptr addrspace(1) [[E5]]
; CHECK-DAG: store i32 [[D6]], ptr addrspace(1) [[E6]]
; CHECK-DAG: store i32 [[D7]], ptr addrspace(1) [[E7]]

; CHECK: ret void

