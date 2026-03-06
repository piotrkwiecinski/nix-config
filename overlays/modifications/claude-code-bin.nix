{ inputs }:
final: prev:
let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.70";
  platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
  checksums = {
    "linux-x64" = "sha256-HlwQEeyJnvDKnwgRwTw+1EQ3Qirtha9gDV/lB0b6rx0=";
    "linux-arm64" = "sha256-JkxmnOR0C7SJawesARAZC89hjt3U+wBos/4s6YlzRoI=";
  };
in
{
  master = prev.master // {
    claude-code-bin = prev.master.claude-code-bin.overrideAttrs (oldAttrs: {
      inherit version;
      src = prev.master.fetchurl {
        url = "${baseUrl}/${version}/${platformKey}/claude";
        sha256 = checksums.${platformKey};
      };
    });
  };
}
