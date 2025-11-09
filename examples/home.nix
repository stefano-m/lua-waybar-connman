{ pkgs, config, lib, home, specialArgs, ... }@allArgs:

{

  programs.waybar.enable = true;
  programs.waybar.settings.mainBar = {

    modules-right = [
      "custom/connman"
    ];

    "custom/connman" = {
      exec = "${pkgs.luaPackages.waybar_connman}/bin/waybar_connman run";
      format = "{icon}  {text}";
      format-icons = {
        "wifi" = " ";
        "ethernet" = "🌐";
        "offline" = "⚠";
        "quit" = "☹";
      };
      return-type = "json";
      restart-interval = 60;
      tooltip = true;
      hide-empty-text = true;
    };

  };

  programs.waybar.style = ''
    #custom-connman {
      color: @blue;
    }

    #custom-connman.error,
    #custom-connman.quit {
      color: @red;
    }

    #custom-connman.disconnected {
        color: @yellow;
    }
  '';

}
