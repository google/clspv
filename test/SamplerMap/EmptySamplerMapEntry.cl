// RUN: not clspv -samplermap %S/empty_sampler_map_entry0.samplermap %s 2> %t
// RUN: FileCheck %s < %t
// RUN: not clspv -samplermap %S/empty_sampler_map_entry1.samplermap %s 2> %t
// RUN: FileCheck %s < %t

// CHECK: Error: Sampler map contained an empty entry!
