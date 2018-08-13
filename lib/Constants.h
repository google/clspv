// Copyright 2018 The Clspv Authors. All rights reserved.
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

#ifndef CLSPV_LIB_CONSTANTS_H_
#define CLSPV_LIB_CONSTANTS_H_

namespace clspv {

// Name for module level metadata storing workgroup argument spec ids.
inline std::string LocalSpecIdMetadataName() { return "clspv.local_spec_ids"; }

// Base name for workgroup variable accessor function.
inline std::string WorkgroupAccessorFunction() { return "clspv.local.var."; }

// Base name for resource variable accessor function.
inline std::string ResourceAccessorFunction() { return "clspv.resource.var."; }

// The first useable SpecId for pointer-to-local arguments.
// 0, 1 and 2 are reserved for workgroup size.
inline int FirstLocalSpecId() { return 3; }

} // namespace clspv

#endif
