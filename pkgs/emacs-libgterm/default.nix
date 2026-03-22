{
  lib,
  stdenv,
  fetchFromGitHub,
  ghostty,
  zig_0_15,
  emacs,
}:

let
  zig = zig_0_15;

  zig_hook = zig.hook.overrideAttrs {
    zig_default_flags = "-Dcpu=baseline --color off";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "emacs-libgterm";
  version = "0.2.0-unstable-2026-03-22";

  src = fetchFromGitHub {
    owner = "rwc9u";
    repo = "emacs-libgterm";
    rev = "ccc1801";
    hash = "sha256-NMutP6klbRJdhNf1aZD/4kLbgNuFr2Z91ORA/8UQtZE=";
  };

  patches = [
    ./fix-error-union.patch
    ./fix-module-path.patch
    ./fix-default-shell.patch
  ];

  nativeBuildInputs = [
    zig_hook
  ];

  postUnpack = ''
    mkdir -p $sourceRoot/vendor
    ln -s ${ghostty.src} $sourceRoot/vendor/ghostty
  '';

  zigBuildFlags = [
    "--system"
    "${ghostty.deps}"
    "-Demacs-include=${emacs}/include"
    "-Doptimize=ReleaseFast"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/emacs/site-lisp
    cp zig-out/lib/libgterm-module.so $out/share/emacs/site-lisp/
    cp gterm.el $out/share/emacs/site-lisp/

    runHook postInstall
  '';

  meta = {
    description = "Terminal emulator for Emacs using libghostty-vt";
    homepage = "https://github.com/rwc9u/emacs-libgterm";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
