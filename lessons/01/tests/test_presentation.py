"""Exercise the real lesson scripts with simulated nodes, never a live lab."""
import errno
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import subprocess
import tempfile
import time
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'scripts'
LOAD = 'source ' + shlex.quote(str(SCRIPTS / 'lib.sh')) + '\n'
FAKE = r'''
sleep() { :; }
_run() {
  printf '%s\n' "$2" | bash -n || return $?
  printf '%s\n' "$2" >> "$COMMANDS"
  case "$2" in
    'ip route get 10.10.0.2')
      if [ "${ROUTE_STATUS:-0}" != 0 ]; then echo 'route probe failed' >&2; return "$ROUTE_STATUS"; fi;;
  esac
  case "$2" in
    *'nmcli connection add'*)
      if [ "${FAIL_ASSIGN:-0}" = 1 ]; then echo 'assignment failed' >&2; return 17; fi;;
  esac
  case "$2" in
    *'ping -I'*) echo '2 packets transmitted, 2 received, 0% packet loss';;
    *'ping -c1'*) echo '1 packets transmitted, 0 received'; return 1;;
    *'ip -br link'*) echo 'eth0 UP LOWER_UP';;
    *'ip route get'*) echo '10.10.0.2 dev eth0 src 10.10.0.1';;
    *'ip neigh show'*) echo '10.10.0.2 lladdr b8:27:eb:00:00:02 REACHABLE';;
  esac
}
read_node_a() {
  printf '%s\n' "$1" >> "$COMMANDS"
  if [ "${DECODE_FAIL:-0}" = 1 ]; then echo 'bad capture' >&2; return 23; fi
  for i in $(seq 1 10); do printf '%s  0.001  raw packet\n' "$i"; done
}
'''


class Presentation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, MODE='ssh', TERM='xterm-256color',
                        LESSON_OUTPUT_DIR=str(self.root / 'output'),
                        COMMANDS=str(self.root / 'commands'))
        for key in ('NO_COLOR', 'LESSON_AUTO', 'LESSON_RUNNER', 'LESSON_RUN_INDEX'):
            self.env.pop(key, None)

    def shell(self, script, **env):
        return subprocess.run(['bash', '-c', LOAD + FAKE + script],
                              capture_output=True, text=True,
                              env=dict(self.env, **env))

    def terminal(self, script, **env):
        master, slave = pty.openpty()
        proc = subprocess.Popen(['bash', '-c', LOAD + FAKE + script],
                                env=dict(self.env, **env), stdin=slave,
                                stdout=slave, stderr=slave)
        os.close(slave)
        output = b''
        checkpoints = []
        deadline = time.monotonic() + 8
        try:
            while time.monotonic() < deadline:
                if not select.select([master], [], [], 0.1)[0]:
                    continue
                try:
                    chunk = os.read(master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                output += chunk
                if output.count(b'[press Enter]') > len(checkpoints):
                    checkpoints.append(output.decode(errors='replace'))
                    os.write(master, b'\n')
            else:
                self.fail('Terminal script did not finish')
            self.assertEqual(proc.wait(timeout=1), 0, output.decode(errors='replace'))
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            os.close(master)
        return output.decode(errors='replace'), checkpoints

    def fixture(self):
        scripts = self.root / 'scripts'
        scripts.mkdir()
        for path in SCRIPTS.glob('0*.sh'):
            shutil.copy2(path, scripts / path.name)
        shutil.copy2(SCRIPTS / 'run.sh', scripts / 'run.sh')
        (scripts / 'lib.sh').write_text(LOAD + FAKE + '\nSCRIPTS=' + shlex.quote(str(scripts)) + '\n')
        vm = scripts / 'virtual-vm'
        vm.mkdir()
        for name in ('lab-up', 'lab-down', 'link'):
            path = vm / f'{name}.sh'
            path.write_text(f'#!/usr/bin/env bash\necho "{name} $*" >> "$COMMANDS"\n')
            path.chmod(0o755)
        return scripts

    def test_palette_and_plain_output(self):
        script = '''
begin '01 — First phase' 'Explanation'
eye <<'EOF'
Interpretation
EOF
pause 'What changed?'
node a 'ip -br link show eth0'
'''
        output, _ = self.terminal(script, LESSON_AUTO='1')
        for expected in ('\x1b[35m', '\x1b[36m',
                         '\x1b[38;2;255;255;255mExplanation\x1b[0m',
                         '\x1b[38;2;255;255;255mInterpretation\x1b[0m',
                         '\x1b[93mWhat changed?\x1b[0m',
                         '\x1b[90meth0 UP LOWER_UP\r\n\x1b[0m'):
            self.assertIn(expected, output)
        self.assertNotIn('\x1b', self.shell(script).stdout)
        plain, _ = self.terminal(script, NO_COLOR='1', LESSON_AUTO='1')
        self.assertNotIn('\x1b', plain)

    def test_review_holds_answer_then_holds_next_phase(self):
        script = '''
begin '01 — First phase' 'Introduction'
finish 'What changed?' 'REVEALED_ANSWER' 'Next: example.sh'
echo NEXT_PHASE
'''
        output, checkpoints = self.terminal(script)
        self.assertEqual(len(checkpoints), 2)
        self.assertNotIn('REVEALED_ANSWER', checkpoints[0])
        self.assertIn('REVEALED_ANSWER', checkpoints[1])
        self.assertNotIn('NEXT_PHASE', checkpoints[1])
        self.assertLess(output.index('Phase 01 complete.'), output.index('NEXT_PHASE'))

    def test_capture_pages_preserve_rows_and_decode_failure(self):
        output, checkpoints = self.terminal("capture_show /tmp/test.pcap arp")
        self.assertEqual(len(checkpoints), 1)
        self.assertIn('8  0.001  raw packet', checkpoints[0])
        self.assertNotIn('9  0.001  raw packet', checkpoints[0])
        self.assertIn('10  0.001  raw packet', output)
        saved = next((self.root / 'output').glob('*-arp.txt')).read_text()
        self.assertEqual(saved, ''.join(f'{i}  0.001  raw packet\n' for i in range(1, 11)))
        self.assertNotIn('--color', (self.root / 'commands').read_text())
        result = self.shell('capture_show /tmp/bad.pcap arp', DECODE_FAIL='1')
        self.assertEqual(result.returncode, 23)
        self.assertIn('bad capture', result.stderr)
        self.assertNotIn('No packets matched', result.stdout)

    def test_full_runner_order_and_stops_on_failure(self):
        scripts = self.fixture()
        result = subprocess.run(['bash', str(scripts / 'run.sh')], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for i in range(1, 6):
            self.assertIn(f'Phase {i:02d} complete.', result.stdout)
        self.assertNotIn('Next: ./scripts/', result.stdout)
        self.assertIn('Continue with lesson 02', result.stdout)
        commands = (self.root / 'commands').read_text()
        self.assertIn('chmod a+r', commands)
        self.assertIn('trap ', commands)  # Recorder cleanup survives a failed ping.
        index = next((self.root / 'output').glob('run-*.txt')).read_text()
        self.assertIn('link-up.pcap', index)
        self.assertIn('arp.pcap', index)
        failed = subprocess.run(['bash', str(scripts / 'run.sh')],
                                env=dict(self.env, FAIL_ASSIGN='1'),
                                capture_output=True, text=True)
        self.assertEqual(failed.returncode, 17, failed.stderr)
        self.assertIn('assignment failed', failed.stderr)
        self.assertNotIn('Phase 04 complete.', failed.stdout)
        self.assertNotIn('05 —', failed.stdout)

    def test_vm_auto_lifecycle_without_terminal_pauses(self):
        scripts = self.fixture()
        output, checkpoints = self.terminal(
            'run_script ' + shlex.quote(str(scripts / 'run.sh')) + ' --vm --auto')
        self.assertEqual(checkpoints, [])
        self.assertIn('Phase 05 complete.', output)
        commands = (self.root / 'commands').read_text().splitlines()
        self.assertEqual(commands[0], 'lab-down ')
        self.assertEqual(commands[1], 'lab-up ')
        self.assertEqual(commands[-1], 'lab-down ')
        self.assertIn('link a off', commands)
        self.assertIn('link a on', commands)

    def test_expected_unreachable_route_does_not_hide_transport_failure(self):
        scripts = self.fixture()
        script = 'run_script ' + shlex.quote(str(scripts / '03-no-address.sh'))
        unreachable = self.shell(script, MODE='netns', ROUTE_STATUS='2')
        self.assertEqual(unreachable.returncode, 0, unreachable.stderr)
        self.assertIn('Phase 03 complete.', unreachable.stdout)
        failed = self.shell(script, ROUTE_STATUS='255')
        self.assertEqual(failed.returncode, 255)
        self.assertNotIn('Phase 03 complete.', failed.stdout)

    def test_hardware_handoffs_and_namespace_explanation(self):
        scripts = self.fixture()
        script = 'run_script ' + shlex.quote(str(scripts / '01-link.sh'))
        output, checkpoints = self.terminal(script)
        self.assertIn('Unplug the cable', checkpoints[0])
        self.assertNotIn('eth0 UP LOWER_UP', checkpoints[0])
        self.assertIn('Seat the cable on both ends', checkpoints[1])
        self.assertIn('Which fields changed?', checkpoints[2])
        self.assertNotIn('what just happened', checkpoints[2])
        ns = self.shell(script, MODE='netns')
        self.assertEqual(ns.returncode, 0, ns.stderr)
        self.assertIn('namespace lab has no cable control', ns.stdout)
        self.assertIn('Phase 01 complete.', ns.stdout)
        auto = subprocess.run(['bash', str(scripts / 'run.sh'), '--auto'],
                              env=self.env, capture_output=True, text=True)
        self.assertEqual(auto.returncode, 2)
        self.assertIn('hardware needs cable handoffs', auto.stderr)

    def test_arp_reading_guide_and_interpretation_bracket_evidence(self):
        scripts = self.fixture()
        script = 'run_script ' + shlex.quote(str(scripts / '05-arp.sh'))
        output, checkpoints = self.terminal(script)
        self.assertLess(output.index('Look for “Who has'), output.index('1  0.001'))
        inspect = next(c for c in checkpoints if 'Does seq=2 need another lookup?' in c)
        self.assertIn('10  0.001  raw packet', inspect)
        self.assertNotIn('what just happened', inspect)
        self.assertIn('what just happened', output)


if __name__ == '__main__':
    unittest.main()
