"""Build and publish Kuradi Saased to its existing itch.io HTML5 channel.

Adapted from CoolorBurn's publish_itch.py / Revalia's batch publishing workflow.
Uses Python's standard library; no pip dependencies are required.
"""

import argparse
import getpass
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


ITCH_TARGET = 'lienthealien/kuradi-saased:HTML5'


def read_version(path):
    match = re.search(r'^version:\s*([^\r\n#]+)',
                      path.read_text(encoding='utf-8-sig'), re.MULTILINE)
    if not match:
        raise ValueError('No version found in pubspec.yaml.')
    return match.group(1).strip().strip('\'"')


def prepare_index(path):
    content = path.read_text(encoding='utf-8-sig')
    content, count = re.subn(r'<base\b[^>]*>', '<base href="./">', content,
                             flags=re.IGNORECASE)
    if count != 1:
        raise ValueError('Expected one <base> tag in build/web/index.html.')
    path.write_text(content, encoding='utf-8')


def publish(project_dir, token=None, *, build_only=False):
    project_dir = Path(project_dir).resolve()
    butler = project_dir / 'butler.exe'
    if not build_only and not butler.is_file():
        raise FileNotFoundError('butler.exe was not found in the project directory.')
    flutter = shutil.which('flutter.bat') or shutil.which('flutter')
    if not flutter:
        raise FileNotFoundError('Flutter was not found on PATH.')
    version = read_version(project_dir / 'pubspec.yaml')
    print(f'Building web release {version} for {ITCH_TARGET}...', flush=True)
    build_env = os.environ.copy()
    build_env.pop('ITCH_API_KEY', None)
    build_env.pop('BUTLER_API_KEY', None)
    subprocess.run([flutter, 'build', 'web', '--release',
                    '--no-wasm-dry-run'], cwd=project_dir, env=build_env, check=True)
    web_dir = project_dir / 'build' / 'web'
    prepare_index(web_dir / 'index.html')

    if build_only:
        print(f'Build ready in {web_dir}. Nothing was uploaded.', flush=True)
        return

    token = (token or os.environ.get('ITCH_API_KEY') or
             os.environ.get('BUTLER_API_KEY') or
             getpass.getpass('itch.io API token (hidden): ')).strip()
    if not token:
        raise ValueError('No itch.io API token supplied. Nothing was uploaded.')
    upload_env = os.environ.copy()
    upload_env.pop('ITCH_API_KEY', None)
    upload_env['BUTLER_API_KEY'] = token
    print(f'Publishing to {ITCH_TARGET}...', flush=True)
    subprocess.run([str(butler), 'push', str(web_dir), ITCH_TARGET,
                    '--userversion', version], cwd=project_dir,
                   env=upload_env, check=True)
    print('Publish completed successfully.', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('token', nargs='?',
                        help='Optional itch.io API token; otherwise prompted with hidden input.')
    parser.add_argument('--build-only', action='store_true',
                        help='Build and prepare the release without requesting a token or uploading.')
    args = parser.parse_args()
    try:
        publish(Path(__file__).resolve().parent, args.token, build_only=args.build_only)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f'ERROR: {error}', file=sys.stderr)
        return 1
    except (KeyboardInterrupt, EOFError):
        print('\nPublishing cancelled.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
