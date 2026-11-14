// RUN: clspv %target -DFN=degrees %s -o %t.deg.spv
// RUN: spirv-dis -o %t.deg.spvasm %t.deg.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,SCALAR < %t.deg.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.spv

// RUN: clspv %target -O0 -DFN=degrees %s -o %t.deg.o0.spv
// RUN: spirv-dis -o %t.deg.o0.spvasm %t.deg.o0.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,SCALAR < %t.deg.o0.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.o0.spv

// RUN: clspv %target -cl-native-math -DFN=degrees %s -o %t.deg.native.spv
// RUN: spirv-dis -o %t.deg.native.spvasm %t.deg.native.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,SCALAR < %t.deg.native.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.native.spv

// RUN: clspv %target -DTYPE=double2 -DFN=degrees %s -o %t.deg.v2.spv
// RUN: spirv-dis -o %t.deg.v2.spvasm %t.deg.v2.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,VEC -DN=2 < %t.deg.v2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.v2.spv

// RUN: clspv %target -DTYPE=double3 -DFN=degrees %s -o %t.deg.v3.spv
// RUN: spirv-dis -o %t.deg.v3.spvasm %t.deg.v3.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,VEC -DN=3 < %t.deg.v3.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.v3.spv

// ReplaceOpenCLBuiltinPass lowers double3 before ThreeElementVectorLoweringPass,
// so -vec3-to-vec4 widens the fmul directly to 4 elements without shuffles.
// RUN: clspv %target -DTYPE=double3 -vec3-to-vec4 -DFN=degrees %s -o %t.deg.v3to4.spv
// RUN: spirv-dis -o %t.deg.v3to4.spvasm %t.deg.v3to4.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,VEC -DN=4 < %t.deg.v3to4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.v3to4.spv

// RUN: clspv %target -DTYPE=double8 --long-vector -DFN=degrees %s -o %t.deg.v8.spv
// RUN: spirv-dis -o %t.deg.v8.spvasm %t.deg.v8.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,DEG,SCALAR8 < %t.deg.v8.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.deg.v8.spv

// RUN: clspv %target -DFN=radians %s -o %t.rad.spv
// RUN: spirv-dis -o %t.rad.spvasm %t.rad.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,RAD,SCALAR < %t.rad.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.rad.spv

// RUN: clspv %target -DTYPE=double4 -DFN=radians %s -o %t.rad.v4.spv
// RUN: spirv-dis -o %t.rad.v4.spvasm %t.rad.v4.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,RAD,VEC -DN=4 < %t.rad.v4.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.rad.v4.spv

// RUN: clspv %target -DTYPE=double8 --long-vector -DFN=radians %s -o %t.rad.v8.spv
// RUN: spirv-dis -o %t.rad.v8.spvasm %t.rad.v8.spv
// RUN: FileCheck %s --implicit-check-not=GLSL.std.450 --implicit-check-not=Degrees --implicit-check-not=Radians --check-prefixes=CHECK,RAD,SCALAR8 < %t.rad.v8.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.rad.v8.spv

// CHECK-DAG: %[[DOUBLE:[a-zA-Z0-9_]+]] = OpTypeFloat 64
// DEG-DAG: %[[CONST:[a-zA-Z0-9_]+]] = OpConstant %[[DOUBLE]] 57.295779513082323
// RAD-DAG: %[[CONST:[a-zA-Z0-9_]+]] = OpConstant %[[DOUBLE]] 0.017453292519943295
// VEC-DAG: %[[VEC:[a-zA-Z0-9_]+]] = OpTypeVector %[[DOUBLE]] [[N]]
// VEC-DAG: %[[SPLAT:[a-zA-Z0-9_]+]] = OpConstantComposite %[[VEC]] %[[CONST]]
// SCALAR: %[[LOAD:[a-zA-Z0-9_]+]] = OpLoad %[[DOUBLE]]
// SCALAR: OpFMul %[[DOUBLE]] %[[LOAD]] %[[CONST]]
// VEC: %[[LOAD:[a-zA-Z0-9_]+]] = OpLoad %[[VEC]]
// VEC: OpFMul %[[VEC]] %[[LOAD]] %[[SPLAT]]
// SCALAR8-COUNT-8: OpFMul %[[DOUBLE]] %{{[a-zA-Z0-9_]+}} %[[CONST]]

#ifndef TYPE
#define TYPE double
#endif

kernel void foo(global TYPE *a, global TYPE *b) { *a = FN(*b); }
