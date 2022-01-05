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

# Usage

Import this folder. Eg:

```nix
let
  nix-filter = import ./path/to/nix-filter;
in
 # ...
```

The top-level is a functor that takes:
* `path` of type `path`: pointing to the root of the source to add to the
    /nix/store.
* `name` of type `string` (optional): the name of the derivation (defaults to
    "source")
* `include` of type `list(string|path|matcher)` (optional): a list of patterns to
    include (defaults to all).
* `exclude` of type `list(string|path|matcher)` (optional): a list of patterns to
    exclude (defaults to none).

The `include` and `exclude` take a matcher, and automatically convert the `string`
and `path` types to a matcher.

The matcher is a function that takes a `path` and `type` and returns `true` if
the pattern matches.

## Builtin matchers

The functor also contains a number of matchers:

* `nix-filter.matchExt`: `ext` -> returns a function that matches the given file extension.
* `nix-filer.inDirectory`: `directory` -> returns a function that matches a directory and
    any path inside of it.
* `nix-filter.isDirectory`: matches all paths that are directories

## Combining matchers

* `and`: `a -> b -> c`
  combines the result of two matchers into a new matcher.
* `or_`: `a -> b -> c`
  combines the result of two matchers into a new matcher.

NOTE: `or` is a keyword in nix, which is why we use a variation here.

REMINDER: both, `include` & `exlude` already XOR elements, so `or_` is
not useful at the top level.

# Design notes

This solution uses `builtins.path { path, name, filter ? path: type: true }`
under the hood, which ships with Nix.

While traversing the filesystem, starting from `path`, it will call `filter`
on each file and folder recursively. If the `filter` returns `false` then the
file or folder is ignored. If a folder is ignored, it won't recurse into it
anymore.

Because of that, it makes it difficult to implement recursive glob matchers.
Something like `**/*.js` would necessarily have to add every folder, to be
able to traverse them. And those empty folders will end-up in the output.

If we want to control rebuild, it's important to have a fixed set of folders.

One possibility is to use a two-pass system, where first all the folders are
being added, and then the empty ones are being filtered out. But all of this
happens at Nix evaluation time. Nix evaluation is already slow enough like
that.

That's why nix-filter is asking the users to explicitly list all the folders
that they want to add.

# Future development

Add more matchers.

# Related projects

* nixpkgs' `lib.cleanSourceWith`.
* All the git-based solutions. See https://github.com/hercules-ci/gitignore.nix#comparison

# License

Copyright (c) 2021 Numtide under the MIT.
