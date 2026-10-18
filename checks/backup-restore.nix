# End-to-end test of homeserver's backups (hosts/homeserver/backup.nix and
# homeserver-restore) against an append-only rest-server set up like
# homerpilab's: back up Home Assistant and Paperless, verify, wipe, restore,
# roll back. Home Assistant itself is a stand-in unit; the restore only needs
# its service, user and data directory. Paperless is the real service.
{ pkgs }:
let
  restPassword = "rest-test-password";
  htpasswd = pkgs.runCommand "restic-htpasswd" { nativeBuildInputs = [ pkgs.apacheHttpd ]; } ''
    htpasswd -B -b -c $out homeserver ${restPassword}
  '';
in
pkgs.testers.runNixOSTest {
  name = "homeserver-backup-restore";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../hosts/homeserver/backup.nix ];

      virtualisation = {
        memorySize = 3072;
        diskSize = 4096;
      };

      # homerpilab's side, on localhost
      services.restic.server = {
        enable = true;
        appendOnly = true;
        privateRepos = true;
        htpasswd-file = "${htpasswd}";
      };

      homeserver.backup = {
        repositoryFile = "${pkgs.writeText "restic-repository" "rest:http://homeserver:${restPassword}@localhost:8000/homeserver/"}";
        passwordFile = "${pkgs.writeText "restic-password" "repo-test-password"}";
      };

      services.paperless = {
        enable = true;
        database.createLocally = true;
        passwordFile = "${pkgs.writeText "paperless-admin" "admin-test-password"}";
        exporter = {
          enable = true;
          # Never fires; the restore stops and restarts this timer as in production
          onCalendar = "2099-01-01";
        };
      };

      users.users.hass = {
        isSystemUser = true;
        group = "hass";
        home = "/var/lib/hass";
      };
      users.groups.hass = { };
      systemd.services.home-assistant = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "hass";
          ExecStart = "${pkgs.coreutils}/bin/sleep infinity";
        };
      };

      environment.systemPackages = [
        pkgs.sqlite
        pkgs.restic
      ];
    };

  testScript =
    { nodes, ... }:
    let
      backup = nodes.machine.homeserver.backup;
    in
    ''
      import re

      def documents():
          return int(machine.succeed(
              "paperless-manage shell -c "
              "'from documents.models import Document; print(Document.objects.count())'"
          ).strip().splitlines()[-1])

      def hass_rows():
          return machine.succeed(
              "sqlite3 /var/lib/hass/home-assistant_v2.db 'select count(*) from t'"
          ).strip()

      def undo_stamp(output):
          match = re.search(r"rollback (\d{8}-\d{6})", output)
          assert match, output
          return match.group(1)

      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("paperless-scheduler.service")
      machine.wait_for_unit("paperless-consumer.service")
      machine.wait_for_unit("home-assistant.service")

      with subtest("seed Home Assistant and Paperless"):
          machine.succeed(
              "install -d -o hass -g hass /var/lib/hass/.storage",
              "echo '{\"data\": {}}' > /var/lib/hass/.storage/core.config_entries",
              "sqlite3 /var/lib/hass/home-assistant_v2.db 'create table t(x); insert into t values (1), (2)'",
              "sqlite3 /var/lib/hass/zigbee.db 'create table devices(ieee); insert into devices values (1)'",
              "chown -R hass:hass /var/lib/hass",
          )
          machine.succeed(
              "echo 'restore test document' > /tmp/restore-test.txt",
              "install -o paperless -g paperless /tmp/restore-test.txt /var/lib/paperless/consume/",
          )
          machine.wait_until_succeeds("[ $(paperless-manage shell -c "
              "'from documents.models import Document; print(Document.objects.count())' "
              "| tail -1) = 1 ]", timeout=300)

      with subtest("back up both services"):
          machine.succeed("systemctl start restic-backups-hass.service")
          machine.succeed("systemctl is-active home-assistant.service")
          machine.succeed("systemctl start --wait paperless-exporter.service")
          machine.succeed("systemctl start restic-backups-paperless.service")
          machine.succeed("homeserver-restore hass list | grep /var/lib/hass >/dev/null")
          machine.succeed("homeserver-restore paperless list | grep /var/lib/paperless/export >/dev/null")

      with subtest("the repository is append-only"):
          out = machine.execute(
              "RESTIC_REPOSITORY_FILE=${backup.repositoryFile} "
              "RESTIC_PASSWORD_FILE=${backup.passwordFile} "
              "restic forget --path /var/lib/hass latest 2>&1"
          )[1]
          assert "unable to remove" in out, out
          machine.succeed("homeserver-restore hass list | grep '1 snapshots' >/dev/null")

      with subtest("verify both snapshots"):
          out = machine.succeed("homeserver-restore hass verify 2>&1")
          assert "zigbee.db: integrity ok" in out, out
          out = machine.succeed("homeserver-restore paperless verify 2>&1")
          assert "1 documents, all files present" in out, out
          machine.fail("ls -d /var/lib/hass-restore-* /var/lib/paperless/restore-*")

      with subtest("lose the data"):
          machine.succeed(
              "systemctl stop home-assistant.service",
              "rm -rf /var/lib/hass/* /var/lib/hass/.storage",
              "systemctl start home-assistant.service",
          )
          machine.succeed(
              "paperless-manage shell -c "
              "'from documents.models import Document; Document.objects.all().delete()'"
          )
          assert documents() == 0

      with subtest("restore Home Assistant"):
          out = machine.succeed("homeserver-restore hass restore --yes 2>&1")
          hass_stamp = undo_stamp(out)
          assert hass_rows() == "2"
          machine.succeed("[ $(stat -c %U /var/lib/hass/zigbee.db) = hass ]")
          machine.succeed("test -f /var/lib/hass/.storage/core.config_entries")
          machine.wait_for_unit("home-assistant.service")

      with subtest("restore Paperless"):
          out = machine.succeed("homeserver-restore paperless restore --yes 2>&1")
          paperless_stamp = undo_stamp(out)
          assert documents() == 1
          machine.succeed(
              "paperless-manage shell -c "
              "'from documents.models import Document; "
              "assert \"restore test document\" in Document.objects.get().content'"
          )
          machine.wait_for_unit("paperless-web.service")
          machine.succeed("systemctl is-active paperless-exporter.timer")

      with subtest("roll both restores back"):
          machine.succeed(f"homeserver-restore hass rollback {hass_stamp} --yes")
          machine.fail("test -f /var/lib/hass/home-assistant_v2.db")
          machine.wait_for_unit("home-assistant.service")
          machine.succeed(f"homeserver-restore paperless rollback {paperless_stamp} --yes")
          assert documents() == 0
          machine.wait_for_unit("paperless-web.service")
    '';
}
