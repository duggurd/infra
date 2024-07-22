let 
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = with pkgs; [ 
    terraform
    kubectl
    openssl

    (python311.withPackages(ps: with ps; [
      ipykernel
      ipython
      jupyter
      notebook

      build
      pandas
      minio
      clickhouse-connect
    ]))
  ];
  shellhook = "source .env";
}
