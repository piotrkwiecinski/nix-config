{ pkgs }:
let
  bluetti-bt-lib = pkgs.home-assistant.python.pkgs.buildPythonPackage rec {
    pname = "bluetti-bt-lib";
    version = "0.1.6";
    pyproject = true;
    src = pkgs.fetchFromGitHub {
      owner = "Patrick762";
      repo = "bluetti-bt-lib";
      rev = version;
      hash = "sha256-2+/d3Rb1icVMsTCrtWqtk9WBBe8/82r05It2RxaeVSY=";
    };
    env.LIB_VERSION = version;
    build-system = with pkgs.home-assistant.python.pkgs; [ setuptools ];
    dependencies = with pkgs.home-assistant.python.pkgs; [
      bleak
      bleak-retry-connector
      crcmod
      cryptography
      async-timeout
      pyasn1
    ];
    doCheck = false;
    dontCheckRuntimeDeps = true;
  };
in
pkgs.buildHomeAssistantComponent rec {
  owner = "Patrick762";
  domain = "bluetti_bt";
  version = "0.2.1";
  src = pkgs.fetchFromGitHub {
    owner = "Patrick762";
    repo = "hassio-bluetti-bt";
    rev = version;
    hash = "sha256-1qWn+KuQY8SRNemOSVqur2JNg6K/pqcVSQsgFrl/6IE=";
  };
  propagatedBuildInputs = [ bluetti-bt-lib ];
}
