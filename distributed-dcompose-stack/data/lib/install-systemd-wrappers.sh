cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo $(pwd)
. lib/util.sh
. .env

if [ "$(id -un)" == "root" ] || id -Gn | grep -qe '\<sudo\>'; then
  BASE=/etc/systemd/system
  SYSTEMCTL_OPTS=()
else
  BASE=$HOME/.config/systemd/user
  mkdir -p $BASE
  SYSTEMCTL_OPTS=(--user)
  export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}
fi

echo "==> Copying templates"
copy_template $BASE/radar-output.service lib/systemd/radar-output.service.template
copy_template $BASE/radar-output.timer lib/systemd/radar-output.timer.template

echo "==> Inlining variables"

inline_variable 'WorkingDirectory=' "$PWD" $BASE/radar-output.service
inline_variable 'ExecStart=' "$PWD/bin/hdfs-restructure-safe /topicAndroidNew ${RESTRUCTURE_OUTPUT_DIR:-output}" $BASE/radar-output.service

echo "==> Reloading systemd"
systemctl "${SYSTEMCTL_OPTS[@]}" daemon-reload
systemctl "${SYSTEMCTL_OPTS[@]}" enable radar-output.timer
systemctl "${SYSTEMCTL_OPTS[@]}" start radar-output.timer
