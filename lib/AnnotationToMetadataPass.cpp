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
      SmallPtrSet<GlobalValue *, 4> to_erase;
      // TODO: #816 remove after final transition.
      SmallPtrSet<Constant *, 4> constants_to_erase;

      ConstantArray *annotations_array =
          dyn_cast<ConstantArray>(GV.getOperand(0));
      for (auto &annotation_entry : annotations_array->operands()) {
        ConstantStruct *annotation_struct =
            dyn_cast<ConstantStruct>(annotation_entry.get());

        auto op0 = annotation_struct->getOperand(0);
        Function *entry_point = dyn_cast<Function>(
            op0->getType()->isOpaquePointerTy() ? op0 : op0->getOperand(0));

        auto op1 = annotation_struct->getOperand(1);
        GlobalVariable *annotation_gv = dyn_cast<GlobalVariable>(
            op1->getType()->isOpaquePointerTy() ? op1 : op1->getOperand(0));
        StringRef annotation =
            dyn_cast<ConstantDataArray>(annotation_gv->getInitializer())
                ->getAsCString();

        const auto entry_point_name_md =
            MDString::get(context, entry_point->getName());
        const auto attrs_md = MDString::get(context, annotation);
        llvm::errs() << entry_point->getName() << ": '" << annotation << "'\n";

        MDTuple *entry =
            MDTuple::get(M.getContext(), {entry_point_name_md, attrs_md});
        md_node->addOperand(entry);

        // clean up annotations so other passes don't try to use the value
        to_erase.insert(annotation_gv);
        // this isn't used so also clean up
        auto op2 = annotation_struct->getOperand(2);
        GlobalVariable *filename_gv = dyn_cast<GlobalVariable>(
            op2->getType()->isOpaquePointerTy() ? op2 : op2->getOperand(0));
        to_erase.insert(filename_gv);

        // this constant stays after the global is erased, so kill it
        // TODO: #816 remove after final transition.
        if (!op1->getType()->isOpaquePointerTy())
          constants_to_erase.insert(op0);
      }

      GV.eraseFromParent();
      for (auto gv : to_erase) {
        gv->eraseFromParent();
      }
      for (auto constant : constants_to_erase) {
        constant->destroyConstant();
      }
      break;
    }
  }
  return PreservedAnalyses::none();
}
