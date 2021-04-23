let
  nix-filter = import ../.;
in
{
  all = nix-filter {
    path = ./fixture1;
  };

  without-readme = nix-filter {
    path = ./fixture1;
    deny = [
      "README.md"
    ];
  };

  with-matchExt = nix-filter {
    path = ./fixture1;
    allow = [
      "package.json"
      "src"
      (nix-filter.matchExt "js")
    ];
  };

  trace = nix-filter {
    path = ./fixture1;
    allow = [
      nix-filter.traceUnmatched
    ];
  };
}
