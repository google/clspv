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
#include "llvm/IR/Operator.h"

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
      SmallPtrSet<GlobalValue *, 4> to_erase;
      SmallPtrSet<Constant *, 4> addrspacecast_to_erase;

      ConstantArray *annotations_array =
          dyn_cast<ConstantArray>(GV.getOperand(0));
      for (auto &annotation_entry : annotations_array->operands()) {
        ConstantStruct *annotation_struct =
            dyn_cast<ConstantStruct>(annotation_entry.get());

        auto op0 = annotation_struct->getOperand(0);
        if (isa<AddrSpaceCastOperator>(op0)) {
          // We need to make sure to erase those to avoid keeping a reference on
          // functions preventing them from being removed
          addrspacecast_to_erase.insert(op0);
        }
        Function *entry_point = dyn_cast<Function>(op0->stripPointerCasts());

        auto op1 = annotation_struct->getOperand(1);
        GlobalVariable *annotation_gv = dyn_cast<GlobalVariable>(op1);
        StringRef annotation =
            dyn_cast<ConstantDataArray>(annotation_gv->getInitializer())
                ->getAsCString();

        const auto entry_point_name_md =
            MDString::get(context, entry_point->getName());
        const auto attrs_md = MDString::get(context, annotation);

        MDTuple *entry =
            MDTuple::get(M.getContext(), {entry_point_name_md, attrs_md});
        md_node->addOperand(entry);

        // clean up annotations so other passes don't try to use the value
        to_erase.insert(annotation_gv);
        // this isn't used so also clean up
        auto op2 = annotation_struct->getOperand(2);
        GlobalVariable *filename_gv = dyn_cast<GlobalVariable>(op2);
        to_erase.insert(filename_gv);
      }

      GV.eraseFromParent();
      for (auto gv : to_erase) {
        gv->eraseFromParent();
      }
      for (auto as : addrspacecast_to_erase) {
        as->destroyConstant();
      }
      break;
    }
  }
  return PreservedAnalyses::none();
}
