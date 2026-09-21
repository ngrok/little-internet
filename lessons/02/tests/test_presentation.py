"""Presentation checks with a fake transport; never touch running lesson VMs."""
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

LIB = Path(__file__).resolve().parents[1] / 'scripts' / 'lib.sh'
# Skip QEMU discovery only. Load the actual presentation code unchanged.
LOAD = '''
source() { case "$1" in */virtual-vm/common.sh) ;; *) builtin source "$@";; esac; }
builtin source %s
node_ssh() { cat >/dev/null; printf 'transport output\\n'; return "${FAKE_STATUS:-0}"; }
''' % shlex.quote(str(LIB))


class Presentation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.env = dict(os.environ, LAB_HOME=self.temp.name, TERM='xterm-256color')
        for key in ('NO_COLOR', 'LESSON_AUTO', 'LESSON_VERBOSE',
                    'LESSON_RUNNER', 'LESSON_RUN_INDEX'):
            self.env.pop(key, None)

    def run_shell(self, script, **env):
        return subprocess.run(['bash', '-c', LOAD + script],
                              env=dict(self.env, **env), capture_output=True, text=True)

    def terminal(self, script, **env):
        master, slave = pty.openpty()
        proc = subprocess.Popen(['bash', '-c', LOAD + script],
                                env=dict(self.env, **env), stdin=slave,
                                stdout=slave, stderr=slave)
        os.close(slave)
        output = b''
        answered = 0
        deadline = time.monotonic() + 5
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
                # Supply Enter only after the script actually reaches a prompt.
                prompts = output.count(b'[press Enter]')
                if prompts > answered:
                    os.write(master, b'\n' * (prompts - answered))
                    answered = prompts
            else:
                self.fail('Terminal script did not finish within five seconds')
            self.assertEqual(proc.wait(timeout=1), 0, output.decode(errors='replace'))
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.wait()
            os.close(master)
        return output.decode(errors='replace')

    def test_setup_is_quiet_but_retains_command_and_output(self):
        result = self.run_shell("setup a 'maintenance command'")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        log = next(Path(self.temp.name).glob('transcripts/*.log')).read_text()
        self.assertIn('maintenance command', log)
        self.assertIn('transport output', log)

    def test_failure_shows_evidence_and_preserves_exit_status(self):
        result = self.run_shell("setup a 'failing command'", FAKE_STATUS='17')
        self.assertEqual(result.returncode, 17)
        self.assertIn('failing command', result.stdout)
        self.assertIn('transport output', result.stdout)
        command = self.run_shell("node a 'failing command'", FAKE_STATUS='17')
        self.assertEqual(command.returncode, 17)
        self.assertIn('transport output', command.stdout)

    def test_verbose_shows_setup(self):
        result = self.run_shell("setup a 'maintenance command'", LESSON_VERBOSE='1')
        self.assertEqual(result.returncode, 0)
        self.assertIn('maintenance command', result.stdout)
        self.assertIn('transport output', result.stdout)

    def test_color_only_for_terminal_and_respects_no_color(self):
        script = '''
phase_banner '01 — A new phase'
note 'Explanation'
eye 'Interpretation'
pause 'What do you notice?'
node a 'ip -br link show eth0'
'''
        tty = self.terminal(script, LESSON_AUTO='1')
        self.assertIn('\x1b[36m', tty)
        self.assertIn('\x1b[35m', tty)
        self.assertIn('\x1b[38;2;255;255;255mExplanation\x1b[0m', tty)
        self.assertIn('\x1b[38;2;255;255;255mInterpretation\x1b[0m', tty)
        self.assertIn('\x1b[93mWhat do you notice?\x1b[0m', tty)
        self.assertIn('\x1b[90mtransport output\r\n\x1b[0m', tty)
        for output in (self.run_shell(script).stdout,
                       self.terminal(script, NO_COLOR='1', LESSON_AUTO='1')):
            self.assertNotIn('\x1b', output)

    def test_runner_transition_keeps_paths_and_next_command_off_screen(self):
        index = str(Path(self.temp.name) / 'run.txt')
        result = self.run_shell('''
begin '01 — The first phase' 'Introduction'
CAPTURE_NAME=example
finish 'What did you notice?' 'The link carried frames.' 'Next: ./scripts/02-manual.sh'
''', LESSON_RUNNER='1', LESSON_RUN_INDEX=index)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('================================================================', result.stdout)
        self.assertIn('Phase 01 complete.', result.stdout)
        self.assertNotIn('Next:', result.stdout)
        self.assertNotIn(self.temp.name, result.stdout)
        evidence = Path(index).read_text()
        self.assertIn('example-{a,b,dhcp}.pcap', evidence)
        self.assertIn('Setup transcript:', evidence)

    def test_standalone_next_command_and_runner_final_directions_remain(self):
        script = '''
begin '07 — Final phase' 'Introduction'
finish 'What did you notice?' 'The link carried frames.' "$DIRECTIONS"
'''
        standalone = self.run_shell(script, DIRECTIONS='Next: ./scripts/02-manual.sh')
        self.assertEqual(standalone.returncode, 0, standalone.stderr)
        self.assertIn('Next: ./scripts/02-manual.sh', standalone.stdout)
        self.assertIn('Setup transcript:', standalone.stdout)
        final = self.run_shell(script, DIRECTIONS='The lab stays up. Explore.',
                               LESSON_RUNNER='1',
                               LESSON_RUN_INDEX=str(Path(self.temp.name) / 'run.txt'))
        self.assertEqual(final.returncode, 0, final.stderr)
        self.assertIn('The lab stays up. Explore.', final.stdout)

    def test_phase_answer_is_revealed_before_advancing(self):
        output = self.terminal('''
begin '06 — Preferences' 'Introduction'
finish 'Why keep the old lease?' 'The active binding is remembered.' 'Next: example.sh'
say 'NEXT_PHASE'
''')
        self.assertEqual(output.count('[press Enter]'), 2)
        first = output.index('[press Enter]')
        second = output.index('[press Enter]', first + 1)
        answer = output.index('The active binding is remembered.')
        self.assertLess(output.index('Why keep the old lease?'), first)
        self.assertLess(first, answer)
        self.assertLess(answer, second)
        self.assertLess(second, output.index('Phase 06 complete.'))
        self.assertLess(output.index('Phase 06 complete.'), output.index('NEXT_PHASE'))

    def test_dhcp_table_aligns_fields_without_changing_raw_evidence(self):
        raw = ('7|0xe666d87c|1|10.10.0.2|0.0.0.0\n'
               '13|0xe666d87c|2||10.10.0.2\n'
               '14|0xe666d87c|3|10.10.0.2|0.0.0.0\n'
               '15|0xe666d87c|5||10.10.0.2\n')
        result = self.run_shell('''
CAPTURE_NAME=preference
cable_mac() { echo b8:27:eb:02:00:02; }
node_ssh() { cat >/dev/null; printf '%s' "$FIELDS"; }
dhcp_fields b
''', FIELDS=raw)
        self.assertEqual(result.returncode, 0, result.stderr)
        saved = Path(self.temp.name) / 'captures/preference-b-fields-1.txt'
        self.assertEqual(saved.read_text(), raw)
        lines = result.stdout.splitlines()
        header = next(line for line in lines if 'Frame  Transaction' in line)
        discover = next(line for line in lines if 'Discover (1)' in line)
        offer = next(line for line in lines if 'Offer (2)' in line)
        self.assertEqual(header.index('Transaction'), discover.index('0xe666d87c'))
        self.assertEqual(header.index('Message'), discover.index('Discover (1)'))
        self.assertEqual(header.index('Requested (50)'), discover.index('10.10.0.2'))
        self.assertEqual(header.index('Requested (50)'), offer.index('-'))
        self.assertEqual(header.index('yiaddr'), offer.index('10.10.0.2'))
        self.assertIn('0.0.0.0', discover)

    def test_packet_pages_wait_and_preserve_every_row(self):
        script = '''
CAPTURE_NAME=test
node_ssh() { cat >/dev/null; for i in $(seq 1 10); do printf '%s  0.001  raw packet\\n' "$i"; done; }
packet_rows a 'decode command' packets
'''
        output = self.terminal(script)
        prompt = output.index('[press Enter]')
        self.assertLess(output.index('8  0.001  raw packet'), prompt)
        self.assertGreater(output.index('9  0.001  raw packet'), prompt)
        rows = next(Path(self.temp.name).glob('captures/*.txt')).read_text().splitlines()
        self.assertEqual(rows, [f'{i}  0.001  raw packet' for i in range(1, 11)])

    def test_empty_and_failed_decodes_are_distinct(self):
        empty = self.run_shell('''
CAPTURE_NAME=empty
node_ssh() { cat >/dev/null; }
packet_rows a 'decode command' packets
''')
        self.assertEqual(empty.returncode, 0)
        self.assertIn('No packets matched', empty.stdout)
        failed = self.run_shell('''
CAPTURE_NAME=failed
node_ssh() { cat >/dev/null; echo 'bad capture' >&2; return 1; }
packet_rows a 'decode command' packets
''')
        self.assertNotEqual(failed.returncode, 0)
        self.assertIn('bad capture', failed.stderr)
        self.assertIn('Failed:', failed.stdout)
        self.assertNotIn('No packets matched', failed.stdout)

    def reset_fixture(self):
        """Use the real reset script with a fake guest and cable transport."""
        scripts = Path(self.temp.name) / 'scripts'
        (scripts / 'virtual-vm').mkdir(parents=True)
        shutil.copy2(LIB.parent / 'reset.sh', scripts / 'reset.sh')
        (scripts / 'lib.sh').write_text(LOAD + '''
SCRIPTS="$LAB_HOME/scripts"
node_ssh() {
  cat >/dev/null
  if [ "${RESET_FAIL:-0}" = 1 ]; then echo 'reset failed' >&2; return 17; fi
  touch "$LAB_HOME/was-reset"
}
''')
        link = scripts / 'virtual-vm' / 'link.sh'
        link.write_text('#!/usr/bin/env bash\nexit 0\n')
        link.chmod(0o755)
        return '''
SCRIPTS=%s
starting_state() {
  if [ "${PROBE_FAIL:-0}" = 1 ]; then echo 'SSH failed' >&2; return 23; fi
  if [ ! -e "$LAB_HOME/was-reset" ] || [ "${STILL_DIRTY:-0}" = 1 ]; then
    echo 'pi-a: IPv4 address still assigned'
  fi
}
prepare_start
say 'PHASE_STARTED'
''' % shlex.quote(str(scripts))

    def test_used_lab_resets_with_one_enter_then_continues(self):
        output = self.terminal(self.reset_fixture(), LESSON_RUNNER='1',
                               LESSON_RUN_INDEX=str(Path(self.temp.name) / 'run.txt'))
        self.assertEqual(output.count('[press Enter]'), 1)
        self.assertIn('IPv4 address still assigned', output)
        self.assertLess(output.index('[press Enter]'), output.index('Reset complete.'))
        self.assertLess(output.index('Reset complete.'), output.index('PHASE_STARTED'))
        self.assertTrue((Path(self.temp.name) / 'was-reset').exists())

    def test_clean_lab_does_not_reset(self):
        result = self.run_shell('''
starting_state() { :; }
prepare_start
say 'PHASE_STARTED'
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('PHASE_STARTED', result.stdout)
        self.assertNotIn('[press Enter]', result.stdout)
        self.assertNotIn('Reset needed', result.stdout)

    def test_unattended_reset_requires_auto(self):
        script = self.reset_fixture()
        result = self.run_shell(script)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((Path(self.temp.name) / 'was-reset').exists())
        self.assertNotIn('PHASE_STARTED', result.stdout)
        auto = self.run_shell(script, LESSON_AUTO='1')
        self.assertEqual(auto.returncode, 0, auto.stderr)
        self.assertTrue((Path(self.temp.name) / 'was-reset').exists())
        self.assertIn('PHASE_STARTED', auto.stdout)

    def test_failed_probe_reset_or_verification_never_starts_phase(self):
        script = self.reset_fixture()
        for flag, status in [('PROBE_FAIL', 23), ('RESET_FAIL', 17), ('STILL_DIRTY', 1)]:
            with self.subTest(flag=flag):
                result = self.run_shell(script, LESSON_AUTO='1', **{flag: '1'})
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertNotIn('PHASE_STARTED', result.stdout)
        self.assertIn('Reset did not restore', result.stderr)

    def test_running_script_uses_snapshot_when_file_is_edited(self):
        script = Path(self.temp.name) / 'phase.sh'
        script.write_text('''set -e
echo PAUSED
read -r answer
printf 'ORIGINAL: %s / %s\\n' "$0" "$1"
''')
        proc = subprocess.Popen(
            ['bash', '-c', LOAD + 'run_script "$SCRIPT" "an argument"'],
            env=dict(self.env, SCRIPT=str(script)), stdin=subprocess.PIPE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.assertTrue(select.select([proc.stdout], [], [], 5)[0])
            self.assertEqual(proc.stdout.readline(), 'PAUSED\n')
            script.write_text('address\n')  # Replaces the open file, like a live edit.
            out, err = proc.communicate('\n', timeout=5)
            self.assertEqual(proc.returncode, 0, err)
            self.assertIn(f'ORIGINAL: {script} / an argument', out)
        finally:
            if proc.poll() is None:
                proc.kill()
                proc.communicate()

    def test_runner_resume_skips_reset_and_prior_phases(self):
        scripts = Path(self.temp.name) / 'scripts'
        scripts.mkdir()
        shutil.copy2(LIB.parent / 'run.sh', scripts / 'run.sh')
        (scripts / 'lib.sh').write_text(LOAD + '''
SCRIPTS="$LAB_HOME/scripts"
prepare_start() { echo reset-check >> "$EVENTS"; }
''')
        steps = ['01-switch', '02-manual', '03-server', '04-dora',
                 '05-ping', '06-preference', '07-reconnect']
        for name in ['check', *steps]:
            script = scripts / f'{name}.sh'
            script.write_text(f'#!/usr/bin/env bash\necho {name} >> "$EVENTS"\n')
            script.chmod(0o755)
        events = Path(self.temp.name) / 'events'
        env = dict(self.env, EVENTS=str(events))
        for args, expected in [(['--from', '04'], ['check', *steps[3:]]),
                               ([], ['check', 'reset-check', *steps])]:
            with self.subTest(args=args):
                events.write_text('')
                result = subprocess.run(['bash', str(scripts / 'run.sh'), *args],
                                        env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(events.read_text().splitlines(), expected)
        # A failed phase must not advance to the next one on resume.
        (scripts / '04-dora.sh').write_text('exit 17\n')
        events.write_text('')
        failed = subprocess.run(['bash', str(scripts / 'run.sh'), '--from', '04'],
                                env=env, capture_output=True, text=True)
        self.assertEqual(failed.returncode, 17)
        self.assertEqual(events.read_text().splitlines(), ['check'])


if __name__ == '__main__':
    unittest.main()
