"""Run with: python3 -m unittest discover -s bin/tests -v (no live desktop changes)."""
import importlib.machinery
import importlib.util
import json
import multiprocessing
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
BIN = ROOT / 'i3/.config/i3/bin'


def load(name):
    loader = importlib.machinery.SourceFileLoader(name.replace('-', '_'), str(BIN / name))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


hw, displays, focus = load('hardware'), load('display'), load('focus-mode')


class HardwareTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.patch = patch.object(hw, 'SYS', self.root)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def files(self, base, **values):
        for name, value in values.items():
            path = self.root / base / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(str(value))

    def test_intel_packages_and_unrelated_hot_nvme(self):
        self.files('class/hwmon/hwmon9', name='coretemp', temp1_label='Package id 0', temp1_input=51000,
                   temp2_label='Core 0', temp2_input=61000)
        self.files('class/hwmon/hwmon3', name='coretemp', temp1_label='Package id 1', temp1_input=54000)
        self.files('class/hwmon/hwmon0', name='nvme', temp1_input=90000)
        self.assertEqual(hw.cpu_temperature(), 54)

    def test_amd_tdie_preferred_over_offset_tctl(self):
        self.files('class/hwmon/hwmon7', name='k10temp', temp1_label='Tctl', temp1_input=75000,
                   temp2_label='Tdie', temp2_input=55000)
        self.assertEqual(hw.cpu_temperature(), 55)

    def test_arm_thermal_and_no_sensor(self):
        self.files('class/thermal/thermal_zone4', type='gpu-thermal', temp=90000)
        self.assertIsNone(hw.cpu_temperature())
        self.files('class/thermal/thermal_zone8', type='cpu-thermal', temp=42000)
        self.assertEqual(hw.cpu_temperature(), 42)

    def test_battery_names_units_and_peripherals(self):
        self.files('class/power_supply/BAT7', type='Battery', energy_now=10000000, energy_full=40000000)
        self.files('class/power_supply/CMB1', type='Battery', charge_now=2000000,
                   charge_full=2000000, voltage_min_design=10000000, status='Charging')
        self.files('class/power_supply/ACAD', type='Mains', online=1)
        self.files('class/power_supply/mouse', type='Battery', scope='Device', capacity=1)
        self.files('class/power_supply/BAT0', type='Battery', present=0, capacity=1)
        battery = hw.battery_reading()
        self.assertEqual(battery['count'], 2)
        self.assertEqual(battery['percent'], 50)  # 30 Wh / 60 Wh, not mean(25%, 100%).
        self.assertTrue(battery['charging'])
        self.assertTrue(battery['online'])

    def test_no_battery_and_dynamic_backlight(self):
        self.assertIsNone(hw.battery_reading())
        self.assertIsNone(hw.backlight_reading())
        self.files('class/backlight/amdgpu_bl2', type='raw', brightness=60, max_brightness=240)
        self.assertEqual(hw.backlight_reading(), {'device': 'amdgpu_bl2', 'percent': 25})

    def test_nvidia_repaint_workaround_only_for_connected_nvidia_output(self):
        self.assertEqual(hw.compositor_flag(), '--use-damage')
        driver = self.root / 'bus/pci/drivers/nvidia'
        driver.mkdir(parents=True)
        self.files('class/drm/card1-HDMI-A-1', status='disconnected')
        device = self.root / 'class/drm/card1/device'
        device.mkdir(parents=True)
        (device / 'driver').symlink_to(driver)
        self.assertEqual(hw.compositor_flag(), '--use-damage')
        self.files('class/drm/card1-HDMI-A-1', status='connected')
        self.assertEqual(hw.compositor_flag(), '--no-use-damage')

    def nvidia(self, card, bus, status):
        device = self.root / 'devices' / bus
        device.mkdir(parents=True)
        link = self.root / f'class/drm/{card}/device'
        link.parent.mkdir(parents=True)
        link.symlink_to(device)
        self.files(f'devices/{bus}', vendor='0x10de', **{'power/runtime_status': status})

    def test_sleeping_nvidia_is_never_queried(self):
        self.nvidia('card1', '0000:01:00.0', 'suspended')
        with patch.object(hw, 'command') as cmd:
            self.assertEqual(hw.gpu_readings()[0]['sleeping'], True)
        cmd.assert_not_called()

    def test_hybrid_gpus_query_only_awake_bus_and_ignore_na(self):
        self.nvidia('card3', '0000:03:00.0', 'active')
        self.nvidia('card8', '0000:08:00.0', 'suspended')
        self.files('class/drm/card0/device', vendor='0x8086')
        with patch.object(hw, 'command', return_value='00000000:03:00.0, 12, 45, [N/A], 8192') as cmd:
            gpus = hw.gpu_readings()
        self.assertIn('--id=0000:03:00.0', cmd.call_args.args[0])
        self.assertEqual(gpus[1]['percent'], 12)
        self.assertEqual(gpus[1]['temperature'], 45)
        self.assertNotIn('memory_used', gpus[1])
        self.assertIsNone(gpus[0]['percent'])

    def test_amd_gpu_sysfs(self):
        self.files('class/drm/card2/device', vendor='0x1002', gpu_busy_percent=27,
                   mem_info_vram_used=1048576, mem_info_vram_total=8388608,
                   **{'hwmon/hwmon6/temp1_input': 49000})
        gpu = hw.gpu_readings()[0]
        self.assertEqual((gpu['percent'], gpu['temperature'], gpu['memory_used']), (27, 49, 1))

    def test_route_change_resets_rate_and_ipv6_fallback(self):
        self.files('class/net/enp9s0/statistics', rx_bytes=14096, tx_bytes=22048)
        old = {'at': 10, 'network': {'iface': 'enp9s0', 'rx': 10000, 'tx': 20000}}
        route = json.dumps([{'dev': 'enp9s0', 'prefsrc': '192.0.2.2'}])
        with patch.object(hw, 'command', return_value=route):
            net = hw.network_reading(old, 14)
        self.assertEqual((net['down'], net['up']), (1024, 512))
        self.files('class/net/tun7/statistics', rx_bytes=900000, tx_bytes=800000)
        with patch.object(hw, 'command', side_effect=['', '[{"dev":"tun7","prefsrc":"2001:db8::1"}]']):
            net = hw.network_reading(old, 14)
        self.assertEqual(net['iface'], 'tun7')
        self.assertIsNone(net['down'])
        with patch.object(hw, 'command', return_value=''):
            self.assertIsNone(hw.network_reading(old, 14))

    def test_shared_cache_and_expiry(self):
        with patch.dict(os.environ, {'XDG_CACHE_HOME': str(self.root / 'cache')}), \
                patch.object(hw, 'collect', side_effect=lambda old: {'at': time.monotonic(), 'test': True}) as sample:
            self.assertEqual(hw.snapshot(), hw.snapshot())
            self.assertEqual(sample.call_count, 1)
            cache = self.root / 'cache/i3-hardware/sample.json'
            cache.write_text('{"at": -100}')
            hw.snapshot()
            self.assertEqual(sample.call_count, 2)

    def test_concurrent_bars_share_one_hardware_query(self):
        queries = self.root / 'queries'

        def collect(old):
            with queries.open('a') as f:
                f.write('query\n')
            time.sleep(0.05)  # Let all readers contend for the same cache lock.
            return {'at': time.monotonic()}

        with patch.dict(os.environ, {'XDG_CACHE_HOME': str(self.root / 'cache')}), \
                patch.object(hw, 'collect', side_effect=collect):
            processes = [multiprocessing.get_context('fork').Process(target=hw.snapshot) for _ in range(6)]
            for process in processes:
                process.start()
            for process in processes:
                process.join(timeout=3)
                self.assertEqual(process.exitcode, 0)
        self.assertEqual(queries.read_text().splitlines(), ['query'])


class DisplayTests(unittest.TestCase):
    def test_preferred_refresh_and_disconnected_output(self):
        args = displays.display_args('''eDP-2 connected primary 1920x1080+0+0
   1920x1080 60.00*+ 120.00
HDMI-3 connected
   2560x1440 59.95+ 99.95
DP-9 disconnected
''')
        self.assertIn('120.0', args)
        self.assertIn('99.95', args)
        self.assertEqual(args[-3:], ['--output', 'DP-9', '--off'])
        self.assertIn('--primary', args)
        self.assertEqual(args[args.index('--right-of') + 1], 'eDP-2')

    def test_missing_preferred_uses_active_then_first(self):
        args = displays.display_args('''HDMI-1 connected
   3840x2160 60.00
   1920x1080 60.00* 144.00
''')
        self.assertEqual(args[args.index('--mode') + 1], '1920x1080')
        self.assertIn('144.0', args)
        self.assertEqual(displays.display_args('DP-1 disconnected'), [])


class FocusTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.state = Path(self.temp.name) / 'focus.json'
        p = patch.object(focus, 'STATE', self.state)
        p.start()
        self.addCleanup(p.stop)

    def roundtrip(self, paused, widgets, video, windows):
        calls = []
        current = set(windows)

        def run(args, check=False):
            args = [str(a) for a in args]
            calls.append(args)
            if args == ['dunstctl', 'is-paused']:
                return subprocess.CompletedProcess(args, 0, paused)
            if args[-2:] == [str(focus.BIN / 'widgets'), 'status']:
                return subprocess.CompletedProcess(args, 0 if widgets else 1, '')
            if args[0] == str(focus.BIN / 'lyrics'):
                current.symmetric_difference_update({'lyrics'})
            return subprocess.CompletedProcess(args, 0, '')

        with patch.object(focus, 'run', side_effect=run), \
                patch.object(focus, 'instances', side_effect=lambda: current.copy()), \
                patch.object(focus, 'wallpaper', side_effect=[video, None] if video else [None]):
            focus.enter()
            self.assertTrue(self.state.exists())
            focus.leave()
            self.assertFalse(self.state.exists())
        self.assertIn(['dunstctl', 'set-paused', paused], calls)
        return calls

    def test_restore_exact_video_and_previously_running_extras(self):
        video = '/tmp/video with spaces.mp4'
        calls = self.roundtrip('false', True, video, {'cava', 'lyrics'})
        for component, action in [('widgets', 'stop'), ('widgets', 'start'),
                                  ('cava-toggle', 'stop'), ('cava-toggle', 'start'), ('livewall', video)]:
            self.assertIn([str(focus.BIN / component), action], calls)
        self.assertEqual(calls.count([str(focus.BIN / 'lyrics'), 'toggle']), 2)

    def test_leave_previously_disabled_components_and_paused_notifications_alone(self):
        calls = self.roundtrip('true', False, None, set())
        self.assertFalse(any(c[-1] in ('start', 'stop', 'toggle') for c in calls))

    def test_failed_snapshot_does_not_change_desktop(self):
        with patch.object(focus, 'instances', side_effect=ValueError('no IPC')), patch.object(focus, 'run') as run:
            with self.assertRaises(ValueError):
                focus.enter()
            run.assert_not_called()
            self.assertFalse(self.state.exists())


class BarTests(unittest.TestCase):
    def test_mirrored_screens_primary_tray_and_focus_media(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mocks = root / 'bin'
            mocks.mkdir()
            (root / 'monitors').write_text('DP-2: 2560x1440+0+0\nHDMI-1: 2560x1440+0+0 (primary)\neDP-1: 1920x1080+2560+0\n')
            scripts = {'pkill': '#!/bin/sh\nexit 1\n', 'pgrep': '#!/bin/sh\nexit 1\n',
                       'polybar': '''#!/bin/sh
if [ "$1" = --list-all-monitors ]; then cat "$TEST_MONITORS"; exit; fi
printf '%s|%s|%s\\n' "$MONITOR" "$BAR_CENTER" "$BAR_RIGHT" >> "$TEST_BAR_LOG"
'''}
            for name, text in scripts.items():
                path = mocks / name
                path.write_text(text)
                path.chmod(0o755)
            env = {**os.environ, 'PATH': str(mocks) + ':' + os.environ['PATH'],
                   'XDG_RUNTIME_DIR': tmp, 'XDG_CACHE_HOME': tmp,
                   'TEST_MONITORS': str(root / 'monitors'), 'TEST_BAR_LOG': str(root / 'bars')}
            for active in (False, True):
                if active:
                    (root / f'dotfiles-i3-focus-{os.getuid()}.json').write_text('{}')
                (root / 'bars').write_text('')
                subprocess.run(['bash', str(BIN / 'i3bar')], env=env, check=True, timeout=5)
                for _ in range(100):
                    rows = (root / 'bars').read_text().splitlines()
                    if len(rows) == 2:
                        break
                    time.sleep(0.01)
                self.assertEqual(len(rows), 2)
                by_monitor = {row.split('|')[0]: row.split('|')[1:] for row in rows}
                self.assertEqual(set(by_monitor), {'HDMI-1', 'eDP-1'})
                self.assertIn('systray', by_monitor['HDMI-1'][1])
                self.assertNotIn('systray', by_monitor['eDP-1'][1])
                self.assertEqual(by_monitor['HDMI-1'][0], '' if active else 'mpd cava lyrics')
                self.assertEqual(by_monitor['eDP-1'][0], '')


class BrightnessTests(unittest.TestCase):
    def test_detected_panel_and_external_ddc_backend(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'brightness').write_text((BIN / 'brightness').read_text())
            for name, content in {
                'hardware': '#!/bin/sh\nprintf "%s\\n" "$TEST_PANEL"\n',
                'brightnessctl': '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_LOG"\n',
                'ddcutil': '#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_LOG"\n',
            }.items():
                path = root / name
                path.write_text(content)
                path.chmod(0o755)
            env = {**os.environ, 'PATH': tmp + ':' + os.environ['PATH'],
                   'TEST_PANEL': 'amdgpu_bl3', 'TEST_LOG': str(root / 'args')}
            subprocess.run(['bash', str(root / 'brightness'), 'up'], env=env, check=True)
            self.assertIn('--device=amdgpu_bl3', (root / 'args').read_text().splitlines())
            env['TEST_PANEL'] = ''
            subprocess.run(['bash', str(root / 'brightness'), 'down'], env=env, check=True)
            self.assertEqual((root / 'args').read_text().splitlines(), ['--noverify', 'setvcp', '10', '-', '5'])


if __name__ == '__main__':
    unittest.main()
