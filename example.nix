{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages =
    # or home.packages
    [
      # ...
    ]
    # construct a list from the output attrset
    ++ (inputs.nix-gaming.lib.legendaryBuilder pkgs
      {
        games = {
          rocket-league = {
            # find names with `legendary list`
            desktopName = "Rocket League";

            # find out on lutris/winedb/protondb
            tricks = ["dxvk" "win10"];

            # google "<game name> logo"
            icon = pkgs.fetchurl {
              # original url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
              url = "https://user-images.githubusercontent.com/36706276/203341314-eaaa0659-9b79-4f40-8b4a-9bc1f2b17e45.png";
              name = "rocket-league.png";
              sha256 = "0a9ayr3vwsmljy7dpf8wgichsbj4i4wrmd8awv2hffab82fz4ykb";
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
          wine = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg;
        };
      });
}
