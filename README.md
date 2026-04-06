# Intel Low Power Mode Daemon as a NixOS module

This flake provides a Nix wrapper for the
[`intel-lpmd`](https://github.com/dmfrpro/intel-lpmd) daemon.

This fork includes:

- **CachyOS patches** addressing:
  - [#110](https://github.com/intel/intel-lpmd/issues/110)
  - [#106](https://github.com/intel/intel-lpmd/issues/106)
  - [#101](https://github.com/intel/intel-lpmd/issues/101)

- **[@octomike](https://github.com/octomike/intel-lpmd) patch** addressing:
  - [#71](https://github.com/intel/intel-lpmd/issues/71)

## Installation as NixOS module

1. Add to flake.nix:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  intel-lpmd-flake.url = "github:dmfrpro/intel-lpmd-flake";
  intel-lpmd-flake.inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Add to your module imports:

```nix
outputs = { self, nixpkgs, intel-lpmd-flake, ... }: {
  nixosConfigurations.host = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      intel-lpmd-flake.nixosModules.default
    ];
  };
};
```

3. Enable the service:

```nix
{
  services.intel-lpmd = {
    enable = true;
    config.meteorLake = true;  # meteorLake / lunarLake / pantherLake / experimental / custom
    mode = "ON";  # ON / OFF / AUTO
    debug = true;
  };
}
```

## All options

| Option                              | Type                     | Default      | Description                                                                                    |
|-------------------------------------|--------------------------|--------------|------------------------------------------------------------------------------------------------|
| `enable`                            | bool                     | `false`      | Enable the Intel lpmd service.                                                                 |
| `debug`                             | bool                     | `false`      | Append `--loglevel=debug` to the daemon command line.                                          |
| `mode`                              | `"ON"`, `"OFF"`, `"AUTO"`| `"AUTO"`     | Control mode passed to `intel_lpmd_control` after daemon starts.                               |
| `config.meteorLake`                 | bool                     | `false`      | Use the predefined Meteor Lake XML config (`intel_lpmd_config_F6_M170.xml`).                   |
| `config.lunarLake`                  | bool                     | `false`      | Use the predefined Lunar Lake XML config (`intel_lpmd_config_F6_M189.xml`).                    |
| `config.pantherLake`                | bool                     | `false`      | Use the predefined Panther Lake XML config (`intel_lpmd_config_F6_M204.xml`).                  |
| `config.experimental`               | bool                     | `false`      | Use the predefined experimental XML config (`experimental.xml`).                               |
| `config.custom`                     | null or string           | `null`       | Raw XML content for a custom configuration. When set, none of the predefined flags may be set. |
