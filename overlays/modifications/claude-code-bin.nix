{ inputs }:
final: prev:
let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.70";
  platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
  checksums = {
    "linux-x64" = "1e5c1011ec899ef0ca9f0811c13c3ed44437422aed85af600d5fe50746faaf1d";
    "linux-arm64" = "264c669ce4740bb4896b07ac0110190bcf618eddd4fb0068b3fe2ce989734682";
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
