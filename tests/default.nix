let
  nix-filter = import ../.;
in
{
  all = nix-filter {
    path = ./fixture1;
  };

  without-readme = nix-filter {
    path = ./fixture1;
    exclude = [
      "README.md"
    ];
  };

  with-matchExt = nix-filter {
    path = ./fixture1;
    include = [
      "package.json"
      "src"
      (nix-filter.matchExt "js")
    ];
  };

  trace = nix-filter {
    path = ./fixture1;
    include = [
      nix-filter.traceUnmatched
    ];
  };
}
