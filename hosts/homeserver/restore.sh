# homeserver-restore: list, verify and restore the restic snapshots of Home
# Assistant and Paperless taken by services.restic.backups (see
# docs/backup-restore.org). RESTIC_REPOSITORY_FILE and RESTIC_PASSWORD_FILE
# are set by the Nix wrapper.

set -o errtrace

usage() {
  cat >&2 <<'EOF'
Usage: homeserver-restore <hass|paperless> <action> [ARG] [--yes]

  list              show the snapshots that contain the service's data
  verify [SNAP]     restore SNAP (default: latest) into a scratch directory,
                    sanity-check it and delete it again; changes nothing
  restore [SNAP]    replace the live data with SNAP (default: latest); the
                    current data is kept next to it as *.pre-restore-<stamp>
  rollback STAMP    undo the restore that printed STAMP, putting the
                    *.pre-restore-STAMP data back
  --yes             do not ask for confirmation before restoring or rolling back
EOF
  exit 2
}

fail() {
  echo "error: $*" >&2
  exit 1
}

[ "$(id -u)" = 0 ] || fail "run as root (sudo homeserver-restore ...)"
[ $# -ge 2 ] || usage
service=$1
action=$2
shift 2

snapshot=latest
yes=0
for arg in "$@"; do
  case $arg in
    --yes) yes=1 ;;
    -*) usage ;;
    *) snapshot=$arg ;;
  esac
done

stamp=$(date +%Y%m%d-%H%M%S)
case $service in
  hass)
    path=/var/lib/hass
    # Same filesystem as the live data, so the swap is a rename
    scratch=/var/lib/hass-restore-$stamp
    ;;
  paperless)
    path=/var/lib/paperless/export
    # Inside the data dir, so the paperless user can read it for the import
    scratch=/var/lib/paperless/restore-$stamp
    ;;
  *) usage ;;
esac

r() {
  restic --cache-dir /var/cache/homeserver-restore "$@"
}

# "<short id> <time>" of the snapshot that SNAPSHOT resolves to
describe() {
  r snapshots --json --path "$path" "$snapshot" |
    jq -er '.[-1] // empty | "\(.short_id) \(.time | split(".")[0])"' ||
    fail "no snapshot '$snapshot' containing $path"
}

fetch() {
  echo "Restoring $path from snapshot $info into $scratch"
  mkdir -p "$scratch"
  r restore "$snapshot" --path "$path" --include "$path" --target "$scratch"
}

check_hass() {
  local d=$scratch/var/lib/hass db result
  [ -f "$d/.storage/core.config_entries" ] ||
    fail "snapshot has no .storage/core.config_entries"
  for db in home-assistant_v2.db zigbee.db; do
    [ -f "$d/$db" ] || fail "snapshot has no $db"
    result=$(sqlite3 "$d/$db" 'PRAGMA quick_check;')
    [ "$result" = ok ] || fail "$db: $result"
    echo "  $db: integrity ok"
  done
  echo "  $(find "$d" -type f | wc -l) files, $(du -sh "$d" | cut -f1)"
}

check_paperless() {
  local d=$scratch/var/lib/paperless/export missing
  [ -f "$d/manifest.json" ] || fail "snapshot has no manifest.json"
  # Every file the manifest references must be in the export
  missing=$(
    jq -r '.[] | select(.model == "documents.document")
      | .__exported_file_name__, .__exported_archive_name__ // empty' \
      "$d/manifest.json" |
      while IFS= read -r f; do
        [ -f "$d/$f" ] || echo "$f"
      done
  )
  [ -z "$missing" ] || fail "files missing from the export:"$'\n'"$missing"
  echo "  $(jq '[.[] | select(.model == "documents.document")] | length' \
    "$d/manifest.json") documents, all files present, $(du -sh "$d" | cut -f1)"
}

# confirm WHAT WORD: ask before doing WHAT unless --yes was given
confirm() {
  [ "$yes" = 1 ] && return
  echo "This $1."
  read -r -p "Type '$2' to continue: " answer
  [ "$answer" = "$2" ] || fail "aborted"
}

paperless_units=(paperless-scheduler.service paperless-web.service
  paperless-consumer.service paperless-task-queue.service)

# Replace the paperless database with an empty one owned by paperless
recreate_paperless_db() {
  runuser -u postgres -- dropdb paperless
  runuser -u postgres -- createdb -O paperless paperless
}

restore_hass() {
  local old=/var/lib/hass.pre-restore-$stamp
  trap 'echo "restore failed; the previous data is in $old" >&2' ERR
  systemctl stop home-assistant.service
  mv /var/lib/hass "$old"
  mv "$scratch/var/lib/hass" /var/lib/hass
  chown -R hass:hass /var/lib/hass
  rm -rf "$scratch"
  systemctl start home-assistant.service
  echo "Home Assistant restored from $info; previous data: $old"
  echo "To undo: homeserver-restore hass rollback $stamp"
}

restore_paperless() {
  local dir=/var/lib/paperless
  trap 'echo "restore failed; the previous data is in $dir/*.pre-restore-$stamp" >&2' ERR

  # Nothing may write to the database or media while they are swapped
  systemctl stop paperless-exporter.timer "${paperless_units[@]}"

  # The importer needs an empty database and empty document folders
  runuser -u postgres -- pg_dump paperless >"$dir/db.pre-restore-$stamp.sql"
  mv "$dir/media" "$dir/media.pre-restore-$stamp"
  [ ! -e "$dir/index" ] || mv "$dir/index" "$dir/index.pre-restore-$stamp"
  install -d -o paperless -g paperless "$dir/media"
  recreate_paperless_db

  paperless-manage migrate
  chown -R paperless:paperless "$scratch"
  paperless-manage document_importer "$scratch/var/lib/paperless/export" --no-progress-bar
  rm -rf "$scratch"

  # Re-apply the NixOS-managed admin password on the next scheduler start
  rm -f "$dir/superuser-state"
  systemctl start paperless-scheduler.service paperless-exporter.timer
  echo "Paperless restored from $info; previous data: $dir/{media,index}.pre-restore-$stamp, $dir/db.pre-restore-$stamp.sql"
  echo "To undo: homeserver-restore paperless rollback $stamp"
}

# The data a rollback replaces is kept as *.rolled-back-<now>
rollback_hass() {
  local from=$1 old=/var/lib/hass.pre-restore-$1
  [ -d "$old" ] || fail "no $old"
  confirm "puts $old back as /var/lib/hass" rollback
  systemctl stop home-assistant.service
  mv /var/lib/hass "/var/lib/hass.rolled-back-$stamp"
  mv "$old" /var/lib/hass
  systemctl start home-assistant.service
  echo "Home Assistant rolled back to the data from before restore $from"
}

rollback_paperless() {
  local from=$1 dir=/var/lib/paperless
  local dump=$dir/db.pre-restore-$1.sql
  [ -f "$dump" ] && [ -d "$dir/media.pre-restore-$from" ] ||
    fail "no $dump or $dir/media.pre-restore-$from"
  confirm "puts the Paperless database and media from before restore $from back" rollback

  systemctl stop paperless-exporter.timer "${paperless_units[@]}"
  recreate_paperless_db
  runuser -u postgres -- psql --quiet -v ON_ERROR_STOP=1 -d paperless <"$dump" >/dev/null
  mv "$dir/media" "$dir/media.rolled-back-$stamp"
  mv "$dir/media.pre-restore-$from" "$dir/media"
  if [ -d "$dir/index.pre-restore-$from" ]; then
    [ ! -e "$dir/index" ] || mv "$dir/index" "$dir/index.rolled-back-$stamp"
    mv "$dir/index.pre-restore-$from" "$dir/index"
  fi
  rm -f "$dir/superuser-state"
  systemctl start paperless-scheduler.service paperless-exporter.timer
  echo "Paperless rolled back to the data from before restore $from"
}

case $action in
  list)
    r snapshots --path "$path"
    ;;
  verify)
    info=$(describe)
    trap 'rm -rf "$scratch"' EXIT
    fetch
    echo "Checking snapshot $info:"
    "check_$service"
    echo "Snapshot $info of $service is restorable."
    ;;
  restore)
    info=$(describe)
    confirm "replaces the live $service data with snapshot $info" restore
    fetch
    echo "Checking snapshot $info:"
    "check_$service"
    "restore_$service"
    ;;
  rollback)
    [ "$snapshot" != latest ] || usage
    "rollback_$service" "$snapshot"
    ;;
  *) usage ;;
esac
