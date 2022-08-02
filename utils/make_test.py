#!/usr/bin/env python

# Copyright 2018 The Clspv Authors. All rights reserved.
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

import argparse
import collections
import os
import re
import subprocess
import tempfile

DESCRIPTION = """This script can be used to help with writing test cases for clspv.

When passed an OpenCL C source file, it will:

    1. Build a SPIR-V module using clspv
    2. Disassemble the module
    3. Post-process the disassembly to introduce FileCheck variables and CHECK directives
    4. Prepend appropriate run commands, append the source and print the final test case

When passed a SPIR-V module, only the post-processed disassembly is printed.
"""

# When one of these regular expressions matches on a disassembly line
# CHECK-DAG will be used instead of CHECK
CHECK_DAG_INSTRUCTION_REGEXES = (
    r'OpType[a-zA-Z]+',
    r'OpConstant[a-zA-Z]*',
    r'OpSpecConstant[a-zA-Z]*',
    r'OpCapability',
    r'OpUndef',
    r'OpVariable',
)

CHECK_DAG = '// CHECK-DAG:'
CHECK = '// CHECK:'

DROP_REGEXES = {
    'boilerplate': (
        r'^;',
        r'OpCapability',
        r'OpExtension',
        r'OpMemoryModel',
        r'OpEntryPoint',
        r'OpExecutionMode',
        r'OpSource',
        r'OpDecorate',
        r'OpMemberDecorate',
    ),
    'functions': (
        r'OpTypeFunction',
        r'OpFunction',
        r'OpLabel',
        r'OpReturn',
        r'OpFunctionEnd',
    ),
    'memory': (
        r'OpTypeRuntimeArray',
        r'OpTypePointer',
        r'OpVariable',
        r'OpAccessChain',
        r'OpLoad',
        r'OpStore',
    ),
}

# Keep track of the FileCheck variables we're defining
variables = set()

def substitute_backreference(regex, value):
    return regex.replace(r'\1', value)

def replace_ids_with_filecheck_variables(line):
    # regex to match IDs, (variable name pattern, variable definition pattern)
    regexp_repl = collections.OrderedDict((
        (r'%([0-9]+)', (r'__original_id_\1', r'%[[\1:[0-9]+]]')),
        (r'%([0-9a-zA-Z_]+)', (r'\1', r'%[[\1:[0-9a-zA-Z_]+]]')),
    ))
    def repl(m):
        namerex, defrex = regexp_repl[m.re.pattern]
        var_match = m.group(1)

        # Get the final FileCheck variable name
        var = substitute_backreference(namerex, var_match)

        # Do we know that variable?
        if var in variables:
            # Just use it
            return '%[[{}]]'.format(var)
        else:
            # Add it to the list of known variables and define it in the output
            variables.add(var)
            return substitute_backreference(defrex, var)

    for rr in regexp_repl.items():
        line = re.sub(rr[0], repl, line)

    return line

def process_disasm_line(args, line):

    def format_line(check, line):
        return '{:{}} {}'.format(check, len(CHECK_DAG), line.strip())

    # Drop the line?
    for drop_group in args.drop:
        for rex in DROP_REGEXES[drop_group]:
            if re.search(rex, line):
                return ''

    # First deal with IDs
    line = replace_ids_with_filecheck_variables(line)

    # Can we use CHECK-DAG?
    for rex in CHECK_DAG_INSTRUCTION_REGEXES:
        if re.search(rex, line):
            return format_line(CHECK_DAG, line)

    # Nope, use CHECK
    return format_line(CHECK, line)

def generate_run_section(args):

    clspv_options = ' '.join(args.clspv_options)

    runsec = ''
    runsec += '// RUN: clspv {} %s -o %t.spv\n'.format(clspv_options)
    runsec += '// RUN: spirv-dis -o %t2.spvasm %t.spv\n'
    runsec += '// RUN: FileCheck %s < %t2.spvasm\n'
    runsec += '// RUN: spirv-val --target-env vulkan1.0 %t.spv\n'
    runsec += '\n'

    return runsec

def disassemble_and_post_process(args, spirv_module):

    ret = ''

    # Get SPIR-V disassembly for the module
    cmd = [
        'spirv-dis',
        spirv_module
    ]

    disasm = subprocess.check_output(cmd).decode('utf-8')

    # Process the disassembly
    for line in disasm.split('\n'):
        if line.strip() == '':
            continue
        processed_line = process_disasm_line(args, line)
        if processed_line:
            ret += '{}\n'.format(processed_line)

    return ret

def generate_test_case_from_source(args):

    tc = ''

    # Start with the RUN directives
    tc += generate_run_section(args)

    # Then compile the source
    fd, spirvfile = tempfile.mkstemp()
    os.close(fd)

    cmd = [
        args.clspv,
    ] + args.clspv_options + [
        '-o', spirvfile,
        args.spirv_module_or_cl_source
    ]

    subprocess.check_call(cmd)

    # Append the processed disassembly
    tc += disassemble_and_post_process(args, spirvfile)

    # Append the original source
    tc += '\n'
    with open(args.spirv_module_or_cl_source) as f:
        tc += f.read()

    # Finally, delete the temporary SPIR-V module
    os.remove(spirvfile)

    return tc

def generate_test_case(args):

    # Determine whether we got source or SPIR-V
    _, inputext = os.path.splitext(args.spirv_module_or_cl_source)

    # Now choose the behaviour
    if inputext == '.cl':
        tc = generate_test_case_from_source(args)
    else:
        tc = disassemble_and_post_process(args, args.spirv_module_or_cl_source)

    return tc

if __name__ == '__main__':

    # Parse command line arguments
    class HelpFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
        pass

    parser = argparse.ArgumentParser(
        description=DESCRIPTION,
        formatter_class=HelpFormatter
    )

    parser.add_argument(
        '--clspv', default='clspv',
        help='clspv binary to use'
    )

    parser.add_argument(
        '--clspv-options', action='append', default=[],
        help='Pass an option to clspv when building (can be used multiple times)'
    )

    parser.add_argument(
        '--drop', action='append', default=[], choices=DROP_REGEXES.keys(),
        help='Remove specific groups of instructions from generated SPIR-V disassembly'
    )

    parser.add_argument(
        'spirv_module_or_cl_source',
        help='SPIR-V module or OpenCL C source file'
    )

    args = parser.parse_args()

    # Generate test case and print to stdout
    print(generate_test_case(args))

