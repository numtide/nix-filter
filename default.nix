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
      assert builtins.isPath root;
      let
        rootStr = toString root;

        # If an argument to include or exclude is a path, transform it to a matcher.
        #
        # This probably needs more work, I don't think that it works on
        # sub-folders.
        toMatcher = f:
          let
            path_ = _toCleanPath root f;
          in
          if builtins.isFunction f then f root
          else
            path: type:
              path_ == path || (type == "directory" && _hasPrefix "${path}/" path_);

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
  inDirectory =
    directory:
    root:
    let
      # Convert `directory` to a path to clean user input.
      directory_ = _toCleanPath root directory;
    in
    path: type:
    directory_ == path
    # Add / to the end to make sure we match a full directory prefix
    || _hasPrefix (directory_ + "/") path;

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

  # Makes sure a path is:
  # * absolute
  # * doesn't contain superfluous slashes or ..
  #
  # Returns a string so there is no risk of adding it to the store by mistake.
  _toCleanPath = absPath: path:
    assert builtins.isPath absPath;
    if builtins.isPath path then
      toString path
    else if builtins.isString path then
      toString (absPath + ("/" + path))
    else
      throw "unsupported type ${builtins.typeOf path}, expected string or path";

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
