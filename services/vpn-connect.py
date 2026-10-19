"""Authenticate OpenConnect profiles in the desktop session; let NM own the tunnel."""

import json
import shlex
import shutil
import signal
import subprocess
import sys


class Cancelled(Exception):
    pass


child = None
activating = False


def run(args, *, data=None):
    global child
    child = subprocess.Popen(
        args, stdin=subprocess.PIPE if data is not None else subprocess.DEVNULL,
        stdout=subprocess.PIPE, text=True,
    )
    output, _ = child.communicate(data)
    code = child.returncode
    child = None
    if code:
        raise RuntimeError(f"{args[0]} failed (exit {code})")
    return output


def cancel(signum, frame):
    raise Cancelled()


def deactivate(uuid):
    subprocess.run(["nmcli", "--wait", "10", "connection", "down", "uuid", uuid],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def settings(uuid):
    path = json.loads(run([
        "busctl", "--system", "--json=short", "call",
        "org.freedesktop.NetworkManager", "/org/freedesktop/NetworkManager/Settings",
        "org.freedesktop.NetworkManager.Settings", "GetConnectionByUuid", "s", uuid,
    ]))["data"][0]
    return json.loads(run([
        "busctl", "--system", "--json=short", "call",
        "org.freedesktop.NetworkManager", path,
        "org.freedesktop.NetworkManager.Settings.Connection", "GetSettings",
    ]))["data"][0]


def connect(uuid):
    global activating
    vpn = settings(uuid).get("vpn", {})
    if vpn.get("service-type", {}).get("data") != "org.freedesktop.NetworkManager.openconnect":
        activating = True
        run(["nmcli", "connection", "up", "uuid", uuid])
        return

    options = vpn.get("data", {}).get("data", {})
    gateway = options.get("gateway")
    browser = shutil.which("xdg-open")
    if not gateway or not browser:
        raise RuntimeError("Configure a VPN gateway and install xdg-open first")

    command = [
        "openconnect", "--authenticate", "--non-inter",
        f"--external-browser={browser}",
        f"--protocol={options.get('protocol', 'anyconnect')}",
    ]
    for key, flag in {
        "cacert": "cafile", "usercert": "certificate", "privkey": "sslkey",
        "usergroup": "usergroup", "authgroup": "authgroup",
        "useragent": "useragent", "reported_os": "os",
    }.items():
        if options.get(key):
            command.append(f"--{flag}={options[key]}")
    if vpn.get("user-name", {}).get("data"):
        command.append(f"--user={vpn['user-name']['data']}")
    command.append(gateway)

    # Parse OpenConnect's quoted assignments as data, without evaluating shell code.
    auth = dict(word.split("=", 1) for word in shlex.split(run(command)))
    keys = {"COOKIE": "cookie", "CONNECT_URL": "gateway", "FINGERPRINT": "gwcert", "RESOLVE": "resolve"}
    if any(not auth.get(key) for key in keys):
        raise RuntimeError("VPN authentication returned incomplete connection details")
    secrets = "".join(f"vpn.secrets.{name}:{auth[key]}\n" for key, name in keys.items())
    activating = True
    run(["nmcli", "connection", "up", "uuid", uuid, "passwd-file", "/dev/stdin"], data=secrets)


def main():
    global child
    if len(sys.argv) != 2:
        print("Usage: vpn-connect.py CONNECTION_UUID", file=sys.stderr)
        return 2
    uuid = sys.argv[1]
    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    try:
        connect(uuid)
        return 0
    except Cancelled:
        # Stop the browser-auth listener as well as any pending NM activation.
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        if child is not None:
            child.terminate()
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()
            child = None
        if activating:
            deactivate(uuid)
        return 130
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        if activating:
            deactivate(uuid)
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
