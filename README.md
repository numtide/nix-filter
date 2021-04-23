# nix-filter - a small self-container source filtering lib

**STATUS: unstable**

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
    src = ./.;
    allow = [
      "src" # strings are automatically converted to ./src filter
      ./package.json # paths are automatically converted to path filters
      (nix-filter.byExt "js") # create your own filters like that
    ];

    # TODO: doesn't work yet
    deny = [
    ];
  };
}
```
