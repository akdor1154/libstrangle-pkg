#!/usr/bin/env python3

import subprocess
import functools
import contextlib
import os
import sys
import textwrap

run = functools.partial(subprocess.run, check=True, encoding='utf-8')
eprint = functools.partial(print, file=sys.stderr)

@contextlib.contextmanager
def cd(dir: str):
    currentDir = os.getcwd()
    os.chdir(dir)
    try:
        yield
    finally:
        os.chdir(currentDir)

def main():

    run(['git', 'checkout', 'main'])
    run(['git', 'submodule', 'update', '--checkout'])

    with cd('./package/libstrangle'):
        
        tags = run(['git', 'tag', '-l', '--sort=-creatordate', '--contains=HEAD'], capture_output=True).stdout.strip().splitlines()

        tags = [t.strip() for t in tags]
        if len(tags) == 0:
            eprint('No new tags')
            exit(0)
            
        tag_next = tags[0]

        eprint(f'Found new tag: {tag_next}')

        BRANCH_NAME=f'update-libstrangle-{tag_next}'

        with cd('../'):
            update_libstrangle(tag_next, BRANCH_NAME)
            raise_pr(BRANCH_NAME)
        
        eprint('raised PR to update gamescope')
        exit(42)

def assert_in_root_repo():
    remotes = run(['git', 'remote', '-v'], capture_output=True).stdout.strip()
    if 'akdor1154/libstrangle-pkg' not in remotes:
        eprint(f'remotes output:\n{remotes}')
        raise Exception('not in libstrangle-pkg repo, aborting.')

def update_libstrangle(tag: str, branch_name: str):
    assert_in_root_repo()
    run(['git', 'checkout', '-B', branch_name])
    with cd('./package/libstrangle'):
        run(['git', 'checkout', tag])
    with open('./versions.mk', 'wt') as version_file:
        version_file.write(textwrap.dedent(f'''\
            MY_VERSION := 1
        '''))
    MSG = f'Bump libstrangle to new tag {tag}'
    CHANGELOG_FILE = 'package/debian/changelog'
    run(['dch', '-v', f'{tag}-1', '-c', CHANGELOG_FILE, '-b', MSG], env={**os.environ, 'EMAIL':'akdor1154@noreply.users.github.com'})
    run(['git', 'add', 'package/libstrangle', 'versions.mk', CHANGELOG_FILE])
    run(['git', 'commit', '-m', MSG, '--', 'package/libstrangle', 'versions.mk', CHANGELOG_FILE])

def raise_pr(branch_name: str):
    try:
        run(['git', 'push', '-u', 'origin', f'{branch_name}:{branch_name}'])
    except subprocess.CalledProcessError as e:
        if e.returncode != 1:
            raise
        if e.stdout: eprint(e.stdout)
        if e.stderr: eprint(e.stderr)
        eprint('Git push failed, is there already a PR/branch for this update?')
        exit(43)
    run(['gh', 'pr', 'create', '--fill', '--assignee', 'akdor1154'])

if __name__ == '__main__':
    main()
# get current tag

# list tags

# get first tag after current tag

