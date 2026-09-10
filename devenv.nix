{ pkgs, ... }:

{
  env = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    CHROMIUM_PATH = pkgs.lib.getExe pkgs.chromium;
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
    poppler-utils
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
        p.blaze-html
        p.clay
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
      package = pkgs.python314.withPackages (p: [
        p.fonttools
        p.brotli
        p.pytest
        p.pytest-playwright
        p.pytest-xdist
      ]);
      lsp.enable = true;
    };
  };

  git-hooks = {
    enable = true;
    hooks = {
      convco.enable = true;
      ruff.enable = true;
      shfmt = {
        enable = true;
        settings = {
          indent = 2;
          case-indent = true;
        };
      };
      nixfmt.enable = true;
      ormolu.enable = true;
      pyright.enable = true;
      shellcheck.enable = true;
      elm-format.enable = true;
    };
  };
}
