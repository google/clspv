// RUN: not clspv -samplermap %S/addressing_mode_previously_set.samplermap %s 2> %t
// RUN: FileCheck %s < %t

// CHECK: Error: Sampler map addressing mode was previously set!
