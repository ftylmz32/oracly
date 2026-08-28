import subprocess
import time
from pathlib import Path

ADB = r"D:\android\platform-tools\adb.exe"
SERIAL = "1700848656001190"
PKG = "com.example.oracly_new"
OUT = Path(r"c:\Dev\oracly_new\artifacts\true-10-10")


def adb(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([ADB, "-s", SERIAL, *args], capture_output=True)


def png_bytes(data: bytes) -> bytes:
    idx = data.find(b"\x89PNG")
    if idx < 0:
        raise RuntimeError(f"no png header ({len(data)} bytes)")
    return data[idx:]


def shot(name: str) -> None:
    time.sleep(1.8)
    adb("shell", "cmd", "statusbar", "collapse")
    p = adb("exec-out", "screencap", "-p")
    dest = OUT / f"{name}.png"
    dest.write_bytes(png_bytes(p.stdout))
    print("SHOT", dest.name, dest.stat().st_size)


def tap(x: int, y: int) -> None:
    adb("shell", "input", "tap", str(x), str(y))


def main() -> None:
    adb("shell", "svc", "power", "stayon", "true")
    adb("shell", "input", "keyevent", "224")
    adb("shell", "wm", "dismiss-keyguard")
    adb("shell", "am", "start", "-n", f"{PKG}/.MainActivity")
    time.sleep(4)
    shot("10_entry")
    for _ in range(3):
        tap(72, 92)  # Atla
        time.sleep(0.8)
    tap(360, 1460)  # possible bottom Atla / Devam
    time.sleep(1.2)
    tap(72, 92)
    time.sleep(2.5)
    shot("11_home")
    # 3x2 Home grid: OR | Kahve | Rüya / Astroloji | Yıldızname | Premium
    tap(360, 820)
    time.sleep(3)
    shot("12_coffee")
    adb("shell", "input", "keyevent", "4")
    time.sleep(2.2)
    tap(140, 1100)
    time.sleep(3)
    shot("13_astrology")
    adb("shell", "input", "keyevent", "4")
    time.sleep(2.2)
    tap(360, 1100)
    time.sleep(3)
    shot("14_yildizname")


if __name__ == "__main__":
    main()
