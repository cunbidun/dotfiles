#!/usr/bin/env python3
"""Minimal BlueZ pairing agent for the Quickshell UI.

This is the one piece Quickshell's QML services cannot provide on their own:
Quickshell 0.3 has no Bluetooth "agent mode" (it is listed as future work), so
device pairing that needs a PIN/passkey/confirmation requires a registered
org.bluez.Agent1. Everything else - listing devices, connect/disconnect/pair/
forget, adapter state, Wi-Fi - is handled natively by Quickshell.Bluetooth and
Quickshell.Networking, so it lives in QML, not here.

The agent forwards each pairing request to the UI over a Unix socket and waits
for the user's response. Nothing about a specific machine is hardcoded: the bus,
adapter and devices are all discovered at runtime and the socket path comes from
the environment.
"""
import json
import os
import socket
import sys
import threading
import uuid

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

BLUEZ_SERVICE = "org.bluez"
AGENT_MANAGER_PATH = "/org/bluez"
AGENT_MANAGER_IFACE = "org.bluez.AgentManager1"
AGENT_IFACE = "org.bluez.Agent1"
DEVICE_IFACE = "org.bluez.Device1"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"

AGENT_OBJECT_PATH = "/org/quickshell/bluez/agent"
AGENT_CAPABILITY = "KeyboardDisplay"

EVENT_PAIRING_REQUEST = "bluetooth.pairing.request"
EVENT_PAIRING_CANCEL = "bluetooth.pairing.cancel"
METHOD_SUBSCRIBE = "subscribe"
METHOD_PING = "ping"
METHOD_PROMPT_RESPONSE = "bluetooth.prompt.response"

PROMPT_TIMEOUT_SECONDS = 120


class PromptBroker:
    """Relays pairing prompts to subscribed UI clients and awaits a response."""

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

    def request(self, data):
        token = str(uuid.uuid4())
        event = threading.Event()
        entry = {"event": event, "response": None}
        with self.lock:
            self.pending[token] = entry
        payload = dict(data)
        payload["event"] = EVENT_PAIRING_REQUEST
        payload["token"] = token
        self.broadcast(payload)
        if not event.wait(PROMPT_TIMEOUT_SECONDS):
            with self.lock:
                self.pending.pop(token, None)
            raise TimeoutError("pairing prompt timed out")
        response = entry["response"] or {}
        if not response.get("accepted", False):
            raise PermissionError("pairing prompt rejected")
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
        super().__init__(bus, AGENT_OBJECT_PATH)

    @dbus.service.method(AGENT_IFACE, in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method(AGENT_IFACE, in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        return str(self._prompt(device, "pin", fields=["pin"]).get("pin", ""))

    @dbus.service.method(AGENT_IFACE, in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        return dbus.UInt32(int(self._prompt(device, "passkey", fields=["passkey"]).get("passkey", "0")))

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
        self.broker.broadcast({"event": EVENT_PAIRING_CANCEL})

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
    def __init__(self, conn, broker):
        self.conn = conn
        self.broker = broker
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
        self.broker.remove_client(self)

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
        if method in (METHOD_SUBSCRIBE, METHOD_PING):
            if method == METHOD_SUBSCRIBE:
                self.broker.add_subscriber(self)
            self.send({"id": request_id, "ok": True, "capabilities": ["bluetooth-agent"]})
        elif method == METHOD_PROMPT_RESPONSE:
            ok = self.broker.respond(
                params.get("token", ""),
                bool(params.get("accepted", False)),
                params.get("secrets") or {},
            )
            self.send({"id": request_id, "ok": ok})
        else:
            self.send({"id": request_id, "ok": False, "error": "unknown method"})


class SocketServer:
    def __init__(self, broker, path):
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
            threading.Thread(target=Client(conn, self.broker).run, daemon=True).start()


def device_info(bus, path):
    info = {"path": path}
    try:
        props = dbus.Interface(bus.get_object(BLUEZ_SERVICE, path), PROPERTIES_IFACE)
        for key in ("Address", "Name", "Alias"):
            try:
                info[key.lower()] = str(props.Get(DEVICE_IFACE, key))
            except Exception:
                pass
    except Exception:
        pass
    return info


def default_socket_path():
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    return os.path.join(runtime_dir, "quickshell-cunbidun", "bluez-agent.sock")


def main():
    socket_path = os.environ.get("QUICKSHELL_BLUEZ_AGENT_SOCKET") or default_socket_path()

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    broker = PromptBroker()
    BluezAgent(bus, broker)

    manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE, AGENT_MANAGER_PATH), AGENT_MANAGER_IFACE)
    manager.RegisterAgent(dbus.ObjectPath(AGENT_OBJECT_PATH), AGENT_CAPABILITY)
    try:
        manager.RequestDefaultAgent(dbus.ObjectPath(AGENT_OBJECT_PATH))
    except Exception:
        pass

    SocketServer(broker, socket_path).start()
    print(f"quickshell-bluez-agent listening on {socket_path}", flush=True)

    loop = GLib.MainLoop()
    try:
        loop.run()
    finally:
        try:
            manager.UnregisterAgent(dbus.ObjectPath(AGENT_OBJECT_PATH))
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
