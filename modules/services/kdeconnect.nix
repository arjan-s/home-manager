{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.services.kdeconnect;

in
{
  meta.maintainers = [ maintainers.adisbladis ];

  options = {
    services.kdeconnect = {
      enable = mkEnableOption "KDE connect";
      package = mkOption {
        type = types.package;
        default = pkgs.kdePackages.kdeconnect-kde;
        example = literalExpression "pkgs.plasma5Packages.kdeconnect-kde";
        description = "The KDE connect package to use";
      };

      indicator = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable kdeconnect-indicator service.";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      assertions = [
        (hm.assertions.assertPlatform "services.kdeconnect" pkgs platforms.linux)
      ];

      systemd.user.services.kdeconnect = {
        Unit = {
          Description = "Adds communication between your desktop and your smartphone";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
          ExecStart =
            if strings.versionAtLeast (versions.majorMinor cfg.package.version) "24.05" then
              "${cfg.package}/bin/kdeconnectd"
            else
              "${cfg.package}/libexec/kdeconnectd";
          Restart = "on-abort";
        };
      };
    })

    (mkIf cfg.indicator {
      assertions = [
        (hm.assertions.assertPlatform "services.kdeconnect" pkgs platforms.linux)
      ];

      systemd.user.services.kdeconnect-indicator = {
        Unit = {
          Description = "kdeconnect-indicator";
          After = [
            "graphical-session.target"
            "tray.target"
          ];
          PartOf = [ "graphical-session.target" ];
          Requires = [ "tray.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
          ExecStart = "${cfg.package}/bin/kdeconnect-indicator";
          Restart = "on-abort";
        };
      };
    })
  ];
}
