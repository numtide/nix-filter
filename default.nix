# This is a pure and self-contained library
rec {
  # Default to filter when calling this lib.
  __functor = self: filter;

  # A proper source filter
  filter =
    {
      # Base path to include
      root
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
      rootStr = toString root;

      # If an argument to include or exclude is a path, transform it to a matcher.
      #
      # This probably needs more work, I don't think that it works on
      # sub-folders.
      toMatcher = f:
        let
          # Push these here to memoize the result
          path_ = toString f;
          path__ = "${rootStr}/${f}";
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
      inherit name;
      path = root;
      filter = path: type:
        (builtins.any (f: f path type) include_) &&
        (!builtins.any (f: f path type) exclude_);
    };

  # Match a directory and any path inside of it
  inDirectory = directory:
    path: type:
      _isPathPrefix directory path;

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

  # Determine segment-wise if one path is a prefix of another
  #
  # Paths need to be split into segments since a simple string
  # prefix check would naively conclude things like "/nix/sto"
  # is a path prefix of "/nix/store" even though they are completely
  # different directories.
  #
  # >>> _isPathPrefix /nix/var/ /nix/var/nix/profiles/
  # true
  #
  # >>> _isPathPrefix "store" /nix/store/
  # false
  _isPathPrefix =
    # Prefix to search for in `path`, can be a string or a path
    prefixPath:
    # Path to search, can be a string or a path
    path:
    let
      prefixSegments = _splitPath prefixPath;
      pathSegments = _splitPath path;

      # Compare the lists of segments. If any segment doesn't match,
      # the prefix is a not a prefix of the path.
      #
      # This iterates over the prefix and should not be run if the
      # path is shorter than the prefix or it will throw runtime
      # errors.
      comparison =
        builtins.foldl' (acc: prefixSegment:
          let
            isPrefix = acc.isPrefix && prefixSegment == builtins.head acc.remainingPath;
            remainingPath = builtins.tail acc.remainingPath;
          in
          { inherit isPrefix remainingPath; }
        ) { isPrefix = true; remainingPath = pathSegments; } prefixSegments;
    in
    # Fail immediately if the path is shorter than the prefix; do not try to
    # compare.
    if builtins.length prefixSegments > builtins.length pathSegments
    then false
    else comparison.isPrefix;

  # Split a path into its segments, filtering out empty segments
  #
  # >>> _splitPath "/nix/store/"
  # [ "nix" "store" ]
  #
  # >>> _splitPath /home/me/////projects/nix-filter////
  # [ "home" "me" "projects" "nix-filter" ]
  _splitPath =
    # Path to split, can be a path or a string
    path:
    let
      pathStr = builtins.toString path;
    in
    builtins.filter (x: x != "" && x != []) (builtins.split "/" pathStr);
}
