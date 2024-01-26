// RUN: clspv -cl-std=CL3.0 -fp64=0 --enable-feature-macros=__opencl_c_atomic_order_acq_rel,__opencl_c_images,__opencl_c_atomic_order_seq_cst,__opencl_c_int64 %s -verify

#ifdef __opencl_c_3d_image_writes
#error __opencl_c_3d_image_writes should not be defined
#endif

#ifndef __opencl_c_atomic_order_acq_rel
#error __opencl_c_atomic_order_acq_rel should be defined
#endif

#ifdef __opencl_c_fp64
#error __opencl_c_fp64 should not be defined
#endif

#ifndef __opencl_c_images
#error __opencl_c_images should be defined
#endif

#ifdef __opencl_c_subgroups
#error __opencl_c_subgroups should not be defined
#endif

#ifndef __opencl_c_atomic_order_seq_cst
#error __opencl_c_atomic_order_seq_cst should be defined
#endif

#ifndef __opencl_c_atomic_scope_device
#error __opencl_c_atomic_scope_device should be defined
#endif

#ifdef __opencl_c_atomic_scope_all_devices
#error __opencl_c_atomic_scope_all_devices should not be defined
#endif

#ifdef __opencl_c_work_group_collective_functions
#error __opencl_c_work_group_collective_functions should not be defined
#endif

#ifdef __opencl_c_read_write_images
#error __opencl_c_read_write_images should not be defined
#endif

#ifndef __opencl_c_int64
#error __opencl_c_int64 should be defined
#endif

// not supported

#ifdef __opencl_c_device_enqueue
#error __opencl_c_device_enqueue should not be defined
#endif

#ifdef __opencl_c_generic_address_space
#error __opencl_c_generic_address_space should not be defined
#endif

#ifdef __opencl_c_pipes
#error __opencl_c_pipes should not be defined
#endif

#ifdef __opencl_c_program_scope_global_variables
#error __opencl_c_program_scope_global_variables should not be defined
#endif

//expected-no-diagnostics
