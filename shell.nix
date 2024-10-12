let 
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = with pkgs; [ 
    terraform
    kubectl
    openssl

    (python311.withPackages(ps: with ps; [
      # all deps are dev deps
      ipykernel
      ipython
      jupyter
      notebook

      s3fs
      # build
      pandas
      minio
      # clickhouse-connect
      sqlalchemy
      psycopg2
      pyarrow
    ]))
  ];
  shellhook = "source .env";
}
