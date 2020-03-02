#!/usr/bin/env python

# Copyright 2017 The Clspv Authors. All rights reserved.
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

"""Get source files for Clspv dependencies from public repositories.
"""

from __future__ import print_function

import argparse
import errno
import json
import os
import os.path
import subprocess
import sys

# Figure out where we are and contruct a path to the root folder
THIS_DIR = os.path.dirname(os.path.abspath(__file__))
TOP_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))

# The file that tells us where to get dependency sources, and
# what git commit to use.
DEPS_FILE = os.path.join(TOP_DIR, 'deps.json')

# The name of a git remote used for getting sources for a single
# dependency.
DEPS_REMOTE = 'deps'

# Maps a site name to its hostname.
SITE_TO_HOST = { 'github' : 'github.com' }

VERBOSE = True


def mkdir_p(directory):
    """Make the directory, and all its ancestors, as required. Any of the directories
    are allowed to already exist."""
    if directory == "":
        # We're being asked to make the current directory.
        return

    try:
        os.makedirs(directory)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(directory):
            pass
        else:
            raise


def command_output(cmd, directory, fail_ok=False):
    """Runs a command in a directory and returns its standard output stream.

    Captures the standard error stream.

    Raises a RuntimeError if the command fails to launch or otherwise fails.
    """
    if VERBOSE:
        print('In {d}: {cmd}'.format(d=directory, cmd=cmd))
    p = subprocess.Popen(cmd,
                         cwd=directory,
                         stdout=subprocess.PIPE)
    (stdout, _) = p.communicate()
    if p.returncode != 0 and not fail_ok:
        raise RuntimeError('Failed to run {} in {}'.format(cmd, directory))
    if VERBOSE:
        print(stdout)
    return stdout


class GoodCommit(object):
    """Represents a good commit for a repository."""

    def __init__(self, json):
        """Initializes this good commit object.

        Args:
        'json':  A fully populated JSON object describing the commit.
        """
        self._json = json
        self.name = json['name']
        self.site = json['site']
        self.subrepo = json['subrepo']
        self.branch = json['branch']
        self.subdir = os.path.join(TOP_DIR, json['subdir']) if ('subdir' in json) else TOP_DIR
        self.commit = json['commit']

    def GetUrl(self, style='https'):
        """Returns the URL for the repository."""
        host = SITE_TO_HOST[self.site]
        sep = '/' if (style == 'https') else ':'
        return '{style}://{host}{sep}{subrepo}'.format(
                    style=style,
                    host=host,
                    sep=sep,
                    subrepo=self.subrepo)

    def AddRemote(self):
        """Add the DEPS_REMOTE remote if it does not exist."""
        if len(command_output(['git', 'remote', 'get-url', DEPS_REMOTE], self.subdir, fail_ok=True)) == 0:
            command_output(['git', 'remote', 'add', DEPS_REMOTE, self.GetUrl()], self.subdir)

    def HasCommit(self):
        """Check if the repository contains the known-good commit."""
        return 0 == subprocess.call(['git', 'rev-parse', '--verify', '--quiet',
                                     self.commit + '^{commit}'],
                                    cwd=self.subdir)

    def Clone(self):
        mkdir_p(self.subdir)
        command_output(['git', 'clone', self.GetUrl(), '.'], self.subdir)

    def Fetch(self):
        command_output(['git', 'fetch', DEPS_REMOTE, self.branch], self.subdir)

    def Checkout(self):
        if not os.path.exists(os.path.join(self.subdir,'.git')):
            self.Clone()
        self.AddRemote()
        if not self.HasCommit():
            self.Fetch()
        command_output(['git', 'checkout', self.commit], self.subdir)


def GetGoodCommits():
    """Returns the latest list of GoodCommit objects."""
    with open(DEPS_FILE) as deps:
        return [GoodCommit(c) for c in json.loads(deps.read())['commits']]


def main():

    commits = GetGoodCommits()

    all_deps = [c.name for c in commits]

    parser = argparse.ArgumentParser(description='Get sources for '
                                     ' dependencies at a specified commit')
    parser.add_argument('--dir', dest='dir', default='.',
                        help='Set target directory for dependencies source '
                        'root. Default is the current directory.')

    parser.add_argument('--deps', choices=all_deps, nargs='+', default=all_deps,
                        help='A list of dependencies to fetch sources for. '
                             'All is the default.')

    args = parser.parse_args()

    mkdir_p(args.dir)
    print('Change directory to {d}'.format(d=args.dir))
    os.chdir(args.dir)

    # Create the subdirectories in sorted order so that parent git repositories
    # are created first.
    for c in sorted(commits, key=lambda x: x.subdir):
        if c.name not in args.deps:
            continue
        print('Get {n}\n'.format(n=c.name))
        c.Checkout()
    sys.exit(0)


if __name__ == '__main__':
    main()
