{ inputs }:
_final: prev: {
  unstable = prev.unstable // {
    claude-code = prev.unstable.claude-code.overrideAttrs (_: rec {
      version = "2.1.12";
      src = prev.unstable.fetchzip {
        url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
        hash = "sha256-JX72YEM2fXY7qKVkuk+UFeef0OhBffljpFBjIECHMXw=";
      };
      npmDepsHash = "sha256-FxyNCFlsgjXAGCGqro+VRwkarif9SzqmrMz0xgmvBco=";
    });
  };
}
