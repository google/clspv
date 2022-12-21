// Copyright 2022 The Clspv Authors. All rights reserved.
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

#include "llvm/IR/Constants.h"

#include "AnnotationToMetadataPass.h"
#include "Constants.h"

using namespace llvm;

PreservedAnalyses
clspv::AnnotationToMetadataPass::run(Module &M, ModuleAnalysisManager &) {
  for (auto &GV : M.globals()) {
    if (GV.getName() == "llvm.global.annotations") {
      // metadata node to write to
      auto &context = M.getContext();
      NamedMDNode *md_node =
          M.getOrInsertNamedMetadata(clspv::EntryPointAttributesMetadataName());

      // list of processed strings to delete at the end
      SmallVector<GlobalVariable *, 4> to_erase;

      ConstantArray *annotations_array =
          dyn_cast<ConstantArray>(GV.getOperand(0));
      for (auto &annotation_entry : annotations_array->operands()) {
        ConstantStruct *annotation_struct =
            dyn_cast<ConstantStruct>(annotation_entry.get());

        Function *entry_point =
            dyn_cast<Function>(annotation_struct->getOperand(0)->getOperand(0));

        GlobalVariable *annotation_gv = dyn_cast<GlobalVariable>(
            annotation_struct->getOperand(1)->getOperand(0));
        StringRef annotation =
            dyn_cast<ConstantDataArray>(annotation_gv->getInitializer())
                ->getAsCString();

        const auto entry_point_name_md =
            MDString::get(context, entry_point->getName());
        const auto attrs_md = MDString::get(context, annotation);

        MDTuple *entry =
            MDTuple::get(M.getContext(), {entry_point_name_md, attrs_md});
        md_node->addOperand(entry);

        // clean up annotations
        to_erase.push_back(annotation_gv);
        // this isn't used so also clean up
        GlobalVariable *filename_gv = dyn_cast<GlobalVariable>(
            annotation_struct->getOperand(2)->getOperand(0));
        // TODO I think this might segfault for multiple entrypoints
        to_erase.push_back(filename_gv);
      }

      // TODO this might make all the looking for "llvm.metadata" redundant
      GV.eraseFromParent();
      for (auto gv : to_erase) {
        gv->eraseFromParent();
      }
      break;
    }
  }

  return PreservedAnalyses{};
}
