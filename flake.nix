{
  description = "nix-filter";

  outputs = { self }: {
    __functor = self.lib.__functor;
    lib = import ./default.nix;
    overlays.default = _: _: { nix-filter = self.lib; };
  };
}
