import os 
from base64 import b64decode
import pandas as pd

def decode_b64_secret_from_env(env_var):
    from base64 import b64decode
    secret = os.environ.get(env_var)
    assert secret is not None, f"{secret} not found!"


    return str(b64decode(secret), encoding="utf-8")


def extract_nested_df_value(df: pd.DataFrame, new_column:str, column: str, key:str):
    if column not in df.columns:
        df[new_column] = None
    else:
        df[new_column] = df[column].apply(lambda x: x.get(key))


def extract_nested_df_values(df: pd.DataFrame, column:str, drop_column=False) -> pd.DataFrame:
    """Extracts values from dicts to different columns with prefix 'column_'
    
    if drop_column is True, the original column is dropped

    the column must be a dict
    """

    if column in df.columns:
        # get all distinct keys in the column
        keys = set()

        for row in df[column]:
            if isinstance(row, dict) and row is not None:
                keys.update(row.keys())

        for key in keys:
            df[f"{column}_{key}"] = df[column].apply(lambda x: x.get(key) if isinstance(x, dict) else pd.NA)


        if drop_column:
            df = df.drop(columns=[column])

    return df
