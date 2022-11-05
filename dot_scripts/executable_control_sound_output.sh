#!/bin/bash

SINKS=$(pactl list short sinks | awk -v OFS='\t' '{print $2}')
SINK_KEYWORDS=( "G533" "bluez" )
SINK_ICONS=( "" "" "蓼")
SINK_KEYWORD_COUNT=${#SINK_KEYWORDS[@]}

CURRENT_SINK=$(pactl get-default-sink)

NEW_SINK_KEYWORD=""
NEW_SINK_KEYWORD_IDX=""
CURRENT_SINK_KEYWORD_IDX=""
for sink in "${!SINK_KEYWORDS[@]}" ; do
  sink_name=${SINK_KEYWORDS[$sink]}
  if [[ "$CURRENT_SINK" == *"$sink_name"* ]]; then
    CURRENT_SINK_KEYWORD_IDX=$sink
    NEW_SINK_KEYWORD_IDX=$(expr $sink + 1)
    break
  fi
done

if [[ "$1" == "show-current" ]]; then
  if [[ -z $CURRENT_SINK_KEYWORD_IDX ]]; then
    CURRENT_SINK_KEYWORD_IDX=$SINK_KEYWORD_COUNT
  fi
  echo ${SINK_ICONS[$CURRENT_SINK_KEYWORD_IDX]}
elif [[ "$1" == "next-output" ]]; then
  NEW_SINK=""
  # If its the default sink keyword
  if [[ -z $NEW_SINK_KEYWORD_IDX ]]; then
    NEW_SINK_KEYWORD_IDX=0
  fi

  # If it's the last sink keyword
  if [ "$NEW_SINK_KEYWORD_IDX" -eq $SINK_KEYWORD_COUNT ]; then
    NEW_SINK_KEYWORD="default"
    NEW_SINK=$(grep -Ev "$(echo ${SINK_KEYWORDS[@]}|tr " " "|")" <<< "$SINKS" | head -n 1)
  else
    NEW_SINK_KEYWORD=${SINK_KEYWORDS[$NEW_SINK_KEYWORD_IDX]}
    NEW_SINK=$(grep $NEW_SINK_KEYWORD <<< $SINKS)
  fi

  if [[ -z $NEW_SINK ]]; then
    NEW_SINK_KEYWORD="default"
    NEW_SINK_KEYWORD_IDX=$SINK_KEYWORD_COUNT
    NEW_SINK=$(grep -Ev "$(echo ${SINK_KEYWORDS[@]}|tr " " "|")" <<< "$SINKS" | head -n 1)
  fi

  pactl set-default-sink $NEW_SINK
  polybar-msg action "#sound-output.hook.0"
  echo ${SINK_ICONS[$NEW_SINK_KEYWORD_IDX]}
elif [[ "$1" == "update-polybar" ]]; then
  if [[ -z $CURRENT_SINK_KEYWORD_IDX ]]; then
    CURRENT_SINK_KEYWORD_IDX=$SINK_KEYWORD_COUNT
  fi
  polybar-msg action "#sound-output.hook.0"
  echo ${SINK_ICONS[$CURRENT_SINK_KEYWORD_IDX]}
else
  echo "Invalid action"
fi
