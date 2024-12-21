import math
import json

def create_query_from_json_schema(file_path: str):
    """
        file_path: str, ex- dbt/finn/models/bronze/ad_metadata/job_fulltime_structure.json
    """
    with open(file_path, "r") as f:
        structure = json.load(f)

    cols = []

    for (k, v) in structure["json_structure(docs)"][0].items():
        # single value
        if v == "VARCHAR":
            cols.append(f'(docs->>"$.{k}")::VARCHAR AS {k.lower()}')
        elif isinstance(v, str):
            cols.append(f'(docs->"$.{k}")::{v} AS {k.lower()}')
        
        # dicts
        elif isinstance(v, dict):
            for (key, value) in v.items():
                col_name = "_".join([k, key])
                cols.append(f'(docs->"$.{k}.{key}")::{value} AS {col_name}')

        # lists
        elif isinstance(v, list):
            # lists of single values
            if isinstance(v[0], str):
                cols.append(f'(docs->"$.{k}")::{v[0]}[] AS {k}')
            
            # lists of dicts
            elif isinstance(v[0], dict):
                inner_struct = ",".join([f'"{key}" {value}' for key, value in v[0].items()])
                struct = f"({inner_struct})[]"
                cols.append(f'(docs->"$.{k}")::STRUCT{struct} AS {k}')

    max_len = max([len(col.split("::")[0]) for col in cols])
    spaces = math.ceil(max_len)+4

    cols_with_tabs = [col.split("::")[0] + (spaces-math.ceil(len(col.split("::")[0])))*' ' + "::" + col.split("::")[1] for col in cols]

    print(*cols_with_tabs, sep=",\n")