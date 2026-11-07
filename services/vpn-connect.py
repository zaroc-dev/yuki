"""Activate a NetworkManager VPN profile from the shell.

OpenConnect profiles authenticate in the desktop session (browser login) and
hand NM the cookie. Profiles that don't store their password (password-flags
NOT_SAVED, what `nmcli --ask` prompts for) exit with NEEDS_SECRET until the
shell runs this again with --secret-stdin and the password on stdin.
"""

import json
import shlex
import shutil
import signal
import subprocess
import sys


NEEDS_SECRET = 3
# NM secret flag: ask every time, never stored.
NOT_SAVED = 2


class Cancelled(Exception):
    pass


class NeedsSecret(Exception):
    pass


child = None
activating = False


def run(args, *, data=None):
    global child
    child = subprocess.Popen(
        args, stdin=subprocess.PIPE if data is not None else subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    output, errors = child.communicate(data)
    code = child.returncode
    child = None
    if code:
        if "Secrets were required" in errors:
            raise NeedsSecret()
        # nmcli prints warnings first; the "Error:" line is the useful one.
        lines = errors.strip().splitlines()
        line = next((l for l in lines if l.startswith("Error:")), lines[-1] if lines else "")
        line = line.removeprefix("Error:").strip().removeprefix("Connection activation failed:").strip()
        raise RuntimeError(line or f"{args[0]} failed (exit {code})")
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


# The password secret's name per VPN plugin, and which OpenVPN modes use it.
SECRET_KEYS = {"vpnc": "Xauth password"}
OPENVPN_PASSWORD_MODES = {"password", "password-tls"}


def password_key(service, options):
    """The vpn.secrets key the user has to type in, or None."""
    plugin = service.rsplit(".", 1)[-1]
    if plugin == "openvpn" and options.get("connection-type", "tls") not in OPENVPN_PASSWORD_MODES:
        return None
    key = SECRET_KEYS.get(plugin, "password")
    try:
        flags = int(options.get(f"{key}-flags", "0"))
    except ValueError:
        return None
    return key if flags & NOT_SAVED else None


def connect(uuid, secret):
    global activating
    vpn = settings(uuid).get("vpn", {})
    service = vpn.get("service-type", {}).get("data", "")
    if service != "org.freedesktop.NetworkManager.openconnect":
        options = vpn.get("data", {}).get("data", {})
        key = password_key(service, options)
        if key is not None and secret is None:
            raise NeedsSecret()
        activating = True
        if key is None:
            run(["nmcli", "connection", "up", "uuid", uuid])
            return
        # passwd-file: one "vpn.secrets.<key>:<value>" per line, read from stdin
        # so the password never shows up in a command line.
        run(["nmcli", "connection", "up", "uuid", uuid, "passwd-file", "/dev/stdin"],
            data=f"vpn.secrets.{key}:{secret}\n")
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
    args = sys.argv[1:]
    secret = None
    if "--secret-stdin" in args:
        args.remove("--secret-stdin")
        secret = sys.stdin.readline().rstrip("\n")
    if len(args) != 1:
        print("Usage: vpn-connect.py CONNECTION_UUID [--secret-stdin]", file=sys.stderr)
        return 2
    uuid = args[0]
    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    try:
        connect(uuid, secret)
        return 0
    except NeedsSecret:
        if activating:
            deactivate(uuid)
        print("Error: This VPN needs your password", file=sys.stderr)
        return NEEDS_SECRET
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
