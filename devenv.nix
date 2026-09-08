{ pkgs, ... }:

{
  env = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    MINIFLARE_WORKERD_PATH = toString (import ./nix/preview-runtime.nix { inherit pkgs; });
  };

  packages = with pkgs; [
    just
    elmPackages.elm-format
    yaml-language-server
    package-version-server
    vscode-css-languageserver
    vscode-json-languageserver
  ];

  languages = {
    elm = {
      enable = true;
      lsp.enable = true;
    };
    haskell = {
      enable = true;
      package = pkgs.haskellPackages.ghcWithPackages (p: [
        p.hakyll
        p.pandoc
        p.aeson
      ]);
      cabal.enable = true;
      lsp.enable = true;
      stack.enable = true;
    };
    javascript = {
      enable = true;
      package = pkgs.nodejs_24;
      corepack.enable = true;
    };
    python = {
      enable = true;
      version = "3.14";
    };
  };
}
