let 
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = [ 
    pkgs.terraform

    (pkgs.python311.withPackages(pkgs: with pkgs; [
      ipykernel
      ipython
      jupyter
      notebook

      pandas
      minio
      clickhouse-connect
    ]))
  ];
  shellhook = "source .env";
}
