# The Pi 4's onboard BCM43455 talks to the SoC over SDIO and can wedge when
# waking from power-save ("brcmf_sdio_bus_sleep ... -110", then "failed
# backplane access over SDIO, halting operation"). The driver never recovers on
# its own, and with no ethernet cable the box is unreachable until power-cycled.
#
# Every minute, ping the default gateway. After repeated failures reload
# brcmfmac, then reboot — but only if the kernel logged brcmfmac SDIO
# errors recently, so a router outage doesn't cause a reboot loop.
{ pkgs, ... }:
{
  systemd.services.wifi-watchdog = {
    description = "Recover wedged brcmfmac Wi-Fi";
    path = with pkgs; [
      coreutils
      gnugrep
      iproute2
      iputils
      kmod
      systemd
    ];
    script = ''
      STATE=/run/wifi-watchdog.failures
      RELOAD_AFTER=3
      REBOOT_AFTER=10

      # No default route (e.g. NetworkManager restarting) counts as a failure.
      gw=$(ip -4 route show default dev wlan0 | grep -oP 'via \K\S+' | head -1 || true)
      if [ -n "$gw" ] && ping -c 3 -W 2 -q "$gw" >/dev/null; then
        rm -f "$STATE"
        exit 0
      fi

      failures=$(( $(cat "$STATE" 2>/dev/null || echo 0) + 1 ))
      echo "$failures" > "$STATE"
      echo "gateway ''${gw:-<none>} unreachable ($failures consecutive)"

      if [ "$failures" -ge "$REBOOT_AFTER" ]; then
        if journalctl -k --since "-15min" -q --no-pager | grep -q 'brcmf.*-110'; then
          echo "brcmfmac still failing after driver reload, rebooting"
          systemctl reboot
        fi
      elif [ "$failures" -eq "$RELOAD_AFTER" ]; then
        echo "reloading brcmfmac"
        modprobe -r brcmfmac_wcc brcmfmac || true
        sleep 2
        modprobe brcmfmac
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.wifi-watchdog = {
    description = "Check Wi-Fi connectivity every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1min";
    };
  };
}
