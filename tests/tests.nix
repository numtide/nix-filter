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
        "src/components/widget.jsx"
        "src/innerdir"
        (nix-filter.matchExt "js")
      ];
    };
    expected = [
      "package.json"
      "src"
      "src/components"
      "src/components/widget.jsx"
      "src/innerdir"
      "src/innerdir/inner.js"
      "src/main.js"
    ];
  };

  with-matchName = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      exclude = [
        (nix-filter.matchName "src")
      ];
    };
    expected = [
      "README.md"
      "package.json"
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

  excluding-paths-keeps-the-parents = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = with nix-filter; [
        (inDirectory "src")
      ];
      exclude = with nix-filter; [
        "src/components"
        "src/innerdir/inner.js"
      ];
    };
    expected = [
      "src"
      "src/innerdir"
      "src/main.js"
    ];
  };

  including-a-file-also-includes-the-parents = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        "src/innerdir/inner.js"
      ];
    };
    expected = [
      "src"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  including-a-directory-also-includes-the-parents = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        "src/components"
      ];
      exclude = [
        (nix-filter.matchExt "jsx")
      ];
    };
    expected = [
      "src"
      "src/components"
    ];
  };

  including-a-directory-also-includes-the-childs = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = [
        "src/innerdir"
      ];
    };
    expected = [
      "src"
      "src/innerdir"
      "src/innerdir/inner.js"
    ];
  };

  exclude-string-or-matchExt-and-inDirectory = rec {
    root = ./fixture1;
    actual = nix-filter {
      inherit root;
      include = with nix-filter; [
        (inDirectory "src")
      ];
      exclude = with nix-filter; [
        (or_
          "src/components/widget.jsx"
          (and (matchExt "js") (inDirectory "src/innerdir"))
        )
      ];
    };
    expected = [
      "src"
      "src/components"
      "src/innerdir"
      "src/main.js"
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
