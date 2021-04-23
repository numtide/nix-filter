# This is a pure and self-contained library
let
  hasSuffix =
    # Suffix to check for
    suffix:
    # Input string
    content:
    let
      lenContent = builtins.length content;
      lenSuffix = builtins.length suffix;
    in
    lenContent >= lenSuffix &&
    builtins.substring (lenContent - lenSuffix) lenContent content == suffix;
in
rec {
  # Default to filter when calling this lib.
  __functor = self: filter;

  # A proper source filter
  filter =
    {
      # Base path to include
      path
    , # Derivation name
      name ? "source"
    , # Only allow the following path matches.
      #
      # Allows all files by default.
      allow ? [ (_:_: true) ]
    , # Ignore the following matches
      deny ? [ ]
    }:
    let
      # If an argument to allow or deny is a path, transform it to a matcher.
      #
      # This probably needs more work, I don't think that it works on
      # sub-folders.
      toMatcher = f:
        let
          path_ = toString f;
          path__ = "${toString path}/${f}";
        in
        if builtins.isFunction f then f
        else if builtins.isPath f then (path: type: path_ == toString path)
        else if builtins.isString f then (path: type: path__ == toString path)
        else
          throw "Unsupported type ${builtins.typeOf f}";

      allow_ = map toMatcher allow;
      deny_ = map toMatcher deny;
    in
    builtins.path {
      inherit name path;
      filter = path: type:
        (builtins.any (f: f path type) allow_) &&
        (!builtins.any (f: f path type) deny_);
    };

  # Match paths with the given extension
  byExt = ext:
    path: type:
      (hasSuffix ".${ext} " path);
}
