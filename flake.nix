{
  description = "Flake for nvim-fzf";

  outputs = {...}: {
    default = {
      imports = [
        ./nvim-fzf.nix
      ];
    };
  };
}
