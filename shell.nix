let 
  pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  packages = with pkgs; [ 
    terraform
    kubectl
    openssl
    clickhouse-cli

    (python311.withPackages(ps: with ps; 
      let
        pyiceberg = buildPythonPackage rec {
        
          pname = "pyiceberg";
          version = "0.7.1 ";
          format = "wheel";
            
          src = fetchurl {
            url = "https://files.pythonhosted.org/packages/0c/71/1ec3ca0537112546f2896b40142102881634e0599f04ceeade26f3bb0d76/pyiceberg-0.7.1-cp311-cp311-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
            hash = "sha256-GFbF1kGXyTNYF7jPcIHkkLYBOFYj5ReMsJTuZF1Pskw=";
          };

          dependencies = [
            psycopg2
            sqlalchemy
            python
            mmh3
            requests
            click
            rich
            strictyaml
            pydantic
            sortedcontainers
            fsspec
            pyparsing
            zstandard
            tenacity
          ];
          doCheck = false;
        };
      in [
        # all deps are dev deps
        
        ipykernel
        ipython
        jupyter
        notebook

        pyiceberg
        s3fs
        # build
        pandas
        minio
        # clickhouse-connect
        sqlalchemy
        psycopg2
        pyarrow
        beautifulsoup4
        matplotlib
        # pyspark
      ]
    ))
  ];
  shellhook = "source .env";
}
