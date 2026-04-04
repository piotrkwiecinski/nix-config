{ pkgs }:
pkgs.buildHomeAssistantComponent rec {
  owner = "davidrapan";
  domain = "solarman";
  version = "25.08.16";
  src = pkgs.fetchFromGitHub {
    owner = "davidrapan";
    repo = "ha-solarman";
    tag = "v${version}";
    hash = "sha256-SsUObH3g3i9xQ4JvRDcCm1Fg2giH+MN3rC3NMPYO5m0=";
  };
  propagatedBuildInputs = with pkgs.home-assistant.python.pkgs; [
    aiofiles
  ];
  # Skip manifest requirements check — bundled pysolarman is vendored in-tree,
  # and propcache/aiohttp are already available via Home Assistant core.
  doCheck = false;
}
