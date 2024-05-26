; RUN: clspv-opt %s -o %t.ll --passes=lower-addrspacecast
; RUN: FileCheck %s < %t.ll

; CHECK: arrayinit.body:
; CHECK-NEXT: {{.*}} = phi ptr [ %{{.*}}, %arrayinit.body ], [ %{{.*}}, %entry ]
; CHECK-NOT: %arrayinit.cur = phi ptr addrspace(4) [ %arrayinit.next, %arrayinit.body ], [ %arrayinit.begin, %entry ]

define dso_local spir_kernel void @fun() {
entry:
  %mem = alloca [4 x float]
  %data = addrspacecast ptr %mem to ptr addrspace(4)
  %arrayinit.begin = getelementptr inbounds [4 x float], ptr addrspace(4) %data, i32 0, i32 0
  %arrayinit.end = getelementptr inbounds float, ptr addrspace(4) %arrayinit.begin, i32 4
  br label %arrayinit.body

arrayinit.body:
  %arrayinit.cur = phi ptr addrspace(4) [ %arrayinit.next, %arrayinit.body ], [ %arrayinit.begin, %entry ]
  %arrayinit.next = getelementptr inbounds float, ptr addrspace(4) %arrayinit.cur, i32 1
  %arrayinit.done = icmp eq ptr addrspace(4) %arrayinit.next, %arrayinit.end
  br i1 %arrayinit.done, label %arrayinit.end2, label %arrayinit.body

arrayinit.end2:
  ret void
}
