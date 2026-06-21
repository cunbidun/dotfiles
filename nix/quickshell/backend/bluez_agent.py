#!/usr/bin/env python3
import json
import os
import socket
import sys
import threading
import time
import uuid

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib


BLUEZ = "org.bluez"
AGENT_MANAGER_PATH = "/org/bluez"
AGENT_MANAGER_IFACE = "org.bluez.AgentManager1"
AGENT_IFACE = "org.bluez.Agent1"
DEVICE_IFACE = "org.bluez.Device1"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
AGENT_PATH = "/com/cunbidun/quickshell/bluez/agent"
CAPABILITY = "KeyboardDisplay"


class PromptBroker:
    def __init__(self):
        self.lock = threading.RLock()
        self.subscribers = set()
        self.pending = {}

    def add_subscriber(self, client):
        with self.lock:
            self.subscribers.add(client)

    def remove_client(self, client):
        with self.lock:
            self.subscribers.discard(client)

    def broadcast(self, message):
        with self.lock:
            clients = list(self.subscribers)
        for client in clients:
            client.send(message)

    def request(self, data, timeout=120):
        token = str(uuid.uuid4())
        event = threading.Event()
        entry = {"event": event, "response": None}
        with self.lock:
            self.pending[token] = entry
        payload = dict(data)
        payload["event"] = "bluetooth.pairing.request"
        payload["token"] = token
        self.broadcast(payload)
        if not event.wait(timeout):
            with self.lock:
                self.pending.pop(token, None)
            raise TimeoutError("pairing prompt timed out")
        response = entry["response"] or {}
        if not response.get("accepted", False):
            raise PermissionError("pairing rejected")
        return response.get("secrets", {}) or {}

    def respond(self, token, accepted, secrets):
        with self.lock:
            entry = self.pending.pop(token, None)
        if not entry:
            return False
        entry["response"] = {"accepted": bool(accepted), "secrets": secrets or {}}
        entry["event"].set()
        return True


class BluezAgent(dbus.service.Object):
    def __init__(self, bus, broker):
        self.bus = bus
        self.broker = broker
        super().__init__(bus, AGENT_PATH)

    @dbus.service.method(AGENT_IFACE, in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method(AGENT_IFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        secrets = self._prompt(device, "pin", fields=["pin"])
        return str(secrets.get("pin", ""))

    @dbus.service.method(AGENT_IFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        secrets = self._prompt(device, "passkey", fields=["passkey"])
        return dbus.UInt32(int(secrets.get("passkey", "0")))

    @dbus.service.method(AGENT_IFACE, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        self._prompt(device, "display-pin", display=str(pincode), fields=[])

    @dbus.service.method(AGENT_IFACE, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        if int(entered) == 0:
            self._prompt(device, "display-passkey", display=f"{int(passkey):06d}", fields=[])

    @dbus.service.method(AGENT_IFACE, in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        self._prompt(device, "confirm", display=f"{int(passkey):06d}", fields=["decision"])

    @dbus.service.method(AGENT_IFACE, in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        self._prompt(device, "authorize", fields=["decision"])

    @dbus.service.method(AGENT_IFACE, in_signature="os", out_signature="")
    def AuthorizeService(self, device, service_uuid):
        self._prompt(device, "authorize-service", display=str(service_uuid), fields=["decision"])

    @dbus.service.method(AGENT_IFACE, in_signature="", out_signature="")
    def Cancel(self):
        self.broker.broadcast({"event": "bluetooth.pairing.cancel"})

    def _prompt(self, device, kind, display="", fields=None):
        info = device_info(self.bus, str(device))
        try:
            return self.broker.request({
                "type": kind,
                "devicePath": str(device),
                "deviceName": info.get("name") or info.get("alias") or info.get("address") or str(device),
                "address": info.get("address", ""),
                "display": display,
                "fields": fields or [],
            })
        except TimeoutError:
            raise dbus.exceptions.DBusException("Prompt timed out", name="org.bluez.Error.Canceled")
        except PermissionError:
            raise dbus.exceptions.DBusException("Prompt rejected", name="org.bluez.Error.Rejected")


class Client:
    def __init__(self, conn, server):
        self.conn = conn
        self.server = server
        self.lock = threading.Lock()
        self.closed = False

    def send(self, message):
        try:
            data = (json.dumps(message, separators=(",", ":")) + "\n").encode()
            with self.lock:
                if not self.closed:
                    self.conn.sendall(data)
        except OSError:
            self.close()

    def close(self):
        with self.lock:
            if self.closed:
                return
            self.closed = True
            try:
                self.conn.close()
            except OSError:
                pass
        self.server.broker.remove_client(self)

    def run(self):
        buf = b""
        try:
            while True:
                chunk = self.conn.recv(4096)
                if not chunk:
                    break
                buf += chunk
                while b"\n" in buf:
                    line, buf = buf.split(b"\n", 1)
                    if line.strip():
                        self.handle(json.loads(line.decode()))
        except Exception as exc:
            self.send({"event": "error", "message": str(exc)})
        finally:
            self.close()

    def handle(self, request):
        method = request.get("method", "")
        request_id = request.get("id")
        params = request.get("params") or {}
        try:
            if method == "subscribe":
                self.server.broker.add_subscriber(self)
                self.send({"id": request_id, "ok": True, "capabilities": ["bluetooth"]})
            elif method == "ping":
                self.send({"id": request_id, "ok": True, "capabilities": ["bluetooth"]})
            elif method == "bluetooth.pair":
                path = params.get("devicePath", "")
                self.server.pair(path)
                self.send({"id": request_id, "ok": True, "started": True})
            elif method == "bluetooth.remove":
                path = params.get("devicePath", "")
                self.server.remove(path)
                self.send({"id": request_id, "ok": True})
            elif method == "bluetooth.cancelPairing":
                path = params.get("devicePath", "")
                self.server.cancel_pairing(path)
                self.send({"id": request_id, "ok": True})
            elif method == "bluetooth.prompt.response":
                token = params.get("token", "")
                accepted = bool(params.get("accepted", False))
                secrets = params.get("secrets") or {}
                ok = self.server.broker.respond(token, accepted, secrets)
                self.send({"id": request_id, "ok": ok})
            else:
                self.send({"id": request_id, "ok": False, "error": "unknown method"})
        except Exception as exc:
            self.send({"id": request_id, "ok": False, "error": str(exc)})


class SocketServer:
    def __init__(self, bus, broker, path):
        self.bus = bus
        self.broker = broker
        self.path = path
        self.sock = None

    def start(self):
        os.makedirs(os.path.dirname(self.path), mode=0o700, exist_ok=True)
        try:
            os.unlink(self.path)
        except FileNotFoundError:
            pass
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.sock.bind(self.path)
        os.chmod(self.path, 0o600)
        self.sock.listen(16)
        threading.Thread(target=self._accept_loop, daemon=True).start()

    def _accept_loop(self):
        while True:
            conn, _ = self.sock.accept()
            client = Client(conn, self)
            threading.Thread(target=client.run, daemon=True).start()

    def pair(self, path):
        validate_device_path(path)
        threading.Thread(target=self._pair_worker, args=(path,), daemon=True).start()

    def _pair_worker(self, path):
        try:
            device = dbus.Interface(self.bus.get_object(BLUEZ, path), DEVICE_IFACE)
            device.Pair(timeout=120)
            self.broker.broadcast({"event": "bluetooth.pair.result", "devicePath": path, "ok": True})
        except Exception as exc:
            self.broker.broadcast({"event": "bluetooth.pair.result", "devicePath": path, "ok": False, "error": str(exc)})

    def remove(self, path):
        validate_device_path(path)
        adapter_path = adapter_for_device_path(path)
        adapter = dbus.Interface(self.bus.get_object(BLUEZ, adapter_path), "org.bluez.Adapter1")
        adapter.RemoveDevice(dbus.ObjectPath(path))

    def cancel_pairing(self, path):
        validate_device_path(path)
        device = dbus.Interface(self.bus.get_object(BLUEZ, path), DEVICE_IFACE)
        device.CancelPairing()


def validate_device_path(path):
    if not isinstance(path, str) or not path.startswith("/org/bluez/hci") or "/dev_" not in path:
        raise ValueError("invalid BlueZ device path")


def adapter_for_device_path(path):
    return path.split("/dev_", 1)[0]


def device_info(bus, path):
    info = {"path": path}
    try:
        props = dbus.Interface(bus.get_object(BLUEZ, path), PROPERTIES_IFACE)
        for key in ("Address", "Name", "Alias"):
            try:
                info[key.lower()] = str(props.Get(DEVICE_IFACE, key))
            except Exception:
                pass
    except Exception:
        pass
    return info


def main():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    socket_path = os.environ.get("QUICKSHELL_BLUEZ_AGENT_SOCKET") or os.path.join(runtime_dir, "quickshell-cunbidun", "bluez-agent.sock")

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    broker = PromptBroker()
    agent = BluezAgent(bus, broker)

    mgr = dbus.Interface(bus.get_object(BLUEZ, AGENT_MANAGER_PATH), AGENT_MANAGER_IFACE)
    mgr.RegisterAgent(dbus.ObjectPath(AGENT_PATH), CAPABILITY)
    try:
        mgr.RequestDefaultAgent(dbus.ObjectPath(AGENT_PATH))
    except Exception:
        pass

    server = SocketServer(bus, broker, socket_path)
    server.start()
    print(f"quickshell-bluez-agent listening on {socket_path}", flush=True)

    loop = GLib.MainLoop()
    try:
        loop.run()
    finally:
        try:
            mgr.UnregisterAgent(dbus.ObjectPath(AGENT_PATH))
        except Exception:
            pass


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as exc:
        print(f"quickshell-bluez-agent error: {exc}", file=sys.stderr, flush=True)
        raise
