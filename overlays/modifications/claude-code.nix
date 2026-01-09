{ inputs }:
_final: prev: {
  unstable = prev.unstable // {
    claude-code = prev.unstable.claude-code.overrideAttrs (_: rec {
      version = "2.1.2";
      src = prev.unstable.fetchzip {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        hash = "sha256-PpNXyZ3xoZ/4lCvtErltkdsL/1hDRyiicblvhykgROw=";
      };
      npmDepsHash = "sha256-KdVaAYXCy+oMN9b1lLeIRiGp/Zb29T4b3pvDp8O1v/M=";
    });
  };
}
