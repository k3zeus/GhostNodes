"""Disposable, sequential Linux installation tests. No host Docker socket mounts.

Default invocation checks prerequisites only; --run creates privileged containers.
Use only a local Docker daemon dedicated to development, never production.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
TEST_ROOT = Path(os.environ.get('CODEX_TEST_ROOT', 'E:/Codex_Tests' if os.name == 'nt' else str(ROOT / 'tests/evidence')))
GIB = 1024 ** 3
SUITES = [
    ['test_install_behavior.py', 'test_wifi_behavior.py'],
    ['test_real_stages.py'],
    ['test_tui.py'],
    ['test_bitcoin_runtime.py'],
    ['test_web_runtime.py'],
]


def source_paths(root):
    result = subprocess.run(
        ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
        cwd=root, check=True, stdout=subprocess.PIPE)
    for name in sorted(set(result.stdout.decode('utf-8').split('\0')) - {''}):
        path = root / name
        parts = Path(name).parts
        if path.is_symlink() or not path.is_file():
            continue
        if not path.resolve().is_relative_to(root.resolve()):
            raise RuntimeError(f'Source escapes workspace: {name}')
        if any(p in {'node_modules', '.venv', '__pycache__', '.pytest_cache',
                     'evidence', 'data', 'logs', '.git'} for p in parts):
            continue
        if path.name == '.env' or (path.name.startswith('.env.') and path.name != '.env.example'):
            continue
        if (path.suffix in {'.env', '.db', '.sqlite', '.log', '.state', '.key'}
                and name != 'var/globals.env') or 'pass' in path.name.lower():
            continue
        yield name


def check_space(paths, minimum_gib):
    for path in set(map(str, paths)):
        free = shutil.disk_usage(path).free
        if free < minimum_gib * GIB:
            raise RuntimeError(f'{path}: {free / GIB:.2f} GiB free; '
                               f'at least {minimum_gib} GiB required. No cleanup of unrelated data.')


def snapshot(root, target):
    with tarfile.open(target, 'w') as archive:
        for name in source_paths(root):
            archive.add(root / name, arcname=name, recursive=False)


def check_local_daemon():
    if os.environ.get('DOCKER_HOST'):
        raise RuntimeError('Unset DOCKER_HOST and select a local Docker context explicitly.')
    context = subprocess.run(['docker', 'context', 'inspect'], check=True,
                             capture_output=True, text=True, timeout=20)
    endpoint = json.loads(context.stdout)[0]['Endpoints']['docker']['Host']
    if not endpoint.startswith(('npipe://', 'unix://')):
        raise RuntimeError('Refusing non-local Docker endpoint: ' + endpoint)
    info = subprocess.run(['docker', 'info', '--format', '{{.OSType}}'], check=True,
                          capture_output=True, text=True, timeout=20)
    if info.stdout.strip() != 'linux':
        raise RuntimeError('A Linux Docker daemon is required.')


def run_logged(command, logfile, disks, minimum_gib, timeout=1800):
    check_space(disks, minimum_gib)
    with logfile.open('wb') as output:
        proc = subprocess.Popen(command, stdout=output, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + timeout
        try:
            while proc.poll() is None:
                if time.monotonic() > deadline:
                    raise TimeoutError('Timed out: ' + ' '.join(command[:4]))
                check_space(disks, minimum_gib)
                time.sleep(2)
            if proc.returncode:
                raise RuntimeError(f'Exit {proc.returncode}; see {logfile}')
        finally:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=10)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true')
    parser.add_argument('--distro', choices=['debian12', 'ubuntu24', 'all'], default='all')
    parser.add_argument('--output', type=Path, default=TEST_ROOT / 'GhostNodes/evidence')
    parser.add_argument('--min-free-gib', type=int, default=30)
    parser.add_argument('--docker-storage', type=Path,
                        help='Filesystem hosting Docker data; required on Linux')
    args = parser.parse_args(argv)
    if args.min_free_gib < 15:
        parser.error('--min-free-gib must be at least 15')
    storage = args.docker_storage
    if storage is None:
        if os.name != 'nt':
            parser.error('--docker-storage must identify the actual Docker data filesystem')
        storage = Path(os.environ.get('SystemDrive', 'C:') + '/')
    # Check before creating archives, images or containers.
    output_disk = args.output.resolve()
    while not output_disk.exists():
        output_disk = output_disk.parent
    disks = [output_disk, storage]
    if os.name == 'nt':
        check_space([Path(os.environ.get('SystemDrive', 'C:') + '/')], 5)
    check_space(disks, args.min_free_gib)
    check_local_daemon()
    if not args.run:
        print('Preflight passed. Add --run to execute privileged disposable Linux tests.')
        return 0

    run_id = uuid.uuid4().hex[:12]
    output = args.output.resolve() / run_id
    output.mkdir(parents=True)
    disks.append(output)
    check_space(disks, args.min_free_gib)
    source = output / 'source.tar'
    snapshot(ROOT, source)
    # A minimal build context avoids sending ignored databases/venvs to Docker.
    context = output / 'context'
    for name in ['Dockerfile.install', 'docker-daemon.json']:
        dest = context / 'tests/e2e' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / 'tests/e2e' / name, dest)
    results = []
    bases = {'debian12': 'debian:bookworm', 'ubuntu24': 'ubuntu:24.04'}
    for distro, base in bases.items():
        if args.distro not in ('all', distro):
            continue
        name = f'gn-tdd-{run_id}-{distro}'
        image = f'ghostnodes-tdd:{run_id}-{distro}'
        result = {'distro': distro, 'container': name, 'image': image, 'status': 'failed'}
        def execute(command, label, timeout=1800):
            run_logged(command, output / f'{distro}-{label}.log', disks,
                       args.min_free_gib, timeout)
        try:
            execute(['docker', 'build', '--build-arg', f'BASE={base}',
                     '--label', f'ghostnodes.tdd={run_id}', '-t', image,
                     '-f', str(context / 'tests/e2e/Dockerfile.install'), str(context)], 'build')
            execute(['docker', 'run', '-d', '--name', name,
                     '--label', f'ghostnodes.tdd={run_id}', '--privileged',
                     '--cgroupns=private', '--tmpfs', '/run', '--tmpfs', '/run/lock',
                     '--memory', '3g', '--cpus', '2',
                     '-e', 'GN_TDD_DISPOSABLE=1', '-e', 'GN_ROOT=/work', image], 'start')
            execute(['docker', 'cp', str(source), name + ':/tmp/source.tar'], 'copy')
            execute(['docker', 'exec', name, 'bash', '-c',
                     'set -e; tar -xf /tmp/source.tar -C /work; rm /tmp/source.tar; '
                     'systemctl is-system-running --wait || true; '
                     'test -d /run/systemd/system'], 'init', 120)
            for index, suite in enumerate(SUITES):
                execute(['docker', 'exec', name, 'python3', '-m', 'pytest', '-q',
                         f'--basetemp=/tmp/gn-pytest/suite-{index}',
                         f'--junitxml=/tmp/result-{index}.xml',
                         *['/work/tests/e2e/' + s for s in suite]], f'suite-{index}')
                execute(['docker', 'cp', name + f':/tmp/result-{index}.xml',
                         str(output / f'{distro}-{index}.xml')], f'copy-{index}')
            execute(['docker', 'exec', name, 'bash', '-c',
                     'set -e; cd /work; for t in tests/test_*.sh; do bash "$t"; done'], 'legacy')
            execute(['docker', 'exec', name, 'python3', '-B', '-m', 'unittest',
                     'discover', '-s', '/work/tests', '-p', 'test_*.py', '-v'], 'portable-units')
            result['status'] = 'passed'
        except (RuntimeError, OSError, subprocess.SubprocessError, TimeoutError) as error:
            result['error'] = str(error)
            print(f'{distro}: {error}', flush=True)
        finally:
            # Keep PTY logs even on failure. Never prune or restart shared Docker.
            for command, label in [
                (['docker', 'cp', name + ':/tmp/gn-pytest', str(output / f'{distro}-pty')], 'evidence'),
                (['docker', 'rm', '-f', name], 'cleanup-container'),
                (['docker', 'image', 'rm', image], 'cleanup-image'),
            ]:
                try:
                    with (output / f'{distro}-{label}.log').open('wb') as logfile:
                        done = subprocess.run(command, stdout=logfile, stderr=subprocess.STDOUT, timeout=30)
                    result[label] = done.returncode
                except (OSError, subprocess.SubprocessError) as error:
                    result[label] = str(error)
            results.append(result)
            (output / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
        if (result['status'] != 'passed' or result.get('cleanup-container') != 0
                or result.get('cleanup-image') != 0):
            result['status'] = 'failed'
            (output / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
            break
    source.unlink(missing_ok=True)
    print('Evidence: ' + str(output))
    return int(any(r['status'] != 'passed' for r in results))


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.SubprocessError) as exc:
        raise SystemExit(str(exc)) from exc
