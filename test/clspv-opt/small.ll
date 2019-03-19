; RUN: clspv-opt %s -O2 -S -o %t.ll
; Function Attrs: nounwind
define spir_kernel void @foo(i32 addrspace(1)* %a, i32 %b) #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 !reqd_work_group_size !7 {
entry:
  %a.addr = alloca i32 addrspace(1)*, align 4
  %b.addr = alloca i32, align 4
  %i = alloca i32, align 4
  store i32 addrspace(1)* %a, i32 addrspace(1)** %a.addr, align 4
  store i32 %b, i32* %b.addr, align 4
  store i32 0, i32* %i, align 4
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %0 = load i32, i32* %i, align 4
  %1 = load i32, i32* %b.addr, align 4
  %cmp = icmp ult i32 %0, %1
  br i1 %cmp, label %for.body, label %for.end

for.body:                                         ; preds = %for.cond
  %2 = load i32 addrspace(1)*, i32 addrspace(1)** %a.addr, align 4
  %3 = load i32, i32* %i, align 4
  %arrayidx = getelementptr inbounds i32, i32 addrspace(1)* %2, i32 %3
  %4 = load i32, i32 addrspace(1)* %arrayidx, align 4
  %inc = add i32 %4, 1
  store i32 %inc, i32 addrspace(1)* %arrayidx, align 4
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %5 = load i32, i32* %i, align 4
  %inc1 = add i32 %5, 1
  store i32 %inc1, i32* %i, align 4
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 6.0.0 (https://github.com/llvm-mirror/clang 82fcdc620f7367f0ffc24b8ade93539e0bfd9e30) (https://github.com/llvm-mirror/llvm 82f73ee5b37a2a4cc1bdad02bebaaaba71b65400)"}
!3 = !{i32 1, i32 0}
!4 = !{!"none", !"none"}
!5 = !{!"uint*", !"uint"}
!6 = !{!"", !""}
!7 = !{i32 1, i32 1, i32 1}
