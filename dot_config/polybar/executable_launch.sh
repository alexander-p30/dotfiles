killall -q polybar

polybar_procs=$(ps -aux | grep polybar)
if [[ ! -z $polybar_procs ]]; then
  killall -q -s 9 polybar
fi

PRIMARY=$(xrandr --query | grep " connected" | grep "primary" | cut -d" " -f1)
OTHERS=$(xrandr --query | grep " connected" | grep -v "primary" | cut -d" " -f1)

if [ ! -z "${PRIMARY}" ]; then
  MONITOR=$PRIMARY TRAY_POS=right polybar  --reload mybar &

  for m in $OTHERS; do
    MONITOR=$m polybar --reload mybar &
  done
else
  for m in $OTHERS; do
    MONITOR=$m TRAY_POS=right polybar --reload mybar &
  done
fi
