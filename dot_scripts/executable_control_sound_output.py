#!/bin/python3
import subprocess
import sys

ICONS = {"bluez": ""}
DEFAULT_ICON = "蓼"

def show_icon(sink):
    print(get_icon(sink))

def next_sink(current_sink):
    idx = SINKS.index(current_sink)

    if idx >= len(SINKS) - 1:
        idx = 0
    else:
        idx += 1

    sink = SINKS[idx]

    set_sink(sink)
    show_icon(sink)

def set_sink(sink):
    run_cmd(['pactl', 'set-default-sink', sink])

def get_icon(sink):
    for alias, icon in ICONS.items():
        if alias.lower() in sink.lower():
            return icon

    return DEFAULT_ICON


def get_all_sinks():
    sinks = []
    output = run_cmd(['pactl', 'list', 'short', 'sinks'])

    for line in output.split('\n'):
        if line:
            sink = line.split()[1]
            sinks.append(sink.strip())

    return sinks

def get_current_sink():
    return run_cmd(['pactl', 'get-default-sink']).strip()

def run_cmd(args):
    return subprocess.run(args, stdout=subprocess.PIPE).stdout.decode('utf-8')

SINKS = get_all_sinks()

if __name__ == '__main__':
    args = sys.argv

    match args[1]:
        case 'show-current':
            show_icon(get_current_sink())

        case 'next':
            next_sink(get_current_sink())
