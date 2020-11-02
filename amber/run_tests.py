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

from __future__ import print_function

import argparse
import glob
import os.path
import subprocess
import sys

SWIFTSHADER_SUPPRESSIONS = [
    'images/write_image2d_r32f.amber',
    'images/write_image2d_rg32f.amber',
    'images/write_image2d_rgba32f.amber',
    'images/write_image2d_r32ui.amber',
    'images/write_image2d_rg32ui.amber',
    'images/write_image2d_rgba32ui.amber',
    'images/write_image2d_r32i.amber',
    'images/write_image2d_rg32i.amber',
    'images/write_image2d_rgba32i.amber',
    'integer/add_sat_short.amber',
    'integer/clz_long.amber',
    'integer/clz_short.amber']

def main():
  parser = argparse.ArgumentParser("Run Amber tests (without validation layers)")
  parser.add_argument('--dir', dest='test_dir', default='.',
                      help='Specify the base directory of tests')
  parser.add_argument('--amber', dest='amber',
                      help='Specify the path to the amber executable')
  parser.add_argument('--swiftshader', dest='swiftshader', action='store_true',
                      help='Only run tests compatible with Swiftshader')

  args = parser.parse_args()

  tests = glob.glob(os.path.join(args.test_dir, "**/*.amber"))
  if args.swiftshader:
    for suppress in SWIFTSHADER_SUPPRESSIONS:
      tests.remove(os.path.join(args.test_dir, suppress))
  cmd = [args.amber, '-d', '-V']
  cmd = cmd + tests
  p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
  (stdout, _) = p.communicate()
  if p.returncode != 0:
    raise RuntimeError('Failed tests \'{}\''.format(stdout.decode("utf-8")))
  print(stdout.decode("utf-8"))

  sys.exit(0)

if __name__ == '__main__':
  main()
