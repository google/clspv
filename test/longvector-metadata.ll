; TODO(#816): remove opaque pointers disable
; RUN: clspv-opt --passes=long-vector-lowering %s -opaque-pointers=0
; RUN: clspv -x ir %s -o %t.spv
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @test() #0 {
entry:
  call void @llvm.experimental.noalias.scope.decl(metadata !0)
  ret void
}

; Function Attrs: inaccessiblememonly nofree nosync nounwind willreturn
declare void @llvm.experimental.noalias.scope.decl(metadata) #1

attributes #0 = { convergent norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="128" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" }
attributes #1 = { inaccessiblememonly nofree nosync nounwind willreturn }

!0 = !{!1}
!1 = distinct !{!1, !2, !"test.inner: %input"}
!2 = distinct !{!2, !"test.inner"}

