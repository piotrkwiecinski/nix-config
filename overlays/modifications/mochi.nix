{ inputs }:
final: prev: {
  unstable = prev.unstable // {
    mochi =
      let
        pname = "mochi";
        version = "1.20.10";
        baseUrl = "https://download.mochi.cards/releases/";

        meta = {
          description = "Simple markdown-powered SRS app";
          homepage = "https://mochi.cards/";
          changelog = "https://mochi.cards/changelog.html";
          license = prev.lib.licenses.unfree;
          sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
          maintainers = with prev.lib.maintainers; [ poopsicles ];
          platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;
        };
      in
      prev.unstable.appimageTools.wrapType2 rec {
        inherit pname version meta;

        src = prev.fetchurl {
          url = baseUrl + "Mochi-${version}.AppImage";
          hash = "sha256-oC53TXgK6UUgsHbLo0Ri/+2/UajYwpoXxHwqO1xY91U=";
        };

        appimageContents = prev.unstable.appimageTools.extractType2 { inherit pname version src; };

        extraPkgs = pkgs: [ prev.xorg.libxshmfence ];

        extraInstallCommands = ''
          install -Dm444 ${appimageContents}/${pname}.desktop -t $out/share/applications/
          install -Dm444 ${appimageContents}/${pname}.png -t $out/share/pixmaps/
          substituteInPlace $out/share/applications/${pname}.desktop \
            --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname}'
        '';
      };
  };
}
