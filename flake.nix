{
  description = "nix-filter";

  outputs = { self }: {
    lib = import ./default.nix;
    overlays.default = _: _: { nix-filter = self.lib; };
  };
}
