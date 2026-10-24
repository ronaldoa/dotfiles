"""Run with: python3 -m unittest discover -s bin/tests -v (no live desktop changes)."""
import importlib.machinery
import importlib.util
import json
import multiprocessing
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from types import SimpleNamespace
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

    def test_cpu_driver_beats_motherboard_cputin(self):
        self.files('class/hwmon/hwmon2', name='k10temp', temp1_label='Tctl', temp1_input=45000)
        self.files('class/hwmon/hwmon3', name='nct6798', temp2_label='CPUTIN', temp2_input=127000)
        self.assertEqual(hw.cpu_temperature(), 45)
        (self.root / 'class/hwmon/hwmon2/temp1_input').unlink()
        self.assertEqual(hw.cpu_temperature(), 127)  # Label match still serves boards without a CPU driver.

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
        with patch.object(hw, 'command', return_value='00000000:03:00.0, 12, 45, [N/A], 8192, GeForce Test') as cmd:
            gpus = hw.gpu_readings()
        self.assertIn('--id=0000:03:00.0', cmd.call_args.args[0])
        self.assertEqual(gpus[1]['percent'], 12)
        self.assertEqual(gpus[1]['temperature'], 45)
        self.assertEqual(gpus[1]['name'], 'GeForce Test')
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



class DetailTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.proc, self.sys = Path(self.temp.name) / 'proc', Path(self.temp.name) / 'sys'
        self.proc.mkdir()
        for name, value in (('PROC', self.proc), ('SYS', self.sys)):
            patched = patch.object(hw, name, value)
            patched.start()
            self.addCleanup(patched.stop)

    def files(self, base, **values):
        for name, value in values.items():
            path = base / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(str(value))

    def test_cpu_topology_usage_and_guest_time(self):
        (self.proc / 'cpuinfo').write_text('processor: 0\nmodel name: Test CPU\nphysical id: 0\ncore id: 0\n\n'
                                         'processor: 1\nmodel name: Test CPU\nphysical id: 0\ncore id: 0\n')
        (self.proc / 'stat').write_text('cpu 10 0 20 50 5 0 10 5 8 2\n')
        self.assertEqual(hw.cpu_times(), (100, 55))  # Guest time must not be counted twice.
        with patch.object(hw, 'cpu_times', side_effect=[(100, 55), (200, 105)]), \
                patch.object(hw.time, 'sleep'), patch.object(hw, 'cpu_temperature', return_value=42):
            rows = hw.cpu_details()
        self.assertIn('Model    Test CPU', rows)
        self.assertIn('Logical CPUs    2', rows)
        self.assertIn('Physical cores    1', rows)
        self.assertIn('Usage    50.0%', rows)
        self.assertIn('Temperature    42°C', rows)

    def test_cpu_frequency_cache_sensors_and_busiest_processes(self):
        (self.proc / 'cpuinfo').write_text('processor: 0\nmodel name: Test CPU\n\nprocessor: 1\nmodel name: Test CPU\n')
        cpus = self.sys / 'devices/system/cpu'
        for cpu, current in (('cpu0', 1000000), ('cpu1', 3000000)):
            self.files(cpus / cpu, **{'cpufreq/scaling_cur_freq': current, 'cpufreq/cpuinfo_max_freq': 5000000,
                                      'cache/index2/level': 2, 'cache/index2/type': 'Unified',
                                      'cache/index2/size': '512K', 'cache/index2/shared_cpu_list': cpu[-1],
                                      'cache/index3/level': 3, 'cache/index3/type': 'Unified',
                                      'cache/index3/size': '32768K', 'cache/index3/shared_cpu_list': '0-1'})
        self.files(cpus / 'cpu0/cpufreq', scaling_governor='powersave', scaling_driver='amd-pstate-epp',
                   energy_performance_preference='balance_performance')
        self.files(self.sys / 'class/hwmon/hwmon2', name='k10temp', temp1_label='Tctl', temp1_input=70000,
                   temp3_label='Tccd1', temp3_input=60000)
        self.files(self.proc, loadavg='1.00 0.50 0.25 3/700 99', uptime='93784.5 1.0',
                   **{'pressure/cpu': 'some avg10=1.25 avg60=0 avg300=0 total=1\n'})
        line = '{pid} (my prog) S ' + ' '.join(['0'] * 10) + ' {ticks} 0 0'
        ticks = [{'10': ('my prog', 100), '11': ('idle', 5)}, {'10': ('my prog', 150), '11': ('idle', 5)}]
        self.assertEqual(hw.process_ticks(), {})
        self.files(self.proc / '10', stat=line.format(pid=10, ticks=7))
        self.assertEqual(hw.process_ticks(), {'10': ('my prog', 7)})  # Names may contain spaces.
        with patch.object(hw, 'cpu_times', side_effect=[(100, 50), (200, 100)]), \
                patch.object(hw, 'process_ticks', side_effect=ticks), patch.object(hw.time, 'sleep'):
            rows = hw.cpu_details()
        self.assertIn('Frequency    avg 2.00 GHz · max 3.00 GHz (limit 5.00 GHz)', rows)
        self.assertIn('Governor    powersave · balance_performance (amd-pstate-epp)', rows)
        self.assertIn('Cache    L2 1.0 MiB · L3 32.0 MiB', rows)  # The shared L3 is counted once.
        self.assertIn('Sensors    Tctl 70°C · Tccd1 60°C', rows)
        self.assertIn('Threads (running / total)    3 / 700', rows)
        self.assertIn('CPU pressure (10 s)    some 1.2%', rows)
        self.assertIn('Uptime    1d 2h 3m', rows)
        # 50 ticks out of 50 per CPU in the interval = one full core; idle processes are left out.
        self.assertEqual(rows[-2:], ['▸ Top processes by CPU (one full core = 100%)', 'my prog (10)    100.0%'])

    def test_memory_matches_available_and_reports_swap(self):
        (self.proc / 'meminfo').write_text('MemTotal: 1048576 kB\nMemAvailable: 786432 kB\n'
            'MemFree: 524288 kB\nBuffers: 65536 kB\nCached: 131072 kB\nSReclaimable: 65536 kB\n'
            'Shmem: 32768 kB\nSwapTotal: 524288 kB\nSwapFree: 393216 kB\n')
        rows = hw.memory_details()
        self.assertIn('Total    1.0 GiB', rows)
        self.assertIn('Used    256.0 MiB  (25.0%)', rows)
        self.assertIn('Cache & buffers    256.0 MiB', rows)
        self.assertIn('Swap    128.0 MiB / 512.0 MiB  (25.0%)', rows)

    def test_memory_swap_devices_pressure_and_largest_processes(self):
        self.files(self.proc, meminfo='MemTotal: 1048576 kB\nMemAvailable: 524288 kB\nMemFree: 1 kB\n'
                   'SwapTotal: 2048 kB\nSwapFree: 1024 kB\n',
                   swaps='Filename Type Size Used Priority\n/swap\\040file file 2048 1024 -2\n',
                   **{'pressure/memory': 'some avg10=2.50 avg60=0 avg300=0 total=1\n'
                      'full avg10=0.50 avg60=0 avg300=0 total=1\n',
                      '7/status': 'Name:\tbig\nVmRSS:\t  2048 kB\n', '8/status': 'Name:\tkthread\n',
                      '9/status': 'Name:\tsmall\nVmRSS:\t1024 kB\n'})
        rows = hw.memory_details()
        self.assertIn('Swap device    /swap file (file) 1.0 MiB / 2.0 MiB', rows)
        self.assertIn('Memory pressure (10 s)    some 2.5% · full 0.5%', rows)
        self.assertEqual(rows[-3:], ['▸ Top processes by memory (RSS, shared pages included)',
                                     'big (7)    2.0 MiB', 'small (9)    1.0 MiB'])

    def test_old_memory_kernel_and_unavailable_readings(self):
        self.assertEqual(hw.memory_details(), ['Memory information unavailable'])
        (self.proc / 'meminfo').write_text('MemTotal: 1024 kB\nMemFree: 256 kB\nBuffers: 64 kB\n'
                                         'Cached: 128 kB\nSReclaimable: 128 kB\nShmem: 64 kB\n')
        rows = hw.memory_details()
        self.assertIn('Used    512 KiB  (50.0%)', rows)
        self.assertIn('Swap    off', rows)

    def test_gpu_details_keep_sleeping_cards_asleep(self):
        gpus = [{'card': 'card0', 'vendor': 'NVIDIA', 'name': 'GeForce Test', 'sleeping': False,
                 'percent': 12, 'temperature': 45, 'memory_used': 2048, 'memory_total': 8192},
                {'card': 'card1', 'vendor': 'AMD', 'sleeping': True}]
        with patch.object(hw, 'gpu_readings', return_value=gpus), patch.object(hw, 'command') as query:
            rows = hw.gpu_details()
        query.assert_not_called()
        self.assertIn('GPU 1    GeForce Test (card0)', rows)
        self.assertIn('▸ GPU 2    AMD (card1)', rows)
        self.assertIn('State    asleep', rows)
        self.assertIn('VRAM    2.0 GiB / 8.0 GiB  (25.0%)', rows)

    def test_nvidia_details_query_only_its_bus_and_skip_unsupported(self):
        gpus = [{'card': 'card0', 'vendor': 'NVIDIA', 'bus': '0000:01:00.0', 'name': 'GeForce Test',
                 'sleeping': False, 'temperature': 50}]
        answers = {'--query-gpu': '550.1, P2, 90.5, 165.00, 2700, 3100, 8750, [N/A]',
                   '--query-compute-apps': '42, /opt/bin/llama-server, 2048\n43, game, [N/A]'}

        def smi(args):
            self.assertIn('--id=0000:01:00.0', args)
            return next(value for key, value in answers.items() if any(a.startswith(key) for a in args))
        self.files(self.sys / 'devices/gpu', current_link_speed='2.5 GT/s PCIe', current_link_width=8,
                   max_link_speed='16.0 GT/s PCIe', max_link_width=16)
        (self.sys / 'class/drm/card0').mkdir(parents=True)
        (self.sys / 'class/drm/card0/device').symlink_to(self.sys / 'devices/gpu')
        with patch.object(hw, 'gpu_readings', return_value=gpus), patch.object(hw, 'command', side_effect=smi):
            rows = hw.gpu_details()
        for row in ('P-state    P2', 'Power    90.5 W / 165.00 W', 'Core clock    2700 / 3100 MHz',
                    'Memory clock    8750 MHz', 'PCIe    2.5 GT/s ×8 (max 16.0 GT/s ×16)',
                    'llama-server (42)    2.0 GiB'):
            self.assertIn(row, rows)
        self.assertFalse(any(row.startswith(('Fan', 'game')) for row in rows))

    def test_amd_and_intel_details_from_sysfs(self):
        device = self.sys / 'class/drm/card1/device'
        self.files(device / 'hwmon/hwmon5', power1_average=45500000, power1_cap=200000000,
                   freq1_input=2100000000, freq2_input=1000000000, fan1_input=1200)
        self.files(self.sys / 'class/drm/card0', gt_cur_freq_mhz=350, gt_max_freq_mhz=1300)
        gpus = [{'card': 'card0', 'vendor': 'Intel', 'sleeping': False},
                {'card': 'card1', 'vendor': 'AMD', 'name': 'Radeon Test', 'sleeping': False}]
        with patch.object(hw, 'gpu_readings', return_value=gpus), patch.object(hw, 'command') as query:
            rows = hw.gpu_details()
        query.assert_not_called()
        for row in ('Core clock    350 / 1300 MHz', '▸ GPU 2    Radeon Test (card1)', 'Power    45.5 W / 200 W',
                    'Core clock    2100 MHz', 'Memory clock    1000 MHz', 'Fan    1200 RPM'):
            self.assertIn(row, rows)

    def test_wifi_network_details(self):
        net = {'iface': 'wlan0', 'ip': '10.0.0.5', 'rx': 2 ** 30, 'tx': 2 ** 20, 'down': 2048, 'up': None}
        self.files(self.sys / 'class/net/wlan0', address='aa:bb:cc:dd:ee:ff', **{'wireless/x': ''})
        outputs = {'iw': 'Connected to x\n\tSSID: Home\x1bNet\n\tfreq: 5180.0\n\tsignal: -50 dBm\n'
                         '\trx bitrate: 400.0 MBit/s 80MHz\n\ttx bitrate: 300.0 MBit/s\n',
                   'addr': json.dumps([{'addr_info': [{'family': 'inet', 'local': '10.0.0.5', 'prefixlen': 24,
                                                       'scope': 'global'},
                                                      {'family': 'inet6', 'local': 'fe80::1', 'scope': 'link'}]}]),
                   'route': json.dumps([{'gateway': '10.0.0.1'}])}
        with patch.object(hw, 'snapshot', return_value={'network': net}), \
                patch.object(hw, 'command', side_effect=lambda args: outputs[args[0] if args[0] == 'iw' else args[2]]):
            rows = hw.network_details()
        for row in ('Interface    wlan0 (Wi-Fi)', 'Wi-Fi    Home Net', 'Band    5.2 GHz', 'Signal    -50 dBm',
                    'Link rate (rx / tx)    400.0 / 300.0 Mbit/s', 'IPv4    10.0.0.5/24', 'Gateway    10.0.0.1',
                    'MAC    aa:bb:cc:dd:ee:ff', 'Throughput    ↓2K/s ↑—/s', 'Since boot    ↓1.0 GiB ↑1.0 MiB'):
            self.assertIn(row, rows)
        self.assertFalse(any('fe80' in row for row in rows))
        with patch.object(hw, 'snapshot', return_value={'network': None}):
            self.assertEqual(hw.network_details(), ['Not connected'])

    def popup(self, returncode, chosen=''):
        process = SimpleNamespace(pid=4321, returncode=returncode)
        process.communicate = lambda text: (process.__dict__.update(input=text), (chosen, None))[1]
        return process

    def test_detail_card_escapes_markup_and_copies_the_chosen_value(self):
        rows = ['Model    A<B>&\nmodel', '▸ Processes', 'x (1)    5%']
        with tempfile.TemporaryDirectory() as cache, patch.dict(os.environ, {'XDG_CACHE_HOME': cache}), \
                patch.object(hw, 'command', return_value=''):
            process = self.popup(1)
            with patch.object(hw.subprocess, 'Popen', return_value=process) as popup, \
                    patch.object(hw.subprocess, 'run') as copy:
                hw.show_details('cpu-info', 'CPU', rows)
            args = popup.call_args.args[0]
            self.assertNotIn('-m', args)  # Rofi's default: the screen under the pointer, i.e. the clicked bar.
            self.assertIn('location: north;', args[args.index('-theme-str') + 1])
            self.assertIn('A&lt;B&gt;&amp; model', process.input)  # Device text never becomes markup.
            self.assertNotIn('<B>', process.input)
            self.assertEqual(len(process.input.splitlines()), 3)
            copy.assert_not_called()  # Esc copies nothing.
            for chosen, copied in (('0\n', 'A<B>& model'), ('1\n', None), ('9\n', None)):
                with patch.object(hw.subprocess, 'Popen', return_value=self.popup(0, chosen)), \
                        patch.object(hw.subprocess, 'run') as copy:
                    hw.show_details('cpu-info', 'CPU', rows)
                self.assertEqual(copy.call_args.kwargs['input'] if copy.called else None, copied)

    def test_gauges_colour_by_load_and_process_bars_are_relative(self):
        self.assertEqual(hw.gauge('Temperature', '72°C'), (72, False))
        self.assertEqual(hw.gauge('Signal', '-60 dBm'), (50, True))
        self.assertEqual(hw.gauge('Power', '50 W / 200 W'), (25, False))
        self.assertEqual(hw.gauge('VRAM', '15.3 GiB / 16.0 GiB  (95.7%)'), (95.7, False))
        self.assertIsNone(hw.gauge('Model', 'CPU 100%'))
        with patch.object(hw, 'command', return_value='theme.red:\t#FF0000\ntheme.green: #00FF00\n'):
            colors = hw.palette()
        self.assertEqual((colors['red'], colors['green'], colors['blue']), ('#FF0000', '#00FF00', '#81A1C1'))
        styled = hw.styled_rows('memory-info', ['Used    1 GiB  (95.0%)', 'Swap    0 KiB / 1 GiB  (10.0%)',
                                                '▸ Top processes by memory', 'big (7)    2.0 GiB', 'small (8)    512.0 MiB'],
                                colors)
        self.assertIn('#FF0000', styled[0])  # 95% used is red, 10% swap is green.
        self.assertIn('#00FF00', styled[1])
        self.assertEqual([row.count('━') for row in styled[3:]], [10, 10])
        filled = [row.split(f'<span color="{colors["blue"]}">')[-1].split('<')[0].count('━') for row in styled[3:]]
        self.assertEqual(filled, [10, 2])  # 512 MiB is a quarter of the largest process.

    def test_second_click_closes_the_card_and_another_module_replaces_it(self):
        with tempfile.TemporaryDirectory() as cache, patch.dict(os.environ, {'XDG_CACHE_HOME': cache}):
            state = Path(cache) / 'i3-hardware/details.json'
            self.assertFalse(hw.close_details('cpu-info'))
            self.files(self.proc, **{'4321/comm': 'rofi'})
            state.write_text(json.dumps({'mode': 'cpu-info', 'pid': 4321}))
            killed = lambda pid, sig: (self.proc / '4321/comm').write_text('zombie')
            with patch.object(hw.os, 'kill', side_effect=killed) as kill:
                self.assertTrue(hw.close_details('cpu-info'))
            kill.assert_called_once_with(4321, hw.signal.SIGTERM)
            (self.proc / '4321/comm').write_text('rofi')
            with patch.object(hw.os, 'kill', side_effect=killed):
                self.assertFalse(hw.close_details('gpu-info'))  # Close the CPU card, then open GPU.
            # The click that closed rofi from outside reaches Polybar too: don't reopen at once.
            state.write_text(json.dumps({'mode': 'cpu-info', 'closed': time.monotonic()}))
            self.assertTrue(hw.close_details('cpu-info'))
            self.assertFalse(hw.close_details('memory-info'))
            state.write_text(json.dumps({'mode': 'cpu-info', 'closed': time.monotonic() - 5}))
            self.assertFalse(hw.close_details('cpu-info'))


class DiskTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name, value in [('PROC', self.root / 'proc'), ('SYS', self.root / 'sys')]:
            patched = patch.object(hw, name, value)
            patched.start()
            self.addCleanup(patched.stop)
        self.mounts, self.usages = [], {}

    def mount(self, target, device='8:1', source='/dev/sda1', kind='ext4', fsroot='/',
              fsid=1, blocks=100, free=40, available=30):
        def escape(value):
            return value.replace('\\', r'\134').replace(' ', r'\040').replace('\t', r'\011').replace('\n', r'\012')
        self.mounts.append(f'1 0 {device} {escape(fsroot)} {escape(target)} rw shared:2 - {kind} {escape(source)} rw')
        self.usages[target] = SimpleNamespace(f_blocks=blocks, f_bfree=free, f_bavail=available,
                                              f_frsize=1024, f_fsid=fsid)

    def collect(self):
        mountinfo = hw.PROC / 'self/mountinfo'
        mountinfo.parent.mkdir(parents=True, exist_ok=True)
        mountinfo.write_text('\n'.join(self.mounts))

        def statvfs(target):
            value = self.usages.get(target, FileNotFoundError(target))
            if isinstance(value, OSError):
                raise value
            return value

        with patch.object(hw.os.path, 'isdir', side_effect=lambda path: str(path) in self.usages), \
                patch.object(hw.os, 'statvfs', side_effect=statvfs):
            return hw.disk_readings()

    def test_root_home_data_and_usb_are_discovered(self):
        self.mount('/', source='/dev/nvme0n1p2', fsid=10)
        self.mount('/mnt/data', device='259:1', source='/dev/nvme1n1', fsid=20)
        self.mount('/home', device='259:5', source='/dev/mapper/home', fsid=30)
        self.mount('/run/media/user/USB Disk', device='8:17', source='/dev/sdb1', kind='exfat', fsid=40)
        disks = self.collect()
        self.assertEqual(disks[0]['mount'], '/')
        self.assertEqual({d['mount'] for d in disks}, {'/', '/mnt/data', '/home', '/run/media/user/USB Disk'})
        self.assertEqual(disks[0]['used'], 60 * 1024)
        self.assertEqual(disks[0]['available'], 30 * 1024)
        self.assertAlmostEqual(disks[0]['percent'], 100 * 60 / 90)  # Match df: exclude reserved free blocks.

    def test_virtual_network_appimage_and_loop_mounts_are_filtered(self):
        self.mount('/')
        for index, (target, kind, source) in enumerate([
            ('/proc', 'proc', 'proc'), ('/tmp', 'tmpfs', 'tmpfs'),
            ('/var/lib/docker/overlay', 'overlay', 'overlay'), ('/mnt/nfs', 'nfs4', 'server:/data'),
            ('/tmp/.mount_App', 'fuse.AppImage', 'App.AppImage'),
            ('/snap/app', 'squashfs', '/dev/loop1'), ('/mnt/image', 'ext4', '/dev/loop2'),
        ], 2):
            self.mount(target, device=f'0:{index}', kind=kind, source=source, fsid=index)
        self.assertEqual([d['mount'] for d in self.collect()], ['/'])

    def test_bind_mount_and_btrfs_subvolume_capacities_are_not_duplicated(self):
        self.mount('/', kind='btrfs', device='0:42', fsroot='/@', fsid=10)
        self.mount('/home', kind='btrfs', device='0:43', fsroot='/@home', fsid=10)
        self.mount('/mnt/data', device='259:1', source='/dev/nvme1n1', fsid=20)
        self.mount('/data', device='259:1', source='/dev/nvme1n1', fsroot='/files', fsid=20)
        self.assertEqual([d['mount'] for d in self.collect()], ['/', '/mnt/data'])

    def test_unplug_permission_error_and_zero_capacity_do_not_break_other_disks(self):
        self.mount('/')
        for index, target in enumerate(['/mnt/unplugged', '/mnt/private', '/mnt/empty'], 2):
            self.mount(target, device=f'8:{index}', source=f'/dev/sd{index}', fsid=index)
        self.usages['/mnt/unplugged'] = FileNotFoundError()
        self.usages['/mnt/private'] = PermissionError()
        self.usages['/mnt/empty'].f_blocks = 0
        self.assertEqual([d['mount'] for d in self.collect()], ['/'])

    def test_hotplug_removal_updates_the_next_sample(self):
        self.mount('/')
        self.mount('/media/usb', device='8:17', source='/dev/sdb1', fsid=2)
        self.assertEqual(len(self.collect()), 2)
        self.mounts.pop()
        self.assertEqual(len(self.collect()), 1)

    def test_missing_mountinfo_keeps_root_and_invalid_lines_are_ignored(self):
        self.mount('/')
        self.mounts = ['malformed line']
        self.assertEqual([d['mount'] for d in self.collect()], ['/'])

    def test_escaped_paths_and_bar_markup_are_plain_text(self):
        mount = '/media/disk\\name with\tspace\nand%{A:command:}'
        self.mount(mount, fsid=2)
        disks = self.collect()
        self.assertEqual(disks[0]['mount'], mount)
        with patch.object(hw.time, 'time', return_value=0):
            label = hw.disk_label(disks)
        self.assertNotIn('\n', label)
        self.assertNotIn('\t', label)
        self.assertNotIn('%{', label)

    def test_menu_cancellation_and_selected_mount_with_spaces(self):
        disks = [{'mount': '/media/USB Disk', 'used': 10, 'total': 100, 'available': 90, 'percent': 10}]
        with patch.object(hw.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '')), \
                patch.object(hw.subprocess, 'Popen') as opened:
            hw.disk_menu(disks)
            opened.assert_not_called()
        with patch.object(hw.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '0\n')), \
                patch.object(hw.subprocess, 'Popen') as opened:
            hw.disk_menu(disks)
            self.assertEqual(opened.call_args.args[0], ['xdg-open', '/media/USB Disk'])

    @unittest.skipUnless(shutil.which('lua'), 'Lua is optional for the widget rendering test')
    def test_widget_paginates_all_disks_and_handles_removal(self):
        script = r'''
local sample, drawn = '', {}
local noop = function() end
local L = {cached=function() return sample end, split=function() return {''} end,
           num=function(v) return tonumber(v) or 0 end, rgba=noop, rounded=noop,
           card=noop, bar=noop, finish=noop,
           text=function(x, y, value) drawn[value] = true end,
           begin=function(w, h) assert(h == 602); return {} end}
dofile = function() return L end
conky_parse = function() return '0' end
cairo_move_to, cairo_line_to, cairo_close_path, cairo_fill = noop, noop, noop, noop
assert(loadfile(WIDGETS))()
local mounts = {'/', '/home', '/mnt/data', '/boot/efi'}
sample = 'disk_count=4\n'
for i, mount in ipairs(mounts) do
    sample = sample .. 'disk_' .. i .. '_mount=' .. mount .. '\n'
        .. 'disk_' .. i .. '_usage=10 GiB / 20 GiB\n'
        .. 'disk_' .. i .. '_percent=50\n'
end
os.time = function() return 0 end
conky_main()
assert(drawn['/'] and drawn['/home'] and drawn['/mnt/data'] and not drawn['/boot/efi'])
drawn = {}
os.time = function() return 10 end
conky_main()
assert(drawn['/boot/efi'])
drawn, sample = {}, 'disk_count=0\n'
conky_main()
assert(drawn['No mounted local disks'])
'''
        source = 'local WIDGETS = ' + json.dumps(str(ROOT / 'conky/.config/conky/widgets.lua')) + '\n' + script
        subprocess.run(['lua', '-'], input=source, text=True, check=True, capture_output=True)


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
                subprocess.run(['bash', str(BIN / 'polybar-launch')], env=env, check=True, timeout=5)
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
                self.assertEqual(by_monitor['HDMI-1'][0], '' if active else 'pill-l2 lyrics cava mpd pill-r2')
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
                'osd': '#!/bin/sh\n',
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
