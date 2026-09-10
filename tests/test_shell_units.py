"""Portable shell regressions using synthetic OS output, never host mutations."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = ('C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else shutil.which('bash'))


def function(name):
    source = (ROOT / 'halfin/tools/system.sh').read_text(encoding='utf-8')
    return re.search(r'^' + name + r'\(\) \{\n.*?^\}', source, re.M | re.S).group()


def run(code):
    return subprocess.run([BASH, '--noprofile', '--norc'], input=code, text=True,
                          capture_output=True, encoding='utf-8', timeout=15)


class SystemPanelTests(unittest.TestCase):
    def test_user_list_does_not_assign_readonly_uid_or_change_home(self):
        block = function('bloco_usuarios').replace(
            'done < /etc/passwd', 'done <<< "tester:x:1000:1000:Test:/home/tester:/bin/bash"')
        result = run('''section() { :; }; sep_thin() { :; }
who() { :; }; last() { :; }; id() { echo tester; }
HOME=/synthetic-original
''' + block + '\nbloco_usuarios\nprintf "HOME=%s\\n" "$HOME"\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('readonly variable', result.stderr)
        self.assertIn('tester', result.stdout)
        self.assertIn('HOME=/synthetic-original', result.stdout)

    def test_process_list_does_not_report_empty_after_listing(self):
        result = run('''section() { :; }; sep_thin() { :; }
ps() {
    printf '%s\\n' 'USER PID CPU MEM VSZ RSS TTY STAT START TIME COMMAND'
    printf '%s\\n' 'tester 123 1 2 0 0 ? S 00:00 0:00 ghostnode'
}
''' + function('bloco_processos') + '\nbloco_processos\n')
        self.assertIn('ghostnode', result.stdout)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Nenhum processo', result.stdout)
        self.assertEqual(result.stderr, '')


if __name__ == '__main__':
    unittest.main()
