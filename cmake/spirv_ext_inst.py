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
import json

def write_enum(grammar, output):
    output.write("enum ExtInst : unsigned int {\n")
    insts = grammar['instructions']
    for inst in insts:
        output.write("  ExtInst%s = %d,\n" % (inst['opname'], inst['opcode']))
    output.write("  ExtInstMax = 0x7fffffffu\n")
    output.write("}; // enum ExtInst\n\n")

    if not 'operand_kinds' in grammar:
        return

    enums = grammar['operand_kinds']
    for enum in enums:
        output.write("enum Ext%s : unsigned int {\n" % enum['kind'])
        for enumerant in enum["enumerants"]:
            output.write("  %s = %s,\n" % (enumerant['enumerant'], enumerant['value']))
        output.write("  %sMax = 0x7fffffffu\n" % enum['kind'])
        output.write("}; // enum Ext%s\n\n" % enum['kind'])


def write_name_func(grammar, output):
    output.write("inline const char* getExtInstName(const ExtInst thing) {\n")
    output.write("  switch(thing) {\n")
    insts = grammar['instructions']
    for inst in insts:
        name = inst['opname']
        output.write("  case ExtInst%s: return \"%s\";\n" % (name, name))
    output.write("  default: return \"\";\n")
    output.write("};\n")
    output.write("}\n")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate GLSL extended instruction header")

    parser.add_argument('--input-file', metavar='<path>',
            type=str, required=True,
            help='Input json grammar')
    parser.add_argument('--output-file', metavar='<path>',
            type=str, required=True, help='Output file')
    parser.add_argument('--namespace', metavar='<name>',
            type=str, required=True, help='Header namespace')

    args = parser.parse_args()

    with open(args.output_file, "w") as output, open(args.input_file, "r") as input:
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
        output.write("// THIS FILE IS AUTOGENERATED - DO NOT EDIT!\n")

        header_blocker = args.output_file.upper();
        header_blocker = re.sub("[^A-Z]", "_", header_blocker)
        output.write("#ifndef %s\n" % header_blocker)
        output.write("#define %s\n" % header_blocker)
        output.write("namespace clspv {\n")
        output.write("namespace %s {\n" % args.namespace)

        grammar = json.loads(input.read())
        write_enum(grammar, output)
        write_name_func(grammar, output)

        output.write("} // namespace %s\n" % args.namespace)
        output.write("} // namespace clspv\n")
        output.write("#endif//%s\n\n" % header_blocker)


if __name__ == '__main__':
    main()

