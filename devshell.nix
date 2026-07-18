{
  mkShell,
  nixd,
  alejandra,
  python3,
  basedpyright,
  ruff,
  prettierd,
  bash-language-server,
  sqlite,
  jq,
  curl,
  git,
  lua,
}:
mkShell {
  name = "reaper-flake dev shell";
  packages = [
    nixd
    alejandra

    (python3.withPackages
      (ps:
        with ps; [
          numpy
          black
          debugpy
        ]))
    basedpyright
    ruff

    bash-language-server
    prettierd

    sqlite
    jq
    curl
    git
    lua
  ];
}
