pkgs: {
  tree-sitter-phpdoc = pkgs.tree-sitter.buildGrammar {
    language = "tree-sitter-phpdoc";
    version = "0.1.5";
    src = pkgs.fetchFromGitHub {
      owner = "claytonrcarter";
      repo = "tree-sitter-phpdoc";
      tag = "v0.1.5";
      hash = "sha256-sQ8jmVvZD0fIc9qlfyl6MaXvP/2ljzViKIl9RgVOJqw=";
    };
    meta.homepage = "https://github.com/claytonrcarter/tree-sitter-phpdoc";
  };
}
