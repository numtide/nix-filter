# This is a pure and self-contained library
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
    , # Only include the following path matches.
      #
      # Allows all files by default.
      include ? [ (_:_: true) ]
    , # Ignore the following matches
      exclude ? [ ]
    }:
    let
      # If an argument to include or exclude is a path, transform it to a matcher.
      #
      # This probably needs more work, I don't think that it works on
      # sub-folders.
      toMatcher = f:
        let
          # Push these here to memoize the result
          path_ = toString f;
          path__ = "${toString path}/${f}";
        in
        if builtins.isFunction f then f
        else if builtins.isPath f then (path: _: path_ == path)
        else if builtins.isString f then (path: _: path__ == path)
        else
          throw "Unsupported type ${builtins.typeOf f}";

      include_ = map toMatcher include;
      exclude_ = map toMatcher exclude;
    in
    builtins.path {
      inherit name path;
      filter = path: type:
        (builtins.any (f: f path type) include_) &&
        (!builtins.any (f: f path type) exclude_);
    };

  # Match paths with the given extension
  matchExt = ext:
    path: type:
      _hasSuffix ".${ext}" path;

  # Wrap a matcher with this to debug its results
  debugMatch = label: fn:
    path: type:
      let
        ret = fn path type;
        retStr = if ret then "true" else "false";
      in
      builtins.trace "label=${label} path=${path} type=${type} ret=${retStr}"
        ret;

  # Add this at the end of the include or exclude, to trace all the unmatched paths
  traceUnmatched = path: type:
    builtins.trace "unmatched path=${path} type=${type}" false;

  # Lib stuff

  _hasSuffix =
    # Suffix to check for
    suffix:
    # Input string
    content:
    let
      lenContent = builtins.stringLength content;
      lenSuffix = builtins.stringLength suffix;
    in
    lenContent >= lenSuffix
    && builtins.substring (lenContent - lenSuffix) lenContent content == suffix;
}
