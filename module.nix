{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.intel-lpmd;
  pkg = pkgs.callPackage ./package.nix { };
  inherit (lib)
    mkOption
    mkEnableOption
    types
    optionalString
    ;
in
{
  options.services.intel-lpmd = {
    enable = mkEnableOption "Intel Linux Energy Optimizer (lpmd)";

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug logging (adds --loglevel=debug).";
    };

    mode = mkOption {
      type = types.enum [
        "ON"
        "OFF"
        "AUTO"
      ];
      default = "AUTO";
      description = "Set the lpmd control mode (ON, OFF, or AUTO).";
    };

    config = {
      meteorLake = mkEnableOption "Meteor Lake configuration (intel_lpmd_config_F6_M170.xml)";
      lunarLake = mkEnableOption "Lunar Lake configuration (intel_lpmd_config_F6_M189.xml)";
      pantherLake = mkEnableOption "Panther Lake configuration (intel_lpmd_config_F6_M204.xml)";
      experimental = mkEnableOption "Experimental configuration (experimental.xml)";
      custom = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              content = mkOption {
                type = types.str;
                description = "Raw XML content of the custom configuration.";
              };
              filename = mkOption {
                type = types.str;
                default = "custom.xml";
                description = "Filename to use inside /etc/intel_lpmd/. The daemon may require a specific name; adjust accordingly.";
              };
            };
          }
        );
        default = null;
        description = "Custom XML configuration. If set, overrides any predefined options.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          let
            predefinedCount = lib.count (id: id) [
              cfg.config.meteorLake
              cfg.config.lunarLake
              cfg.config.pantherLake
              cfg.config.experimental
            ];
            customSet = cfg.config.custom != null;
          in
          (predefinedCount == 1 && !customSet) || (customSet && predefinedCount == 0);
        message = ''
          Exactly one of services.intel-lpmd.config.{meteorLake, lunarLake, pantherLake, experimental} must be enabled,
          or services.intel-lpmd.config.custom must be set to a non-null value. Do not mix custom with predefined flags.
        '';
      }
    ];

    environment.etc =
      let
        configChoice =
          if cfg.config.custom != null then
            {
              source = pkgs.writeText "custom-config.xml" cfg.config.custom.content;
              targetName = cfg.config.custom.filename;
            }
          else if cfg.config.meteorLake then
            {
              source = "${pkg}/share/xml/intel_lpmd_config_F6_M170.xml";
              targetName = "intel_lpmd_config_F6_M170.xml";
            }
          else if cfg.config.lunarLake then
            {
              source = "${pkg}/share/xml/intel_lpmd_config_F6_M189.xml";
              targetName = "intel_lpmd_config_F6_M189.xml";
            }
          else if cfg.config.pantherLake then
            {
              source = "${pkg}/share/xml/intel_lpmd_config_F6_M204.xml";
              targetName = "intel_lpmd_config_F6_M204.xml";
            }
          else if cfg.config.experimental then
            {
              source = "${pkg}/share/xml/experimental.xml";
              targetName = "experimental.xml";
            }
          else
            throw "Unreachable: assertion guarantees a valid config";
      in
      {
        "intel_lpmd/${configChoice.targetName}".source = configChoice.source;
      };

    systemd.services.intel-lpmd = {
      description = "Intel Linux Energy Optimizer (lpmd) Service";
      documentation = [ "man:intel_lpmd(8)" ];

      unitConfig = {
        ConditionVirtualization = "no";
        StartLimitIntervalSec = 200;
        StartLimitBurst = 5;
      };

      serviceConfig = {
        Type = "dbus";
        SuccessExitStatus = 2;
        BusName = "org.freedesktop.intel_lpmd";
        ExecStart = "${pkg}/bin/intel_lpmd --systemd --dbus-enable ${optionalString cfg.debug "--loglevel=debug"}";
        ExecStartPost = "${pkg}/bin/intel_lpmd_control ${cfg.mode}";
        Restart = "on-failure";
        RestartSec = 30;
        PrivateTmp = true;
      };

      wantedBy = [
        "multi-user.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];

      after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];

      aliases = [ "org.freedesktop.intel_lpmd.service" ];
    };

    environment.systemPackages = [ pkg ];
  };
}
