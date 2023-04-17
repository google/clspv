// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL1.0 %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK10 %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL1.1 %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK11 %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL1.2 %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK12 %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK20 %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CL3.0 --inline-entry-points %s -o %t.spv
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck --check-prefix=CHECK30 %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: OpSource OpenCL_C 120

// CHECK10: OpSource OpenCL_C 100
// CHECK11: OpSource OpenCL_C 110
// CHECK12: OpSource OpenCL_C 120
// CHECK20: OpSource OpenCL_C 200
// CHECK30: OpSource OpenCL_C 300

void kernel test() {}

