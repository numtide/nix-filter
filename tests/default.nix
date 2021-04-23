let
  nix-filter = import ../.;
in
{
  all = nix-filter {
    path = ./demo1;
  };

  without-readme = nix-filter {
    path = ./demo1;
    deny = [
      "README.md"
    ];
  };

  with-matchExt = nix-filter {
    path = ./demo1;
    allow = [
      "package.json"
      (nix-filter.matchExt "js")
    ];
  };
}
