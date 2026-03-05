{ inputs }:
final: prev:
let
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  version = "2.1.69";
  platformKey = "${final.stdenv.hostPlatform.node.platform}-${final.stdenv.hostPlatform.node.arch}";
  checksums = {
    "linux-x64" = "b3bdbd5a3cbf8caafe353022170df77fefa80b00003074d4d27e7da8c59e629a";
    "linux-arm64" = "ecc7bbf10513ff122327866eb97212945b73afd7f81e30700375cdf10f50b2a3";
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
