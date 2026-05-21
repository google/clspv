
// Check that clspv does not allow physical storage buffers with the 'spir'
// target.
// RUN: not clspv %s -o %t.spv -arch=spirv32 -physical-storage-buffers

kernel void test()
{
}
