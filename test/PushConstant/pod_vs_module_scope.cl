// Valid combinations
// RUN: clspv %target %s -o %t.spv -pod-pushconstant -global-offset 2>&1
// RUN: clspv %target %s -o %t.spv -pod-ubo -global-offset-push-constant 2>&1
// RUN: clspv %target %s -o %t.spv -pod-ubo -cl-std=CL2.0 -inline-entry-points 2>&1

// POD args cannot be push constants if there are module scope push constants
// RUN: not clspv %target %s -pod-pushconstant -global-offset-push-constant 2>&1 | FileCheck %s
// RUN: not clspv %target %s -pod-pushconstant -cl-std=CL2.0 -inline-entry-points 2>&1 | FileCheck %s
// CHECK: POD arguments as push constants are not compatible with module scope push constants
