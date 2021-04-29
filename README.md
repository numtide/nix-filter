<h1 align="center">
  <img src="nix-filter.svg" alt="logo" width="200">
  <br>
  nix-filter - a small self-contained source filtering lib
</h1>

**STATUS: beta**

A cool way to include only what you need.

When using nix within a project, developers often use `src = ./.;` for a
project like this:

```nix
{ stdenv }:
stdenv.mkDerivation {
  name = "my-project";
  src = ./.;
}
```

This works but has an issue; on each build, nix will copy the whole project
source code into the /nix/store. Including the `.git` folder and any temporary
files left over by the editor.

The main workaround is to use either `builtins.fetchGit ./.` or one of the
many gitignore filter projects but this is not precise enough. If the
project README changes, it should rebuild the project. If the nix code
changes, it shouldn't rebuild the project. That's why this project exists. I
want total control.

## Example usage

```nix
{ stdenv, nix-filter }:
stdenv.mkDerivation {
  name = "my-project";
  src = nix-filter {
    root = ./.;
    # If no include is passed, it will include all the paths.
    include = [
      # Include the "src" path relative to the root.
      "src"
      # Include this specific path. The path must be under the root.
      ./package.json
      # Include all files with the .js extension
      (nix-filter.matchExt "js")
    ];

    # Works like include, but the reverse.
    exclude = [
      ./main.js
    ];
  };
}
```

## How it works

nix-filter is a function that takes:
* `path` of type `path`: pointing to the root of the source to add to the
    /nix/store.
* `name` of type `string` (optional): the name of the derivation (defaults to
    "source")
* `include` of type `list(string|path|matcher)` (optional): a list of patterns to
    include (defaults to all).
* `exclude` of type `list(string|path|matcher)` (options): a list of patterns to
    exclude (defaults to none).

The `include` and `exclude` take a matcher, and automatically convert the `string`
and `path` types to a matcher.

The matcher is a function that takes a `path` and `type` and returns `true` if
the pattern matches.

## Builtin matchers

* `matchExt`: `ext` -> returns a function that matches the given file extension.
* `inDirectory`: `directory` -> returns a function that matches a directory and
    any path inside of it.
* `isDirectory`: matches all paths that are directories

## Combining matchers

* `and`: `a -> b -> c`
  combines the result of two matchers into a new matcher.
* `or`: `a -> b -> c`
  combines the result of two matchers into a new matcher.

## Future development

Solve the above issue. Add more matchers.

# License

Copyright (c) 2021 Numtide under the MIT.
