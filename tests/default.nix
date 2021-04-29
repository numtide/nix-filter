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

  with-matchExt2 = nix-filter {
    root = ./fixture1;
    include = [
      "package.json"
      "src/innerdir"
      (nix-filter.matchExt "js")
    ];
  };

  with-inDirectory = nix-filter rec {
    root = ./fixture1;
    include = [
      (nix-filter.inDirectory "src") # should match everything under ./fixture1/src/
      (nix-filter.inDirectory "READ") # should not match README.md
    ];
  };

  # should match everything under ./fixture1/src/ but not in ./fixture1/src/innerdir/
  with-inDirectory2 = nix-filter rec {
    root = ./fixture1;
    include = [
      (nix-filter.inDirectory "src")
    ];
    exclude = [
      (nix-filter.inDirectory ./fixture1/src/innerdir)
    ];
  };

  trace = nix-filter {
    root = ./fixture1;
    include = [
      nix-filter.traceUnmatched
    ];
  };
}
