from __future__ import annotations

import argparse
import subprocess
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--suite", default="critical")
    args = parser.parse_args()
    checkpoint = f"commerce_{args.suite}_checkpoint"
    command = ["great_expectations", "checkpoint", "run", checkpoint]
    print(f"Running Great Expectations checkpoint: {checkpoint}")
    try:
        return subprocess.call(command)
    except FileNotFoundError:
        print("Great Expectations is not installed. Install with `pip install -e .[quality]`.")
        return 127


if __name__ == "__main__":
    sys.exit(main())
