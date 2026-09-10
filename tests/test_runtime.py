"""Exercise the real Bashio, vclient and Mosquitto binaries in a disposable image.

Run with tests/Dockerfile; no Home Assistant or heating hardware is contacted.
"""
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import socketserver
import subprocess
import tempfile
import threading
import time
import unittest


def wait_for(predicate, seconds=12):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.1)
    raise AssertionError("Condition did not become true before timeout")


class Boiler(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self):
        super().__init__(("127.0.0.1", 3002), BoilerConnection)
        self.stalled = False
        self.value = "21.5 Grad Celsius"
        self.commands = []


class BoilerConnection(socketserver.StreamRequestHandler):
    def handle(self):
        try:
            self.wfile.write(b"vctrld>")
            for line in self.rfile:
                command = line.decode().strip()
                self.server.commands.append(command)
                if command == "quit":
                    self.wfile.write(b"good bye!\n")
                    return
                while self.server.stalled:
                    # A peer making partial progress defeats vclient's per-byte alarm.
                    self.wfile.write(b" ")
                    time.sleep(0.1)
                self.wfile.write((self.server.value + "\nvctrld>").encode())
        except (BrokenPipeError, ConnectionResetError):
            pass


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.processes = []
        self.logs = []
        self.broker = None
        self.boiler = Boiler()
        self.addCleanup(self.tearDown)
        threading.Thread(target=self.boiler.serve_forever, daemon=True).start()
        self.options = {
            "tty": "/dev/null", "device_id": "2098", "debug": False,
            "refresh": 1, "command_timeout": 1,
            "vcontrol_host": "127.0.0.1", "vcontrol_port": 3002,
            "mqtt_host": "127.0.0.1", "mqtt_port": 1883,
            "mqtt_topic": "openv", "commands": ["getTempA:FLOAT", "getError0:STRING"],
        }
        self.cache = Path(self.tmp.name, "cache")
        self.cache.mkdir()
        os.environ["CACHE_DIR"] = str(self.cache)
        Path("/data").mkdir(exist_ok=True)
        shutil.rmtree("/run/vcontrold", ignore_errors=True)
        self.write_options()
        # Only generate runtime files: use the documented remote-daemon branch.
        options = dict(self.options, vcontrol_host="boiler.test")
        Path("/data/options.json").write_text(json.dumps(options))
        (self.cache / "addons.self.options.config.cache").write_text(json.dumps(options))
        result = self.run_script("vcontrold/run", env={"TAIL_BIN": "/bin/true"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.write_options()

    def tearDown(self):
        if getattr(self, "cleaned", False):
            return
        self.cleaned = True
        self.boiler.stalled = False
        for process in reversed(self.processes):
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
        self.boiler.shutdown()
        self.boiler.server_close()
        for log in self.logs:
            log.close()
        self.tmp.cleanup()

    def write_options(self):
        Path("/data/options.json").write_text(json.dumps(self.options))
        (self.cache / "addons.self.options.config.cache").write_text(json.dumps(self.options))

    def run_script(self, name, *args, env=None, check=False):
        return subprocess.run(
            ["bashio", "/etc/services.d/" + name, *args],
            env=dict(os.environ, **(env or {})), capture_output=True, text=True,
            timeout=10, check=check,
        )

    def start(self, args, name):
        path = Path(self.tmp.name, name + ".log")
        log = path.open("w")
        self.logs.append(log)
        process = subprocess.Popen(args, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        self.processes.append(process)
        return process, path

    def start_broker(self):
        self.broker, _ = self.start(["mosquitto", "-p", "1883"], "broker")
        def ready():
            try:
                with socket.create_connection(("127.0.0.1", 1883), timeout=0.1):
                    return True
            except OSError:
                return False
        wait_for(ready)

    def read_message(self, topic="openv/getTempA"):
        result = subprocess.run(
            ["mosquitto_sub", "-h", "127.0.0.1", "-t", topic, "-C", "1", "-W", "8"],
            capture_output=True, text=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.rstrip("\n")

    def test_publisher_reports_broker_failure_and_recovers(self):
        process, log = self.start(["bashio", "/etc/services.d/vclient_pub/run"], "pub")
        wait_for(lambda: "failed" in log.read_text().lower())
        self.assertIsNone(process.poll(), log.read_text())
        self.start_broker()
        self.assertEqual(self.read_message(), "21.500000")

    def test_stalled_read_times_out_and_next_poll_recovers(self):
        self.start_broker()
        self.boiler.stalled = True
        process, log = self.start(["bashio", "/etc/services.d/vclient_pub/run"], "pub")
        wait_for(lambda: "timed out" in log.read_text().lower(), seconds=6)
        self.boiler.stalled = False
        self.assertIsNone(process.poll(), log.read_text())
        self.assertEqual(self.read_message(), "21.500000")

    def test_string_payload_is_data_and_cannot_execute_shell(self):
        self.start_broker()
        marker = Path(self.tmp.name, "executed")
        self.boiler.value = f'Fault "sensor" $(touch {marker}) `printf injected` \\ path'
        self.start(["bashio", "/etc/services.d/vclient_pub/run"], "pub")
        self.assertEqual(self.read_message("openv/getError0"), self.boiler.value)
        self.assertFalse(marker.exists(), "Boiler data was executed as shell code")

    def test_subscriber_survives_initial_broker_unavailability(self):
        process, log = self.start(["bashio", "/etc/services.d/vclient_sub/run"], "sub")
        wait_for(lambda: "refused" in log.read_text().lower())
        time.sleep(0.3)
        self.assertIsNone(process.poll(), log.read_text())
        self.start_broker()
        def command_received():
            subprocess.run(["mosquitto_pub", "-t", "openv/setTempWWsoll", "-m", "45"], check=True)
            return "setTempWWsoll 45" in self.boiler.commands
        wait_for(command_received)

    def test_transient_service_failure_does_not_halt_container(self):
        for service in ("vcontrold", "vclient_pub", "vclient_sub"):
            with self.subTest(service=service):
                result = self.run_script(service + "/finish", "1", "0")
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_retained_setter_is_not_replayed(self):
        self.start_broker()
        subprocess.run(["mosquitto_pub", "-r", "-t", "openv/setTempWWsoll", "-m", "60"], check=True)
        self.start(["bashio", "/etc/services.d/vclient_sub/run"], "sub")
        time.sleep(2)
        self.assertNotIn("setTempWWsoll 60", self.boiler.commands)

    def test_multiline_setter_cannot_inject_another_command(self):
        self.start_broker()
        self.start(["bashio", "/etc/services.d/vclient_sub/run"], "sub")
        time.sleep(1)
        subprocess.run([
            "mosquitto_pub", "-t", "openv/setTempWWsoll",
            "-m", "45\nopenv/setTempWWsoll 80",
        ], check=True)
        time.sleep(1)
        self.assertEqual(self.boiler.commands, [], "Malformed payload reached the boiler")

    def test_oversized_setter_is_not_sent_to_vclient(self):
        self.start_broker()
        self.start(["bashio", "/etc/services.d/vclient_sub/run"], "sub")
        time.sleep(1)
        subprocess.run(["mosquitto_pub", "-t", "openv/setTempWWsoll", "-m", "9" * 512], check=True)
        time.sleep(1)
        self.assertEqual(self.boiler.commands, [])

    def test_boiler_error_is_not_reported_as_successful_setter(self):
        self.start_broker()
        self.boiler.value = "ERR: command unknown"
        _, log = self.start(["bashio", "/etc/services.d/vclient_sub/run"], "sub")
        time.sleep(1)
        subprocess.run(["mosquitto_pub", "-t", "openv/setUnknown", "-m", "1"], check=True)
        wait_for(lambda: "Failed to execute" in log.read_text())
        self.assertNotIn("executed successfully", log.read_text())

    def test_broker_restart_resumes_values(self):
        self.start_broker()
        process, log = self.start(["bashio", "/etc/services.d/vclient_pub/run"], "pub")
        self.assertEqual(self.read_message(), "21.500000")
        self.broker.terminate()
        self.broker.wait(timeout=3)
        wait_for(lambda: "publication failed" in log.read_text().lower())
        self.boiler.value = "23.5 Grad Celsius"
        self.start_broker()
        self.assertEqual(self.read_message(), "23.500000")
        self.assertIsNone(process.poll(), log.read_text())

    def test_invalid_first_poll_command_does_not_discard_valid_commands(self):
        self.options["commands"] = ["bad command:FLOAT", "getTempA:FLOAT"]
        self.options["vcontrol_host"] = "boiler.test"
        self.write_options()
        result = self.run_script("vcontrold/run", env={"TAIL_BIN": "/bin/true"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(Path("/run/vcontrold/1_mqtt_commands.txt").read_text(), "getTempA\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
