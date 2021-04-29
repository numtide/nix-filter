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
      include ? [ (_:_:_: true) ]
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
        else if builtins.isPath f then (_: path: _: path_ == path)
        else if builtins.isString f then (_: path: _: path__ == path)
        else
          throw "Unsupported type ${builtins.typeOf f}";

      include_ = map toMatcher include;
      exclude_ = map toMatcher exclude;
    in
    builtins.path {
      inherit name;
      path = root;
      filter = path: type:
        (builtins.any (f: f root path type) include_) &&
        (!builtins.any (f: f root path type) exclude_);
    };

  # Match a directory and any path inside of it
  inDirectory = directory:
    root: path: type:
      let
        # Convert `directory` to a path to clean user input
        dirAsPath =
          if builtins.isString directory then root + ("/" + directory)
          else if builtins.isPath directory then directory
          else
            throw "inDirectory: Unsupported type ${builtins.typeOf directory}, expected string or path";
        directory_ = toString dirAsPath;
        path_ = toString path;
      in
      directory_ == path_
      # Add / to the end to make sure we match a full directory prefix
      || _hasPrefix (directory_ + "/") path_;

  # Match paths with the given extension
  matchExt = ext:
    root: path: type:
      _hasSuffix ".${ext}" path;

  # Wrap a matcher with this to debug its results
  debugMatch = label: fn:
    root: path: type:
      let
        ret = fn path type;
        retStr = if ret then "true" else "false";
      in
      builtins.trace "label=${label} path=${path} type=${type} ret=${retStr}"
        ret;

  # Add this at the end of the include or exclude, to trace all the unmatched paths
  traceUnmatched = root: path: type:
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

  _hasPrefix =
    # Prefix to check for
    prefix:
    # Input string
    content:
    let
      lenPrefix = builtins.stringLength prefix;
    in
    prefix == builtins.substring 0 lenPrefix content;
}
