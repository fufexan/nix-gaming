{
  environment.systemPackages =
    # or home.packages
    [
      # ...
    ]
    # construct a list from the output attrset
    ++ builtins.attrValues (inputs.nix-gaming.lib.legendaryBuilder
      {
        inherit (pkgs) system;

        games = {
          rocket-league = {
            # find names with `legendary list`
            desktopName = "Rocket League";

            # find out on lutris/winedb/protondb
            tricks = ["dxvk" "win10"];

            # google "<game name> logo"
            icon = builtins.fetchurl {
              url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
              name = "rocket-league.png";
              sha256 = "09n90zvv8i8bk3b620b6qzhj37jsrhmxxf7wqlsgkifs4k2q8qpf";
            };

            # if you don't want winediscordipcbridge running for this game
            discordIntegration = false;
            # if you dont' want to launch the game using gamemode
            gamemodeIntegration = false;

            preCommands = ''
              echo "the game will start!"
            '';

            postCommands = ''
              echo "the game has stopped!"
            '';
          };
        };

        opts = {
          # same options as above can be provided here, and will be applied to all games
          # NOTE: game-specific options take precedence
          wine = packages.wine-tkg;
        };
      });
}
