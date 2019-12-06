// Copyright 2019 The Clspv Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "Builtins.h"

using namespace llvm;

bool clspv::IsImageBuiltin(StringRef name) {
  return clspv::IsSampledImageRead(name) || clspv::IsImageWrite(name) ||
         clspv::IsImageQuery(name);
}

bool clspv::IsSampledImageRead(StringRef name) {
  return clspv::IsFloatSampledImageRead(name) ||
         clspv::IsUintSampledImageRead(name) ||
         clspv::IsIntSampledImageRead(name);
}

bool clspv::IsFloatSampledImageRead(StringRef name) {
  return name.startswith("_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_f") ||
         name.startswith("_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_f") ||
         name.startswith("_Z11read_imagef14ocl_image2d_ro11ocl_samplerDv2_i") ||
         name.startswith("_Z11read_imagef14ocl_image3d_ro11ocl_samplerDv4_i");
}

bool clspv::IsUintSampledImageRead(StringRef name) {
  return name.startswith(
             "_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_f") ||
         name.startswith(
             "_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_f") ||
         name.startswith(
             "_Z12read_imageui14ocl_image2d_ro11ocl_samplerDv2_i") ||
         name.startswith("_Z12read_imageui14ocl_image3d_ro11ocl_samplerDv4_i");
}

bool clspv::IsIntSampledImageRead(StringRef name) {
  return name.startswith("_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_f") ||
         name.startswith("_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_f") ||
         name.startswith("_Z11read_imagei14ocl_image2d_ro11ocl_samplerDv2_i") ||
         name.startswith("_Z11read_imagei14ocl_image3d_ro11ocl_samplerDv4_i");
}

bool clspv::IsImageWrite(StringRef name) {
  return clspv::IsFloatImageWrite(name) || clspv::IsUintImageWrite(name) ||
         clspv::IsIntImageWrite(name);
}

bool clspv::IsFloatImageWrite(StringRef name) {
  return name.startswith("_Z12write_imagef14ocl_image2d_woDv2_iDv4_f") ||
         name.startswith("_Z12write_imagef14ocl_image3d_woDv4_iDv4_f");
}

bool clspv::IsUintImageWrite(StringRef name) {
  return name.startswith("_Z13write_imageui14ocl_image2d_woDv2_iDv4_j") ||
         name.startswith("_Z13write_imageui14ocl_image3d_woDv4_iDv4_j");
}

bool clspv::IsIntImageWrite(StringRef name) {
  // Odd mangling for 3d writes.
  return name.startswith("_Z12write_imagei14ocl_image2d_woDv2_iDv4_i") ||
         name.startswith("_Z12write_imagei14ocl_image3d_woDv4_iS0_");
}

bool clspv::IsGetImageHeight(StringRef name) {
  return name.startswith("_Z16get_image_height14ocl_image2d_ro") ||
         name.startswith("_Z16get_image_height14ocl_image2d_wo") ||
         name.startswith("_Z16get_image_height14ocl_image3d_ro") ||
         name.startswith("_Z16get_image_height14ocl_image3d_wo");
}

bool clspv::IsGetImageWidth(StringRef name) {
  return name.startswith("_Z15get_image_width14ocl_image2d_ro") ||
         name.startswith("_Z15get_image_width14ocl_image2d_wo") ||
         name.startswith("_Z15get_image_width14ocl_image3d_ro") ||
         name.startswith("_Z15get_image_width14ocl_image3d_wo");
}

bool clspv::IsGetImageDepth(StringRef name) {
  return name.startswith("_Z15get_image_depth14ocl_image3d_ro") ||
         name.startswith("_Z15get_image_depth14ocl_image3d_wo");
}

bool clspv::IsGetImageDim(StringRef name) {
  return name.startswith("_Z13get_image_dim14ocl_image2d_ro") ||
         name.startswith("_Z13get_image_dim14ocl_image2d_wo") ||
         name.startswith("_Z13get_image_dim14ocl_image3d_ro") ||
         name.startswith("_Z13get_image_dim14ocl_image3d_wo");
}

bool clspv::IsImageQuery(StringRef name) {
  return clspv::IsGetImageHeight(name) || clspv::IsGetImageWidth(name) ||
         clspv::IsGetImageDepth(name);
}
