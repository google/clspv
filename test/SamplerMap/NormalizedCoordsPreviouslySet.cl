// RUN: not clspv -samplermap %S/normalized_coords_previously_set.samplermap %s 2> %t
// RUN: FileCheck %s < %t

// CHECK: Error: Sampler map normalized coordinates was previously set!
