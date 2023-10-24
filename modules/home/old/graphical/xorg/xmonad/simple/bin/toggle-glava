#!/usr/bin/env bash

get_pid() {
    ps -ax | grep "$1" | grep -v grep | awk '{print $1}' | tr "\n" " "
}

spawn_glava() {
    res=$(xrandr | grep "*+|**" | awk '{print $1}')
    if [[ $res == "1920x1080" ]]; then
        glava -e rc-radial.glsl -m radial -r 'setgeometry 1040 0 800 800' & disown
        glava -e rc-graph.glsl -m graph -r 'setgeometry 0 780 1920 300' & disown
    else
        glava -e rc-graph.glsl -m graph -r 'setgeometry 0 1860 3840 300' & disown
        glava -e rc-radial.glsl -m radial -r 'setgeometry 2600 420 800 800' & disown
    fi
}

toggle_glava () {
    pids=$(get_pid "glava-unwrapped")
    kill $pids || spawn_glava
}

restart_glava () {
    pids=$(get_pid "glava-unwrapped")
    kill $pids || true
    spawn_glava
}

if [[ $1 == "toggle" ]]; then
    toggle_glava
elif [[ $1 == "restart" ]]; then
    restart_glava
fi
