// RUN: clspv %s -o %t.spv -descriptormap=%t.map
// RUN: FileCheck %s < %t.map
// RUN: spirv-val --target-env vulkan1.0 %t.spv

//      CHECK: sampler,16,samplerExpr,"CLK_NORMALIZED_COORDS_FALSE|CLK_ADDRESS_NONE|CLK_FILTER_NEAREST",descriptorSet,0,binding,0
// CHECK-NEXT: kernel,readf,arg,im1d,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readf,arg,im2d,argOrdinal,1,descriptorSet,1,binding,1,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readf,arg,im3d,argOrdinal,2,descriptorSet,1,binding,2,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readf,arg,out,argOrdinal,3,descriptorSet,1,binding,3,offset,0,argKind,buffer
// CHECK-NEXT: kernel,readui,arg,im1d,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readui,arg,im2d,argOrdinal,1,descriptorSet,1,binding,1,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readui,arg,im3d,argOrdinal,2,descriptorSet,1,binding,2,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readui,arg,out,argOrdinal,3,descriptorSet,1,binding,3,offset,0,argKind,buffer
// CHECK-NEXT: kernel,readi,arg,im1d,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readi,arg,im2d,argOrdinal,1,descriptorSet,1,binding,1,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readi,arg,im3d,argOrdinal,2,descriptorSet,1,binding,2,offset,0,argKind,ro_image
// CHECK-NEXT: kernel,readi,arg,out,argOrdinal,3,descriptorSet,1,binding,3,offset,0,argKind,buffer

kernel void readf(read_only image1d_t im1d, read_only image2d_t im2d, read_only image3d_t im3d, global float4* out) {
  out[0] = read_imagef(im1d, 0);
  out[1] = read_imagef(im2d, (int2)(0));
  out[2] = read_imagef(im3d, (int4)(0));
}

kernel void readui(read_only image1d_t im1d, read_only image2d_t im2d, read_only image3d_t im3d, global uint4* out) {
  out[0] = read_imageui(im1d, 0);
  out[1] = read_imageui(im2d, (int2)(0));
  out[2] = read_imageui(im3d, (int4)(0));
}

kernel void readi(read_only image1d_t im1d, read_only image2d_t im2d, read_only image3d_t im3d, global int4* out) {
  out[0] = read_imagei(im1d, 0);
  out[1] = read_imagei(im2d, (int2)(0));
  out[2] = read_imagei(im3d, (int4)(0));
}

