{
  description = ''
    Intel Low Power Mode Daemon (lpmd) is a Linux daemon designed to optimize
    active idle power. It selects the most power-efficient CPUs based on a
    configuration file or CPU topology. Depending on system utilization and
    other hints, it puts the system into Low Power Mode by activating the
    power-efficient CPUs and disabling the rest, and restores the system from
    Low Power Mode by activating all CPUs.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        default = pkgs.callPackage ./package.nix { };
      };

      nixosModules.default = import ./module.nix;
    };
}
