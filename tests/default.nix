let
  testCases = import ./tests.nix;

  # Convert a path to a string with the root stripped
  toRelativeString = root: path:
    let
      r = toString root;
      p = toString path;
    in
    builtins.substring
      (builtins.stringLength r + 1)
      (builtins.stringLength p)
      p;

  # Traverse a directory, returning all children in a list
  listDir =
    root:
    let
      files = builtins.readDir root;
      filesAsList = map
        (fileName:
          {
            path = root + ("/" + fileName);
            type = builtins.getAttr fileName files;
          }
        )
        (builtins.attrNames files);
      pathsInDir = map (file: file.path) filesAsList;
      nestedPaths = builtins.concatMap (file: listDir file.path)
        (builtins.filter (file: file.type == "directory") filesAsList);
    in
    pathsInDir ++ nestedPaths;

  # Run a test, returning a list of failures
  runTest = testDef:
    let
      missing = builtins.filter
        (file:
          ! builtins.pathExists (testDef.actual + ("/" + file))
        )
        testDef.expected;
      included = map (toRelativeString testDef.actual) (listDir testDef.actual);
      extra = builtins.filter
        (path:
          ! builtins.elem path testDef.expected
        )
        included;
    in
    (map (x: { path = x; status = "missing"; }) missing)
    ++
    (map (x: { path = x; status = "extra"; }) extra);

  # Take a set of test results and filter out every key that
  # is not failing.
  onlyFailures = results:
    let
      names = builtins.attrNames results;
    in
    builtins.foldl'
      (finalFailures: testName:
        let
          failures = builtins.getAttr testName results;
        in
        if builtins.length failures == 0
        then finalFailures
        else finalFailures // { ${testName} = failures; }
      )
      { }
      names;

  testResults = builtins.mapAttrs (_: testDef: runTest testDef) testCases;
in
testResults // { "@onlyFailures" = onlyFailures testResults; }
