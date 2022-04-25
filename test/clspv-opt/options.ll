; This tests that all the clspv options work with clspv-opt.  It does not
; check any specific transformation.  It just makes sure that the options
; are accepted.

; RUN: clspv-opt %s -o %t.ll --passes=native-math,opencl-inliner,remove-unused-arguments,replace-llvm-intrinsics,replace-opencl-builtin,replace-pointer-bitcast,rewrite-inserts-pass,scalarize,share-module-scope-vars,signed-compare-fixup,simplify-pointer-bitcast,splat-arg,splat-selection-condition,specialize-image-types,strip-freeze,three-element-vector-lowering,ubo-type-transform,undo-bool,undo-byval,undo-gep-constantexpr,undo-instcombine,undo-sret,undo-translate-sampler-fold,undo-truncate-to-odd-integer,unhide-constant-loads,zero-initialize-allocas,fixup-structured-cfg,reorder-basic-blocks,verify

define spir_kernel void @foo() local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !3 !kernel_arg_type !3 !kernel_arg_base_type !3 !kernel_arg_type_qual !3 !clspv.pod_args_impl !4 {
entry:
  ret void
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!3 = !{}
!4 = !{i32 0}
