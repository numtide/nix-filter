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
        if builtins.isFunction f then
          builtins.concatMap (p: _expandPath root p []) (_matchManually root f)
        else if builtins.isPath f then _expandPath root f []
        else if builtins.isString f then _expandPath root (_stringToPath root f) []
        else
          throw "Unsupported type ${builtins.typeOf f}";

      include_ = builtins.foldl' (includes: path:
        includes // { ${toString path} = true; }
      ) {} (builtins.concatMap toMatcher include);

      exclude_ = builtins.foldl' (excludes: path:
        excludes // { ${toString path} = true; }
      ) {} (builtins.concatMap toMatcher exclude);
    in
    builtins.path {
      inherit name;
      path = root;
      filter = path: type:
        (builtins.hasAttr (toString path) include_) &&
        (!builtins.hasAttr (toString path) exclude_);
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

  # Expand a path into a list containing itself and its parents up to the root.
  #
  # >>> _expandPath /home/me /home/me/projects/nix-filter/tests []
  # [ /home/me/projects/nix-filter/tests /home/me/projects/nix-filter /home/me/projects ]
  #
  # >>> _expandPath /home/me /nix/var/nix/profiles []
  # []
  _expandPath =
    # The root of the project, type: path
    root:
    # The path to expand, type: path
    path:
    # Paths accumulated while expanding `path`
    acc:
    if path == root then acc
    # If we hit /, `path` wasn't in our root path (i.e. the path is outside the project),
    # so discard the accumulated results.
    else if path == /. then []
    else _expandPath root (builtins.dirOf path) (acc ++ [path]);

  # Traverse the filesystem starting at the root and accumulate a list of
  # paths accepted by matchFn (some matcher function).
  #
  # >>> _matchManually ./fixture1 (matchExt "js")
  # [ /home/me/projects/nix-filter/tests/fixture1/src/main.js ]
  _matchManually =
    # The root of the project, type: path
    root:
    # The matcher function to run on paths within the root of the project,
    # type: path -> file type (string) -> bool
    matchFn:
    let
      files = builtins.readDir root;
      filesAsList = map (fileName:
        {
          path = _stringToPath root fileName;
          type = builtins.getAttr fileName files;
        }
      ) (builtins.attrNames files);
      matchedPaths = map (file: file.path)
        (builtins.filter (file: matchFn file.path file.type) filesAsList);
      innerMatchedPaths = builtins.concatMap (file: _matchManually file.path matchFn)
        (builtins.filter (file: file.type == "directory") filesAsList);
    in
    matchedPaths ++ innerMatchedPaths;

  # Properly convert a string to a path based on the given root
  #
  # >>> _stringToPath /nix "store"
  # /nix/store
  _stringToPath = root: str:
    # Parentheses necessary here! If they are not included, it is treated as
    # (root + "/") + str. Since a path cannot end in "/", the slash gets
    # completely removed, effectively resulting in `root + str`.
    root + ("/" + str);
}
