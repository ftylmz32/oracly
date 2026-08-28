import subprocess
import time
from pathlib import Path

ADB = r"D:\android\platform-tools\adb.exe"
SERIAL = "1700848656001190"
OUT = Path(r"c:\Dev\oracly_new\artifacts\true-10-10")


def adb(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([ADB, "-s", SERIAL, *args], capture_output=True)


def shot(name: str) -> None:
    dest = OUT / f"{name}.png"
    for _ in range(8):
        adb("shell", "cmd", "statusbar", "collapse")
        p = adb("exec-out", "screencap", "-p")
        idx = p.stdout.find(b"\x89PNG")
        if idx >= 0 and len(p.stdout) > 20000:
            dest.write_bytes(p.stdout[idx:])
            print("SHOT", dest.name, dest.stat().st_size)
            return
        time.sleep(1.2)
        adb("devices")
    raise RuntimeError(f"shot failed {name}")


def tap(x: int, y: int) -> None:
    adb("shell", "input", "tap", str(x), str(y))


def main() -> None:
    adb("shell", "svc", "power", "stayon", "true")
    adb("shell", "input", "keyevent", "224")
    # Assume we may be on Home. Open Kahve (center-top grid cell).
    tap(360, 820)
    time.sleep(3)
    shot("12_coffee")
    adb("shell", "input", "keyevent", "4")
    time.sleep(2)
    tap(140, 1100)
    time.sleep(3)
    shot("13_astrology")
    adb("shell", "input", "keyevent", "4")
    time.sleep(2)
    tap(360, 1100)
    time.sleep(3)
    shot("14_yildizname")


if __name__ == "__main__":
    main()
