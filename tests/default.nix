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

  with-inDirectory = nix-filter rec {
    root = ./fixture1;
    include = [
      (nix-filter.inDirectory (root + "/src")) # should match everything under ./fixture1/src/
      (nix-filter.inDirectory (root + "/READ")) # should not match README.md
    ];
  };

  trace = nix-filter {
    root = ./fixture1;
    include = [
      nix-filter.traceUnmatched
    ];
  };
}
