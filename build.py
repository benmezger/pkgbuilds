#!/usr/bin/env python3

# Author: Ben Mezger <me@benmezger.nl>
# Created at <2022-08-10 Wed 23:34>

import pathlib
import subprocess
import os


IGNORE = (".git", ".mypy_cache")


def find_pkgs() -> list:
    pkgs = []

    for dir in filter(lambda d: d not in IGNORE, os.listdir(".")):
        if not pathlib.Path(dir).is_dir():
            continue

        _any = filter(lambda x: "pkg.tar.zst" in x, os.listdir(dir))
        if not any(_any):
            pkgs.append(dir)

    return pkgs


def main():
    pkgs = find_pkgs()
    dir = os.getcwd()

    failed = []
    for pkg in pkgs:
        os.chdir(pkg)
        result = subprocess.run(["makepkg", "-f"])

        if result.returncode != 0:
            failed.append(pkg)

        os.chdir(dir)

    for f in failed:
        print(f"'{f}' failed")


if __name__ == "__main__":
    main()