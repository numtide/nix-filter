let
  nix-filter = import ../.;
in
{
  all = nix-filter {
    root = ./fixture1;
  };

  without-readme = nix-filter {
    root = ./fixture1;
    exclude = [
      "README.md"
    ];
  };

  with-matchExt = nix-filter {
    root = ./fixture1;
    include = [
      "package.json"
      "src"
      (nix-filter.matchExt "js")
    ];
  };

  trace = nix-filter {
    root = ./fixture1;
    include = [
      nix-filter.traceUnmatched
    ];
  };
}
