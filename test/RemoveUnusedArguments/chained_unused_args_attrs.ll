; RUN: clspv-opt --passes=remove-unused-arguments %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: define noundef float @leaf(ptr addrspace(1) readonly %0, float nofpclass(nan) %1) #0
; CHECK: %[[LD:[a-zA-Z0-9_.]+]] = load float, ptr addrspace(1) %0, align 4
; CHECK: %[[ADD:[a-zA-Z0-9_.]+]] = fadd float %[[LD]], %1
; CHECK: ret float %[[ADD]]

; CHECK-LABEL: define noundef float @mid(ptr addrspace(1) readonly %0, float nofpclass(nan) %1) #0
; CHECK: %[[CALL:[a-zA-Z0-9_.]+]] = call float @leaf(ptr addrspace(1) %0, float %1)
; CHECK: ret float %[[CALL]]

; CHECK: attributes #0 = { nounwind }

define noundef float @leaf(ptr noalias %unused0, ptr addrspace(1) readonly %used_ptr, i32 signext %unused1, float nofpclass(nan) %val) #0 {
entry:
  %ld = load float, ptr addrspace(1) %used_ptr, align 4
  %add = fadd float %ld, %val
  ret float %add
}

define noundef float @mid(ptr noalias %unused0, ptr addrspace(1) readonly %used_ptr, i32 signext %unused1, float nofpclass(nan) %val) #0 {
entry:
  %res = call float @leaf(ptr %unused0, ptr addrspace(1) %used_ptr, i32 %unused1, float %val)
  ret float %res
}

attributes #0 = { nounwind }
