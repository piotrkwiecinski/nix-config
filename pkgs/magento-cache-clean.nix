{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "magento-cache-clean";
  version = "1.1.4-unstable-2024-04-03";

  src = fetchFromGitHub {
    owner = "mage2tv";
    repo = "magento-cache-clean";
    rev = "e52d340ad648e44bf33d618b79f16e396488d64d";
    hash = "sha256-+/ZzXto++SxSBJBkVL9mcUWrdkONDUpddJbODpG9VLs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/magento-cache-clean $out/bin
    cp -r bin node_modules $out/lib/magento-cache-clean/

    makeWrapper ${nodejs}/bin/node $out/bin/cache-clean \
      --add-flags "$out/lib/magento-cache-clean/bin/cache-clean.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "File watcher based cache cleaner for Magento 2";
    homepage = "https://github.com/mage2tv/magento-cache-clean";
    license = licenses.bsd3;
    mainProgram = "cache-clean";
  };
}
