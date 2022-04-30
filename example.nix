inputs: let
  rocket-league = inputs.self.lib.legendaryBuilder {
    games = {
      rocket-league = {
        desktopName = "Rocket League";
        tricks = ["dxvk" "win10"];
        icon = builtins.fetchurl {
          url = "https://www.pngkey.com/png/full/16-160666_rocket-league-png.png";
          name = "rocket-league.png";
          sha256 = "09n90zvv8i8bk3b620b6qzhj37jsrhmxxf7wqlsgkifs4k2q8qpf";
        };
        discordIntegration = false;
      };
    };

    opts = {
      wine = packages.wine-tkg;
      inherit (packages) wine-discord-ipc-bridge;
    };
  };
in
  rocket-league
