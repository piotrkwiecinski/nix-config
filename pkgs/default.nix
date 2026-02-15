{ pkgs, pkgs-unstable }:
{
  dm = pkgs.writeShellApplication {
    name = "dm";
    text = ''
      find_compose_dir() {
        local dir
        dir=$(pwd)

        while [ "$dir" != "/" ]; do
          if [ -f "$dir/compose.yaml" ] || [ -f "$dir/docker-compose.yml" ]; then
            echo "$dir"
            return 0
          fi
          dir=$(dirname "$dir")
        done

        return 1
      }

      docker_root=$(find_compose_dir) || {
        echo "No compose.yaml or docker-compose.yml file found."
        exit 1
      }

      docker_bin_dir="''${docker_root}/bin"

      if [[ "$#" -eq 0 ]]; then
        echo "dm [COMMAND]"
        echo ""
        echo "Available commands:"
        echo ""
        ls -1 "$docker_bin_dir"
        exit 0
      fi

      command="$1"

      if [ ! -f "''${docker_bin_dir}/''${command}" ]; then
        echo "Command ''${command} not found."
        ls -1 "$docker_bin_dir"
        exit 1
      fi

      shift
      pushd "''${docker_root}"
      ./bin/"''${command}" "''${@}"
      popd
    '';
  };

  claude-code-ide = pkgs-unstable.emacsPackages.trivialBuild {
    pname = "claude-code-ide";
    version = "0-unstable-2026-02-02";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "5f12e60c6d2d1802c8c1b7944bbdf935d5db1364";
      hash = "sha256-tivRvgfI/8XBRImE3wuZ1UD0t2dNWYscv3Aa53BmHZE=";
    };
    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/commit/34fce7a4312ea6cb7824b89a7c789a3b942db958.patch";
        hash = "sha256-PSBrgsECPhvMDYYzdS7nRn9qaSe7OkuJm+3IIwXaE6Q=";
      })
      (pkgs.fetchpatch {
        url = "https://github.com/manzaltu/claude-code-ide.el/commit/24d75f9b6e8a8a4ae2126b0f503d47b63b9592bd.patch";
        hash = "sha256-s12dx6JUx2scZ/KHnBcf4KeggGsD179SS1oKVxI6MCk=";
      })
    ];
    packageRequires = with pkgs-unstable.emacsPackages; [
      vterm
      websocket
      transient
      web-server
    ];
    meta.homepage = "https://github.com/manzaltu/claude-code-ide.el";
  };
}
