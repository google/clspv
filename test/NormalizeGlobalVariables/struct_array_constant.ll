; RUN: clspv-opt %s -o %t.ll --passes=normalize-global-variables
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

%struct.Pair = type { i32, float }
%struct.Other = type { float, i32 }
%struct.Outer = type { %struct.Pair, <2 x i32> }

; Unnormalized globals remain at the top of the module:
; - Original @multi_use_diff_geom (still used with its unnormalized packed-struct type, renamed when its name was taken)
; - Negative test globals (@mismatch_struct_no_norm, @mismatch_size_no_norm)
; CHECK: [[DIFF_GEOM_ORIG:@[0-9a-zA-Z_.]+]] = addrspace(2) constant <{ [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }> }> <{ [2 x %struct.Pair] [%struct.Pair { i32 11, float 1.100000e+01 }, %struct.Pair { i32 12, float 1.200000e+01 }], <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 13, float 1.300000e+01 }, %struct.Pair zeroinitializer }> }>, align 4
; CHECK: @mismatch_struct_no_norm = addrspace(2) constant <{ %struct.Pair, %struct.Other }> <{ %struct.Pair { i32 1, float 2.000000e+00 }, %struct.Other { float 3.000000e+00, i32 4 } }>, align 4
; CHECK: @mismatch_size_no_norm = addrspace(2) constant <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 1, float 2.000000e+00 }, %struct.Pair { i32 3, float 4.000000e+00 } }>, align 4

; 1. Flat packed struct of structs normalized to 1D array of structs.
; CHECK: @flat_table = addrspace(2) constant [2 x %struct.Pair] [%struct.Pair { i32 1, float 2.000000e+00 }, %struct.Pair { i32 3, float 4.000000e+00 }]

; 2. Heterogeneous packed struct mixing array rows, partial struct rows, and
;    both array and packed-struct zeroinitializers normalized to a 2D array of structs.
; CHECK: @nested_2d_table = addrspace(2) constant [4 x [2 x %struct.Pair]]
; CHECK-SAME: [2 x %struct.Pair] [%struct.Pair { i32 1, float 1.000000e+00 }, %struct.Pair { i32 2, float 2.000000e+00 }]
; CHECK-SAME: [2 x %struct.Pair] [%struct.Pair { i32 3, float 3.000000e+00 }, %struct.Pair zeroinitializer]
; CHECK-SAME: [2 x %struct.Pair] zeroinitializer
; CHECK-SAME: [2 x %struct.Pair] zeroinitializer

; 3. Packed struct containing nested struct/vector elements normalized to 1D array of Outer structs.
; CHECK: @nested_struct_table = addrspace(2) constant [3 x %struct.Outer]
; CHECK-SAME: %struct.Outer { %struct.Pair { i32 10, float 5.000000e-01 }, <2 x i32> <i32 1, i32 2> }
; CHECK-SAME: %struct.Outer { %struct.Pair { i32 20, float 1.500000e+00 }, <2 x i32> <i32 3, i32 4> }
; CHECK-SAME: %struct.Outer zeroinitializer

; 4. 2D array of structs reshaped into a 1D array of structs.
; CHECK: @array_reshape_table = addrspace(2) constant [4 x %struct.Pair] [%struct.Pair { i32 1, float 1.000000e+00 }, %struct.Pair { i32 2, float 2.000000e+00 }, %struct.Pair zeroinitializer, %struct.Pair zeroinitializer]

; 5. Multiple GEP users with the same target array-of-struct type reuse one normalized global.
; CHECK: @multi_use_same_type = addrspace(2) constant [2 x %struct.Pair] [%struct.Pair { i32 7, float 8.000000e+00 }, %struct.Pair { i32 9, float 1.000000e+01 }]

; 6. Multiple GEP users with different geometries (1D array and 2D array).
; CHECK: [[DIFF_GEOM_1D:@[0-9a-zA-Z_.]+]] = addrspace(2) constant [4 x %struct.Pair] [%struct.Pair { i32 11, float 1.100000e+01 }, %struct.Pair { i32 12, float 1.200000e+01 }, %struct.Pair { i32 13, float 1.300000e+01 }, %struct.Pair zeroinitializer]
; CHECK: [[DIFF_GEOM_2D:@[0-9a-zA-Z_.]+]] = addrspace(2) constant [2 x [2 x %struct.Pair]]
; CHECK-SAME: [2 x %struct.Pair] [%struct.Pair { i32 11, float 1.100000e+01 }, %struct.Pair { i32 12, float 1.200000e+01 }]
; CHECK-SAME: [2 x %struct.Pair] [%struct.Pair { i32 13, float 1.300000e+01 }, %struct.Pair zeroinitializer]

@flat_table = addrspace(2) constant <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 1, float 2.000000e+00 }, %struct.Pair { i32 3, float 4.000000e+00 } }>, align 4

@nested_2d_table = addrspace(2) constant <{ [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }>, [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }> }> <{ [2 x %struct.Pair] [%struct.Pair { i32 1, float 1.000000e+00 }, %struct.Pair { i32 2, float 2.000000e+00 }], <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 3, float 3.000000e+00 }, %struct.Pair zeroinitializer }>, [2 x %struct.Pair] zeroinitializer, <{ %struct.Pair, %struct.Pair }> zeroinitializer }>, align 4

@nested_struct_table = addrspace(2) constant <{ %struct.Outer, [2 x %struct.Outer] }> <{ %struct.Outer { %struct.Pair { i32 10, float 5.000000e-01 }, <2 x i32> <i32 1, i32 2> }, [2 x %struct.Outer] [%struct.Outer { %struct.Pair { i32 20, float 1.500000e+00 }, <2 x i32> <i32 3, i32 4> }, %struct.Outer zeroinitializer] }>, align 8

@array_reshape_table = addrspace(2) constant [2 x [2 x %struct.Pair]] [[2 x %struct.Pair] [%struct.Pair { i32 1, float 1.000000e+00 }, %struct.Pair { i32 2, float 2.000000e+00 }], [2 x %struct.Pair] zeroinitializer], align 4

@multi_use_same_type = addrspace(2) constant <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 7, float 8.000000e+00 }, %struct.Pair { i32 9, float 1.000000e+01 } }>, align 4

@multi_use_diff_geom = addrspace(2) constant <{ [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }> }> <{ [2 x %struct.Pair] [%struct.Pair { i32 11, float 1.100000e+01 }, %struct.Pair { i32 12, float 1.200000e+01 }], <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 13, float 1.300000e+01 }, %struct.Pair zeroinitializer }> }>, align 4

@mismatch_struct_no_norm = addrspace(2) constant <{ %struct.Pair, %struct.Other }> <{ %struct.Pair { i32 1, float 2.000000e+00 }, %struct.Other { float 3.000000e+00, i32 4 } }>, align 4

@mismatch_size_no_norm = addrspace(2) constant <{ %struct.Pair, %struct.Pair }> <{ %struct.Pair { i32 1, float 2.000000e+00 }, %struct.Pair { i32 3, float 4.000000e+00 } }>, align 4

; CHECK-LABEL: define spir_kernel void @test_flat_and_nested(
; CHECK: getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @flat_table, i32 0, i32 %i, i32 0
; CHECK: getelementptr inbounds [4 x [2 x %struct.Pair]], ptr addrspace(2) @nested_2d_table, i32 0, i32 %i, i32 %j, i32 0
; CHECK: getelementptr inbounds [3 x %struct.Outer], ptr addrspace(2) @nested_struct_table, i32 0, i32 %i, i32 0, i32 0
; CHECK: getelementptr inbounds [4 x %struct.Pair], ptr addrspace(2) @array_reshape_table, i32 0, i32 %i, i32 0
define spir_kernel void @test_flat_and_nested(ptr addrspace(1) %out, i32 %i, i32 %j) {
entry:
  %gep1 = getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @flat_table, i32 0, i32 %i, i32 0
  %ld1 = load i32, ptr addrspace(2) %gep1, align 4

  %gep2 = getelementptr inbounds [4 x [2 x %struct.Pair]], ptr addrspace(2) @nested_2d_table, i32 0, i32 %i, i32 %j, i32 0
  %ld2 = load i32, ptr addrspace(2) %gep2, align 4

  %gep3 = getelementptr inbounds [3 x %struct.Outer], ptr addrspace(2) @nested_struct_table, i32 0, i32 %i, i32 0, i32 0
  %ld3 = load i32, ptr addrspace(2) %gep3, align 4

  %gep4 = getelementptr inbounds [4 x %struct.Pair], ptr addrspace(2) @array_reshape_table, i32 0, i32 %i, i32 0
  %ld4 = load i32, ptr addrspace(2) %gep4, align 4

  %sum0 = add i32 %ld1, %ld2
  %sum1 = add i32 %sum0, %ld3
  %sum2 = add i32 %sum1, %ld4
  store i32 %sum2, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_multi_uses(
; CHECK: getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @multi_use_same_type, i32 0, i32 %i, i32 0
; CHECK: getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @multi_use_same_type, i32 0, i32 %j, i32 0
; CHECK: getelementptr inbounds [2 x [2 x %struct.Pair]], ptr addrspace(2) [[DIFF_GEOM_2D]], i32 0, i32 %i, i32 %j, i32 0
; CHECK: getelementptr inbounds [4 x %struct.Pair], ptr addrspace(2) [[DIFF_GEOM_1D]], i32 0, i32 %i, i32 0
; CHECK: getelementptr inbounds <{ [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }> }>, ptr addrspace(2) [[DIFF_GEOM_ORIG]], i32 0, i32 1, i32 0, i32 0
define spir_kernel void @test_multi_uses(ptr addrspace(1) %out, i32 %i, i32 %j) {
entry:
  %gep_same1 = getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @multi_use_same_type, i32 0, i32 %i, i32 0
  %ld_same1 = load i32, ptr addrspace(2) %gep_same1, align 4

  %gep_same2 = getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @multi_use_same_type, i32 0, i32 %j, i32 0
  %ld_same2 = load i32, ptr addrspace(2) %gep_same2, align 4

  %gep_2d = getelementptr inbounds [2 x [2 x %struct.Pair]], ptr addrspace(2) @multi_use_diff_geom, i32 0, i32 %i, i32 %j, i32 0
  %ld_2d = load i32, ptr addrspace(2) %gep_2d, align 4

  %gep_1d = getelementptr inbounds [4 x %struct.Pair], ptr addrspace(2) @multi_use_diff_geom, i32 0, i32 %i, i32 0
  %ld_1d = load i32, ptr addrspace(2) %gep_1d, align 4

  %gep_orig = getelementptr inbounds <{ [2 x %struct.Pair], <{ %struct.Pair, %struct.Pair }> }>, ptr addrspace(2) @multi_use_diff_geom, i32 0, i32 1, i32 0, i32 0
  %ld_orig = load i32, ptr addrspace(2) %gep_orig, align 4

  %s0 = add i32 %ld_same1, %ld_same2
  %s1 = add i32 %s0, %ld_2d
  %s2 = add i32 %s1, %ld_1d
  %s3 = add i32 %s2, %ld_orig
  store i32 %s3, ptr addrspace(1) %out, align 4
  ret void
}

; CHECK-LABEL: define spir_kernel void @test_negative(
; CHECK: getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @mismatch_struct_no_norm, i32 0, i32 %i, i32 0
; CHECK: getelementptr inbounds [3 x %struct.Pair], ptr addrspace(2) @mismatch_size_no_norm, i32 0, i32 %i, i32 0
define spir_kernel void @test_negative(ptr addrspace(1) %out, i32 %i) {
entry:
  %gep1 = getelementptr inbounds [2 x %struct.Pair], ptr addrspace(2) @mismatch_struct_no_norm, i32 0, i32 %i, i32 0
  %ld1 = load i32, ptr addrspace(2) %gep1, align 4

  %gep2 = getelementptr inbounds [3 x %struct.Pair], ptr addrspace(2) @mismatch_size_no_norm, i32 0, i32 %i, i32 0
  %ld2 = load i32, ptr addrspace(2) %gep2, align 4

  %sum = add i32 %ld1, %ld2
  store i32 %sum, ptr addrspace(1) %out, align 4
  ret void
}
