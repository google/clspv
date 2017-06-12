// RUN: not clspv -samplermap %S/empty.samplermap %s 2> %t
// RUN: FileCheck %s < %t

// CHECK: Error: Sampler map was an empty file!
