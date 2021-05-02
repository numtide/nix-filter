let
  nix-filter = import ../.;
in
{
  all = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
    };
    expected = [
      "README.md"
      "package.json"
      "src"
      "src/main.js"
      "src/components"
      "src/components/widget.jsx"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  without-readme = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      exclude = [
        "README.md"
      ];
    };
    expected = [
      "package.json"
      "src"
      "src/main.js"
      "src/components"
      "src/components/widget.jsx"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  with-matchExt = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        "package.json"
        "src"
        (nix-filter.matchExt "js")
      ];
    };
    expected = [
      "package.json"
      "src"
      "src/main.js"
    ];
  };

  with-matchExt2 = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        "package.json"
        "src/innerdir"
        (nix-filter.matchExt "js")
      ];
    };
    expected = [
      "package.json"
      "src"
      "src/main.js"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  with-inDirectory = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        (nix-filter.inDirectory "src")
        (nix-filter.inDirectory "READ")
      ];
    };
    expected = [
      "src"
      "src/main.js"
      "src/components"
      "src/components/widget.jsx"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  with-inDirectory2 = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        (nix-filter.inDirectory "src")
        (nix-filter.inDirectory "READ")
      ];
      exclude = [
        (nix-filter.inDirectory ./fixture1/src/innerdir)
      ];
    };
    expected = [
      "src"
      "src/main.js"
      "src/components"
      "src/components/widget.jsx"
    ];
  };

  combiners = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = with nix-filter; [
        (and isDirectory (inDirectory "src"))
      ];
    };
    expected = [
      "src"
      "src/components"
      "src/innerdir"
    ];
  };

  trace = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        nix-filter.traceUnmatched
      ];
    };
    expected = [ ];
  };
}
