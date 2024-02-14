#!/usr/bin/env python

import json
import os
import socket
import subprocess

last_ws = -1


def compute_data(ws_numer: int):
    minimize_ws_name = f"special:minimized_{ws_numer}"

    p = subprocess.run(
        "hyprctl clients -j",
        shell=True,
        check=True,
        stdout=subprocess.PIPE,
    )

    output = p.stdout.decode()
    clients = json.loads(output)

    count_minimized = 0
    name_list = []

    for client in clients:
        if client.get("workspace", {}).get("name", "") == minimize_ws_name:
            if not client["class"]:
                continue
            count_minimized += 1
            data = f"{count_minimized}. {client['class'].split('.')[-1]}: {client['title']}"
            data = (data[:50] + "...") if len(data) > 50 else data
            name_list.append(data)

    data = {
        "text": f"{count_minimized}",
        "class": "minimized",
        "tooltip": "\n".join(name_list),
    }
    print(f"Updating file to {json.dumps(data)}")
    with open("/tmp/waybar_minimized", "w+") as f:
        json.dump(data, f)

    subprocess.run(["pkill", "-SIGRTMIN+17", "waybar"])


def handle_received_data(line):
    event = line.split(">>")[0]
    if event == "workspace":
        workspace = line.split(">>")[-1]
        try:
            ws_numer = int(workspace)
            global last_ws
            last_ws = ws_numer
        except Exception:
            print("Workspace is not a number")
            return

    if event in ["workspace", "openwindow", "closewindow", "movewindow"]:
        print(f"Got event {event}. Updating count")
        compute_data(last_ws)


def main():
    print("Starting minimized daemon for hyprland")
    p = subprocess.run(
        "hyprctl activeworkspace -j",
        shell=True,
        check=True,
        stdout=subprocess.PIPE,
    )
    output = p.stdout.decode()
    workspace = json.loads(output)["id"]
    global last_ws
    last_ws = workspace
    compute_data(workspace)

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    his = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    s.connect(f"/tmp/hypr/{his}/.socket2.sock")

    try:
        while True:
            data = s.recv(1024)
            if not data:
                break  # Connection closed by the server
            data = data.decode("utf-8")
            for line in data.split("\n"):
                handle_received_data(line)
    finally:
        s.close()


if __name__ == "__main__":
    main()
