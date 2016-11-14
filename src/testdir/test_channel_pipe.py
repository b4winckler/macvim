#!/usr/bin/python
#
# Server that will communicate over stdin/stderr
#
# This requires Python 2.6 or later.

from __future__ import print_function
import sys
import time

if __name__ == "__main__":

    if len(sys.argv) > 1:
        if sys.argv[1].startswith("err"):
            print(sys.argv[1], file=sys.stderr)
            sys.stderr.flush()
        else:
            print(sys.argv[1])
            sys.stdout.flush()
            if sys.argv[1].startswith("quit"):
                sys.exit(0)

    while True:
        typed = sys.stdin.readline()
        if typed.startswith("quit"):
            print("Goodbye!")
            sys.stdout.flush()
            break
        if typed.startswith("echo "):
            print(typed[5:-1])
            sys.stdout.flush()
        if typed.startswith("double "):
            print(typed[7:-1] + "\nAND " + typed[7:-1])
            sys.stdout.flush()
        if typed.startswith("split "):
            print(typed[6:-1], end='')
            sys.stdout.flush()
            time.sleep(0.05)
            print(typed[6:-1], end='')
            sys.stdout.flush()
            time.sleep(0.05)
            print(typed[6:-1])
            sys.stdout.flush()
        if typed.startswith("echoerr "):
            print(typed[8:-1], file=sys.stderr)
            sys.stderr.flush()
        if typed.startswith("doubleerr "):
            print(typed[10:-1] + "\nAND " + typed[10:-1], file=sys.stderr)
            sys.stderr.flush()

