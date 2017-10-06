# OpenCL C 1.2 Language on Vulkan

## Overview

The OpenCL C 1.2 language provides an expressive variant of the C language with
which to program heterogeneous architectures.
There is already a significant body of code in the wild written in the OpenCL C
language - both in open source and proprietary software.
This document explains how the OpenCL C language is mapped onto an
implementation of the Vulkan standard for high-performance graphics and compute.

The following subjects are covered:

- Which SPIR-V features are used.
- How the Vulkan API makes use of the Vulkan variant of SPIR-V produced.
- How OpenCL C language constructs are mapped down onto Vulkan's variant of
  SPIR-V.
- Restrictions on the OpenCL C language as is to be consumed by a Vulkan
  implementation.

## SPIR-V Features

The SPIR-V as produced from the OpenCL C language can make use of the following
additional extensions:

- _SPV\_KHR\_variable\_pointers_ - to enable the support of more expressive
  pointers that the OpenCL C language can make use of.
- _SPV\_KHR\_storage\_buffer\_storage\_class_ - required by
  _SPV\_KHR\_variable\_pointers_, to enable use of the StorageBuffer storage
  class.

The SPIR-V as produced from the OpenCL C language can make use of the following
capabilities:

- `Shader` as we are targeting the OpenCL C language at a Vulkan implementation.
- `VariablePointers`, from the _SPV\_KHR\_variable\_pointers_ extension.
  - *Note*: The compiler always emits code that depends on `VariablePointers`
    even though there might some cases where it is not strictly needed.

## Vulkan Interaction

A Vulkan implementation that is to consume the SPIR-V produced from the OpenCL C
language must conform to the following the rules:

- If the short/ushort types are used in the OpenCL C:
  - The `shaderInt16` field of `VkPhysicalDeviceFeatures` **must** be set to
    true.
- If images are used in the OpenCL C:
  - The `shaderStorageImageReadWithoutFormat` field of
    `VkPhysicalDeviceFeatures` **must** be set to true.
  - The `shaderStorageImageWriteWithoutFormat` field of
    `VkPhysicalDeviceFeatures` **must** be set to true.
- The implementation **must** support extensions _VK\_KHR\_storage\_buffer\_storage\_class_ and
  _VK\_KHR\_variable\_pointers_:
  - A call to `vkCreateDevice()` where the `ppEnabledExtensionNames` field of
    `VkDeviceCreateInfo` contains extension strings
    _"VK\_KHR\_storage\_buffer\_storage\_class"_ and
    _"VK\_KHR\_variable\_pointers"_ **must** succeed.

### Descriptor Type Mappings

OpenCL C kernel argument types are mapped to Vulkan descriptor types in the
following way:

- If the argument to the kernel is a read only image, the matching Vulkan
  descriptor set type is `VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE`.
- If the argument to the kernel is a write only image, the matching Vulkan
  descriptor set type is `VK_DESCRIPTOR_TYPE_STORAGE_IMAGE`.
- If the argument to the kernel is a sampler, the matching Vulkan
  descriptor set type is `VK_DESCRIPTOR_TYPE_SAMPLER`.
- If the argument to the kernel is a constant or global pointer type, the
  matching Vulkan descriptor set type is `VK_DESCRIPTOR_TYPE_STORAGE_BUFFER`.
- If the argument to the kernel is a plain-old-data type, the matching Vulkan
  descriptor set type is `VK_DESCRIPTOR_TYPE_STORAGE_BUFFER`.

Note: If `-cluster-pod-kernel-args` is used, then all plain-old-data kernel
arguments are collected into a single structure to be passed in to the compute
shader as a single storage buffer resource.

## OpenCL C Modifications

Some OpenCL C language features that are not natively expressible in Vulkan's
variant of SPIR-V, require a subtle mapping to how Vulkan SPIR-V represents the
corresponding functionality.

### Compilation

An additional preprocessor macro `VULKAN` is set, to allow developers to guard
OpenCL C functionality based on whether the Vulkan API is being targeted or not.
This value is set to 100, to match Vulkan version 1.0.

### Kernels

OpenCL C language kernels take the form:

    void kernel foo(global int* a, global float* b, uint c);

SPIR-V tracks OpenCL C language kernels using `OpEntryPoint` opcodes that denote
the entry-points where an API interacts with a compute kernel.

Vulkan's variant of SPIR-V requires that the entry-points be `void` return
functions, and that they take no arguments.
To pass data into Vulkan SPIR-V shaders, `OpVariable`s are declared outside of
the functions, and decorated with `DescriptorSet` and `Binding` decorations, to
denote that the shaders can interact with their data.

The default way to map an OpenCL C language kernel to a Vulkan SPIR-V compute
shader is as follows:

- If a sampler map file is specified, all literal samplers use descriptor set _0_.
- By default, all kernels in the translation unit use the same descriptor set
  number, either _0_ or _1_.  (They use 1 if a sampler map is specified.)
  **This is new default behaviour**.
  - Use option `-distinct-kernel-descriptor-sets` to get the old behaviour,
  where each kernel is assigned its own descriptor set number, such that the first
  kernel has descriptor set _0_, and each subsequent kernel is an increment of
  _1_ from the previous.
- Each argument within each kernel is assigned a binding in that kernel's
  corresponding `DescriptorSet` such that the `Binding` is equal to the position
  of the argument in the kernel's argument list, where the first argument for
  the kernel has a `Binding` of _0_.
- If the argument to the kernel is a `global` or `constant` pointer, it is
  placed into a SPIR-V `OpTypeStruct` that is decorated with `BufferBlock`, and
  an `OpVariable` of this structure type is created and decorated with the
  corresponding `DescriptorSet` and `Binding`, using the `Uniform` storage
  class.
- If the argument to the kernel is a plain-old-data type, it is placed into a
  SPIR-V `OpTypeStruct` that is decorated with `BufferBlock`, and an
  `OpVariable` of this structure type is created and decorated with the
  corresponding `DescriptorSet` and `Binding`, using the `Uniform` storage
  class.
- If the argument to the kernel is an image or sampler, an `OpVariable` of the
  `OpTypeImage` or `OpTypeSampler` type is created and decorated with the
  corresponding `DescriptorSet` and `Binding`, using the `UniformConstant`
  storage class.

#### Descriptor map

The compiler can tell you what descriptor set and bindings are used for samplers
in the sampler map and kernel arguments.
Use option `-descriptormap` to name a file that should contain the mapping information.

Example:

    clspv foo.cl -descriptormap=foomap.csv

The descriptor map is a text file with comma-separated values.

Consider this example:

    // First kernel in the translation unit, and no sampler map is used.
    void kernel foo(global int* a, float f, global float* b, uint c) {...}

It generates the following descriptor map:

    kernel,foo,arg,a,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
    kernel,foo,arg,f,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,pod
    kernel,foo,arg,b,argOrdinal,2,descriptorSet,0,binding,2,offset,0,argKind,buffer
    kernel,foo,arg,c,argOrdinal,3,descriptorSet,0,binding,3,offset,0,argKind,pod

For kernel arguments, the fields are:
- `kernel` to indicate a kernel argument
- kernel name
- `arg` to indicate a kernel argument
- argument name
- `argOrdinal` to indicate a kernel argument ordinal position field
- the argument's 0-based position in the kernel's parameter list
- `descriptorSet`
- the DescriptorSet value
- `binding`
- the Binding value
- `offset`
- The byte offset inside the storage buffer where you should write the argument value.
  This will always be zero, unless you cluster plain-old-data kernel arguments. (See below.)
- `argKind`
- a string describing the kind of argument, one of:
  - `buffer` - OpenCL buffer
  - `pod` - Plain Old Data, e.g. a scalar, vector, or structure
  - `ro_image` - Read-only image
  - `wo_image` - Write-only image
  - `sampler` - Sampler

If a sampler map is used, then samplers use descriptor set 0 and kernel descriptor
set numbers start at 1.  For example, if the sampler map file is `mysamplermap`
containing:

    CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST,
    CLK_NORMALIZED_COORDS_TRUE  | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR

Then compiling with:

    clspv foo.cl -samplermap=mysamplermap -descriptormap=mydescriptormap

Then `mydescriptormap` will contain:

    sampler,18,samplerExpr,"CLK_ADDRESS_CLAMP_TO_EDGE|CLK_FILTER_NEAREST|CLK_NORMALIZED_COORDS_FALSE",descriptorSet,0,binding,0
    sampler,35,samplerExpr,"CLK_ADDRESS_CLAMP_TO_EDGE|CLK_FILTER_LINEAR|CLK_NORMALIZED_COORDS_TRUE",descriptorSet,0,binding,1
    kernel,foo,arg,a,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,buffer
    kernel,foo,arg,f,argOrdinal,1,descriptorSet,1,binding,1,offset,0,argKind,pod
    kernel,foo,arg,b,argOrdinal,2,descriptorSet,1,binding,2,offset,0,argKind,buffer
    kernel,foo,arg,c,argOrdinal,3,descriptorSet,1,binding,3,offset,0,argKind,pod


#### Clustering plain-old-data kernel arguments to save descriptors

Descriptors can be scarce.  So the compiler also has an option
`-cluster-pod-kernel-args` which can be used to reduce the number of descriptors.
When the option is used:

- All plain-old-data (POD) kernel arguments are collected into a single struct
  and passed into the compute shader via a single storage buffer resource.
- The binding numbers are assigned as previously, except:
  - Binding numbers for non-POD arguments are assigned as if there were no
    POD arguments.
  - The binding number for the struct containing the POD arguments is one more
    than the highest non-POD argument.


#### Example descriptor set mapping

For example:

    // First kernel in the translation unit, and no sampler map is used.
    void kernel foo(global int* a, float f, global float* b, uint c);

In the default case, the bindings are:

- `a` is mapped to a storage buffer with descriptor set 0, binding 0
- `f` is mapped to a storage buffer with descriptor set 0, binding 1
- `b` is mapped to a storage buffer with descriptor set 0, binding 2
- `c` is mapped to a storage buffer with descriptor set 0, binding 3

If `-cluster-pod-kernel-args` is used:

- `a` is mapped to a storage buffer with descriptor set 0, binding 0
- `b` is mapped to a storage buffer with descriptor set 0, binding 1
- `f` and `c` are POD arguments, so they are mapped to the first and
  second members of a struct, and that struct is mapped to a storage
  buffer with descriptor set 0 and binding 2

That is, compiling as follows:

    clspv foo.cl -cluster-pod-kernel-args -descriptormap=myclusteredmap

will produce the following in `myclusteredmap`:

    kernel,foo,arg,a,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
    kernel,foo,arg,b,argOrdinal,2,descriptorSet,0,binding,1,offset,0,argKind,buffer
    kernel,foo,arg,f,argOrdinal,1,descriptorSet,0,binding,2,offset,0,argKind,pod
    kernel,foo,arg,c,argOrdinal,3,descriptorSet,0,binding,2,offset,4,argKind,pod

If `foo` were the second kernel in the translation unit, then its arguments
would also use descriptor set 0.
If `foo` were the second kernel in the translation unit _and_ option
`-distinct-kernel-descriptor-sets` is used, then its arguments would
use descriptor set 1.

Compiling with the same sampler map from before:

    clspv foo.cl -cluster-pod-kernel-args -descriptormap=myclusteredmap -samplermap=mysamplermap

produces the following descriptor map:

    sampler,18,samplerExpr,"CLK_ADDRESS_CLAMP_TO_EDGE|CLK_FILTER_NEAREST|CLK_NORMALIZED_COORDS_FALSE",descriptorSet,0,binding,0
    sampler,35,samplerExpr,"CLK_ADDRESS_CLAMP_TO_EDGE|CLK_FILTER_LINEAR|CLK_NORMALIZED_COORDS_TRUE",descriptorSet,0,binding,1
    kernel,foo,arg,a,argOrdinal,0,descriptorSet,1,binding,0,offset,0,argKind,buffer
    kernel,foo,arg,b,argOrdinal,2,descriptorSet,1,binding,1,offset,0,argKind,buffer
    kernel,foo,arg,f,argOrdinal,1,descriptorSet,1,binding,2,offset,0,argKind,pod
    kernel,foo,arg,c,argOrdinal,3,descriptorSet,1,binding,2,offset,4,argKind,pod


TODO(dneto): Give an example using images.

### Attributes

The following attributes are ignored in the OpenCL C source, and thus have
no functional impact on the produced SPIR-V:

- `__attribute__((work_group_size_hint(X, Y, Z)))`
- `__attribute__((packed))`
- `__attribute__ ((endian(host)))`
- `__attribute__ ((endian(device)))`
- `__attribute__((vec_type_hint(<typen>)))`

The `__attribute__((reqd_work_group_size(X, Y, Z)))` kernel attribute specifies
the work-group size that **must** be used with that kernel.


### Work-Group Size

The OpenCL C language allows the work-group size to be set just before executing
the kernel on the device, at `clEnqueueNDRangeKernel()` time.
Vulkan requires that the work group size be specified no later than when the
`VkPipeline` is created, which in OpenCL terms corresponds to when the
`cl_kernel` is created.

To allow for the maximum flexibility to developers who are used to specifying
the work-group size in the host API and not in the device-side kernel
language, we can use _specialization constants_ to allow for setting the work-group
size at `VkPipeline` creation time.

If the `reqd_work_group_size` attribute is used in the OpenCL C source, then that
attribute will specify the work-group size that must be used.
Otherwise, the Vulkan SPIR-V produced by the compiler will contain specialization
constants as follows:

- The _x_ dimension of the work-group size is stored in a specialization
  constant that is decorated with the `SpecId` of _0_, whose value defaults to 
  _1_.
- The _y_ dimension of the work-group size is stored in a specialization
  constant that is decorated with the `SpecId` of _1_, whose value defaults to 
  _1_.
- The _z_ dimension of the work-group size is stored in a specialization
  constant that is decorated with the `SpecId` of _2_, whose value defaults to 
  _1_.

If a compilation unit contains multiple kernels, then either:
- All kernels should have a `reqd_work_group_size` attribute, or
- No kernels should have a `required_work_group_size` attribute.  In this case
  work group sizes would be set via specialization constants for the
  pipeline as described above.

### Types

#### Signed Integer Types

Signed integer types are mapped down onto their unsigned equivalents in SPIR-V
as produced from OpenCL C.

Signed integer modulus (`%`) operations, where either argument to the modulus is
a negative integer, will result in an undefined result.

### OpenCL C Built-In Functions

OpenCL C language built-in functions are mapped, where possible, onto their GLSL
4.5 built-in equivalents.
For example, the OpenCL C language built-in function `tan()` is mapped onto
GLSL's built-in function `tan()`.

#### Common Functions

The OpenCL C built-in `sign()` function does not differentiate between a signed
and unsigned 0.0 input value, nor does it return 0.0 if the input value is a
NaN.

#### Integer Functions

The OpenCL C built-in `mad24()` and `mul24()` functions do not perform their
operations using 24-bit integers. Instead, they use 32-bit integers, and thus
have no performance-improving characteristics over normal 32-bit integer
arithmetic.

#### Work-Item Functions

The OpenCL C work-item functions map to Vulkan SPIR-V as follows:

- `get_work_dim()` will **always** return _3_.
- `get_global_size()` is implemented by multiplying the result from
  `get_local_size()` by the result from `get_num_groups()`.
- `get_global_id()` is mapped to a SPIR-V variable decorated with
  `GlobalInvocationId`.
- `get_local_size()` is mapped to a SPIR-V variable decorated with
  `WorkgroupSize`.
- `get_local_id()` is mapped to a SPIR-V variable decorated with
  `LocalInvocationId`.
- `get_num_groups()` is mapped to a SPIR-V variable decorated with
  `NumWorkgroups`.
- `get_group_id()` is mapped to a SPIR-V variable decorated with
  `WorkgroupId`.
- `get_global_offset()` will **always** return _0_.

## OpenCL C Restrictions

Some OpenCL C language features that have no expressible equivalents in Vulkan's
variant of SPIR-V are restricted.

### Kernels

OpenCL C language kernels **must not** be called from other kernels.

Pointer types in the `local` address space **must not** be used as kernel
arguments.

Pointers of type `half` **must not** be used as kernel arguments.

### Types
#### Boolean

Booleans are an abstract type - they have no known compile-time size.
Using a boolean type as the argument to the `sizeof()` operator will result in
an undefined value.
The boolean type **must not** be used to form `global`, or `constant` variables,
nor be used within a struct or union type in the `global`, or `constant` address
spaces.

#### 8-Bit Types

The `char`, `char2`, `char3`, `uchar`, `uchar2`, and `uchar3` types
**must not** be used.

#### 64-Bit Types

The `double`, `double2`, `double3`, `double4`, `long`, `long2`, `long3`,
`long4`, `ulong`, `ulong2`, `ulong3`, and `ulong4` types **must not** be used.

#### Images

The `image2d_array_t`, `image1d_t`, `image1d_buffer_t`, and `image1d_array_t`
types **must not** be used.

#### Samplers

Any `sampler_t`'s **must** be passed in via a kernel argument, or the sampler
**must** be in the sampler map (see the -samplemap command line argument).

#### Events

The `event_t` type **must not** be used.

#### Pointers

Pointers are an abstract type - they have no known compile-time size.
Using a pointer type as the argument to the `sizeof()` operator will result in
an undefined value.

Pointer-to-integer casts **must not** be used.

Integer-to-pointer casts **must not** be used.

Pointers in the `local` address space **must not** be used as kernel arguments.

Pointers **must not** be compared for equality or inequality.

#### 8- and 16-Wide Vectors

Vectors of 8 and 16 elements **must not** be used.

#### Recursive Struct Types

Recursively defined struct types **must not** be used.

#### Pointer-Sized Types

Since pointers have no known compile-time size, the pointer-sized types
`size_t`, `ptrdiff_t`, `uintptr_t`, and `intptr_t` do not represent types that
are the same size as a pointer.
Instead, those types are mapped to 32-bit integer types.

### Built-In Functions

For any OpenCL C language built-in functions that are mapped onto their GLSL
4.5 built-in equivalents, the precision requirements of the OpenCL C language
built-ins are not necessarily honoured.

#### Atomic Functions

The `atomic_xchg()` built-in function that takes a floating-point argument
**must not** be used.

#### Common Functions

The `step()`, and `smoothstep()` built-in functions **must not** be used.

#### Conversions

The `convert_<type>_rte()`, `convert_<type>_rtz()`, `convert_<type>_rtp()`,
`convert_<type>_rtn()`, `convert_<type>_sat()`, `convert_<type>_sat_rte()`,
`convert_<type>_sat_rtz()`, `convert_<type>_sat_rtp()`, and
`convert_<type>_sat_rtn()` built-in functions **must not** be used.

#### Math Functions

The `acospi()`, `asinpi()`, `atanpi()`, `atan2pi()`, `cbrt()`, `copysign()`,
`cospi()`, `erf()`, `erfc()`, `expm1()`, `fdim()`, `fmod()`, `hypot()`,
`ilogb()`, `lgamma()`, `lgamma_r()`, `log1p()`, `logb()`, `maxmag()`,
`minmag()`, `nan()`, `nextafter()`, `pown()`, `remainder()`, `remquo()`,
`rint()`, `rootn()`, `sincos()`, `sinpi()`, `tanpi()`, and `tgamma()` built-in
functions **must not** be used.

#### Integer Functions

The `abs_diff()`, `add_sat()`, `hadd()`, `mad_hi()`, `mad_sat()`, `mul_hi()`,
`rhadd()`, `rotate()`, `sub_sat()` and `upsample()` built-in functions
**must not** be used.

#### Relational Functions

The `islessgreater()`, `isfinite()`, `isnormal()`, `isordered()`,
`isunordered()`, `bitselect()`, and `select()` built-in functions **must not**
be used.

#### Vector Data Load and Store Functions

The `vload<size>()`, `vstore<size>()`, `vstore_half_rtp()`, `vstore_half_rtn()`,
`vstore_half<size>_rtp()`, `vstore_half<size>_rtn()`, `vstorea_half<size>_rtp()`
, and `vstorea_half<size>_rtn()` built-in functions **must not** be used.

The `vload_half()`, `vload_half<size>()`, `vstore_half()`, `vstore_half_rte()`,
`vstore_half_rtz()`, `vstore_half<size>()`, `vstore_half<size>_rte()`,
`vstore_half<size>_rtz()`, `vloada_half<size>()`, `vstorea_half<size>()`,
`vstorea_half<size>_rte()`, and `vstorea_half<size>_rtz()` built-in functions
are only allowed to use the `global` and `constant` address spaces.

The `vstore_half_rte()`, `vstore_half_rtz()`, `vstore_half<size>_rte()`,
`vstore_half<size>_rtz()`, `vstorea_half<size>_rte()`, and
`vstorea_half<size>_rtz()` built-in functions are not guaranteed to round the
result correctly if the destination address was not declared as a half* on the
kernel entry point.

#### Async Copy and Prefetch Functions

The `async_work_group_copy()`, `async_work_group_strided_copy()`,
`wait_group_events()`, and `prefetch()` built-in functions **must not** be used.

#### Miscellaneous Vector Functions

The `shuffle()` and `shuffle2()` built-in functions **must not** be used.

#### Printf

The `printf()` built-in function **must not** be used.

#### Image Read and Write Functions

The `get_image_channel_data_type()`, `get_image_channel_order()`,
`read_imagei()`, `read_imageui()`, `write_imagei()` and `write_imageui()`
built-in functions **must not** be used.

The versions of the `read_imagef()` built-in functions that use integer vector
types to specify which coordinate to sample **must not** be used.
