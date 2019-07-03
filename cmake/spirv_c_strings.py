#!/usr/bin/env python
# Copyright 2019 The Clspv Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os.path
import re
import sys

def helper(contents, prefix, keep_prefix, is_mask):
    suffix=""
    if is_mask == True:
        suffix = "Mask"

    output = list()
    output.append("const char* get" + prefix + "Name(const "
            + prefix + suffix + " thing) {\n")
    output.append("  switch (thing) {\n");
    process = False
    enum_match = re.compile("enum " + prefix + suffix + " {");
    for line in contents:
        if process is True:
            if re.search("};", line) is not None:
                break
            if re.search(prefix + "Max", line) is not None:
                break
            item = line
            if is_mask == False:
                item = re.sub(" = [0-9]*,", "", line)

            if is_mask == True:
                m = re.search(prefix + suffix + "([a-zA-Z0-9_]*)", item)
                if m is not None:
                    output.append("    case spv::%s%s%s: return \"%s\";\n"
                            % (prefix, suffix, m.group(1), m.group(1)))
                else:
                    m = re.search(prefix + "([a-zA-Z0-9_]*)" + suffix, item)
                    output.append("    case spv::%s%s%s: return \"%s\";\n"
                            % (prefix, m.group(1), suffix, m.group(1)))
            elif keep_prefix == True:
                m = re.search("(" + prefix + "[a-zA-Z0-9_]*)", item)
                output.append("    case spv::%s: return \"%s\";\n"
                        % (m.group(1), m.group(1)))
            else:
                m = re.search(prefix + "([a-zA-Z0-9_]*)", item)
                output.append("    case spv::%s%s: return \"%s\";\n"
                        % (prefix, m.group(1), m.group(1)))
        elif re.match(enum_match, line) is not None:
            process = True

    output.append("    default: return \"\";\n")
    output.append("  }\n")
    output.append("}\n")

    return output
    
def main():
    import argparse
    parser = argparse.ArgumentParser(description='Generate SPIR-V enums')

    parser.add_argument('--input-file', metavar='<path>',
            type=str, required=True,
            help='input SPIR-V header')
    parser.add_argument('--output-file', metavar='<path>',
            type=str, required=True,
            help='output SPIR-V header')
    parser.add_argument('--namespace', type=str,
            help='namespace for header')

    args = parser.parse_args()

    lines = list()
    with open(args.input_file, "r") as input:
        for line in input:
            if line.find("CapabilityStorageUniformBufferBlock16 = 4433") != -1:
                continue
            if line.find("CapabilityStorageUniform16 = 4434") != -1:
                continue
            if line.find("CapabilityShaderViewportIndexLayerNV = 5254") != -1:
                continue
            lines.append(line)

    content = list()
    content += helper(lines, "Op", True, False)
    content += helper(lines, "Capability", False, False)
    content += helper(lines, "AddressingModel", False, False)
    content += helper(lines, "MemoryModel", False, False)
    content += helper(lines, "ExecutionModel", False, False)
    content += helper(lines, "ExecutionMode", False, False)
    content += helper(lines, "FunctionControl", False, True)
    content += helper(lines, "StorageClass", False, False)
    content += helper(lines, "Decoration", False, False)
    content += helper(lines, "BuiltIn", False, False)
    content += helper(lines, "SelectionControl", False, True)
    content += helper(lines, "LoopControl", False, True)
    content += helper(lines, "Dim", False, False)
    content += helper(lines, "ImageFormat", False, False)
    content += helper(lines, "ImageOperands", False, True)
    content += helper(lines, "MemoryAccess", False, True)
    content += helper(lines, "SourceLanguage", False, False)

    with open(args.output_file, "w") as output:
        output.write("// Copyright 2017 The Clspv Authors. All rights reserved.\n")
        output.write("//\n")
        output.write("// Licensed under the Apache License, Version 2.0 (the \"License\");\n")
        output.write("// you may not use this file except in compliance with the License.\n")
        output.write("// You may obtain a copy of the License at\n")
        output.write("//\n")
        output.write("//     http://www.apache.org/licenses/LICENSE-2.0\n")
        output.write("//\n")
        output.write("// Unless required by applicable law or agreed to in writing, software\n")
        output.write("// distributed under the License is distributed on an \"AS IS\" BASIS,\n")
        output.write("// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n")
        output.write("// See the License for the specific language governing permissions and\n")
        output.write("// limitations under the License.\n")
        output.write("//\n")
        output.write("// THIS FILE IS AUTOGENERATED - DO NOT EDIT!\n")
        header_blocker = args.output_file
        header_blocker = header_blocker.upper()
        header_blocker = re.sub("[^A-Z]", "_", header_blocker)
        output.write("#ifndef %s\n" % header_blocker)
        output.write("#define %s\n" % header_blocker)
        output.write("namespace %s{\n" % args.namespace)
        for line in content:
            output.write(line)
        output.write("} // %s\n" % args.namespace)
        output.write("#endif //%s\n" % header_blocker)

if __name__ == '__main__':
    main()


