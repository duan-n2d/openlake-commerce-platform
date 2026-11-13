from __future__ import annotations

import argparse
import socket
import time


def wait_for_host(host: str, port: int, timeout_seconds: int) -> None:
    deadline = time.monotonic() + timeout_seconds
    last_error: OSError | None = None
    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, port), timeout=3):
                print(f"{host}:{port} is reachable")
                return
        except OSError as exc:
            last_error = exc
            time.sleep(2)
    raise TimeoutError(f"Timed out waiting for {host}:{port}: {last_error}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", help="Target in host:port format")
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()
    host, raw_port = args.target.rsplit(":", 1)
    wait_for_host(host, int(raw_port), args.timeout)


if __name__ == "__main__":
    main()
