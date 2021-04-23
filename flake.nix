{
  description = "nix-filter";

  outputs = { self }: {
    lib = import ./default.nix;
  };
}
