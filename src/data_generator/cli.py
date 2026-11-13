from __future__ import annotations

import argparse

from common.logging import configure_logging
from data_generator.db import CommerceWriter


def main() -> None:
    parser = argparse.ArgumentParser(description="OpenLake Commerce synthetic workload generator")
    subparsers = parser.add_subparsers(dest="command", required=True)

    seed = subparsers.add_parser("seed", help="Insert additional synthetic customers/products")
    seed.add_argument("--customers", type=int, default=25)
    seed.add_argument("--products", type=int, default=15)

    generate = subparsers.add_parser("generate", help="Generate order/payment/shipment/clickstream activity")
    generate.add_argument("--continuous", action="store_true")
    generate.add_argument("--events", type=int, default=10)
    generate.add_argument("--interval-seconds", type=float, default=2.0)

    args = parser.parse_args()
    configure_logging()
    writer = CommerceWriter()

    if args.command == "seed":
        writer.seed_reference_data(customers=args.customers, products=args.products)
    elif args.command == "generate":
        if args.continuous:
            writer.run_continuous(interval_seconds=args.interval_seconds)
        else:
            for _ in range(args.events):
                writer.generate_once()


if __name__ == "__main__":
    main()
