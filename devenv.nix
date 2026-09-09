{ pkgs, ... }:

{
  env = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    MINIFLARE_WORKERD_PATH = toString (
      pkgs.writeShellScript "asai-workerd" ''
        exec ${pkgs.stdenv.cc.bintools.dynamicLinker} \
          "$PWD/node_modules/@cloudflare/workerd-linux-${
            if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "64"
          }/bin/workerd" "$@"
      ''
    );
  };

  packages = with pkgs; [
    just
    ormolu
    nixfmt
    ruff
    poppler-utils
    python3Packages.fonttools
    python3Packages.brotli
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
