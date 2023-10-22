{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "flake-utils";
  };
  outputs = { self, flake-utils, nixpkgs, ... }:
    flake-utils.lib.simpleFlake {
      inherit self nixpkgs;
      name = "xray-server";
      shell = { pkgs, ... }: pkgs.mkShell {
        name = "xray-server-shell";
        packages = with pkgs; [
          terraform
          awscli2
          ansible
        ];
      };
    };
}
