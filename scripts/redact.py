"""Redact secret values from an Infisical CSV report.

Usage: redact.py <input.csv> <output.csv>
"""

import csv
import sys


def main(src_path, dst_path):
    with open(src_path, newline="", encoding="utf-8") as src:
        reader = csv.DictReader(src)
        rows = list(reader)
        fieldnames = reader.fieldnames

    for row in rows:
        secret = row.get("Secret") or ""
        if secret and row.get("Match"):
            row["Match"] = row["Match"].replace(secret, "REDACTED")
        if "Secret" in row:
            row["Secret"] = "REDACTED"

    with open(dst_path, "w", newline="", encoding="utf-8") as dst:
        writer = csv.DictWriter(dst, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
