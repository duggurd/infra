import pandas as pd

from utils.general import extract_nested_df_values


def SEARCH_ID_REALESTATE_HOMES(df: pd.DataFrame) -> pd.DataFrame:
    df = common_metadata_df_cleaning(df)

    nested_columns = [
        "price_suggestion",
        "price_total",
        "price_shared_cost",
        "area_range",
        "area_plot",
        "price_range_suggestion",
        "price_range_total",
        "bedrooms_range",
    ]

    for nested_column in nested_columns:
        df = extract_nested_df_values(df, nested_column, True)

    return df

def SEARCH_ID_REALESTATE_LETTINGS(df: pd.DataFrame) -> pd.DataFrame:
    df = common_metadata_df_cleaning(df)

    nested_columns = [
        "price_suggestion",
        "price_total",
        "price_shared_cost",
        "area_range",
        "area_plot",
    ]

    for nested_column in nested_columns:
        df = extract_nested_df_values(df, nested_column, True)

    return df


def SEARCH_ID_CAR_USED(df: pd.DataFrame) -> pd.DataFrame:
    df = common_metadata_df_cleaning(df)
    
    nested_columns = [
        "price",
    ]

    for nested_column in nested_columns:
        df = extract_nested_df_values(df, nested_column, True)

    return df

def SEARCH_ID_JOB_FULLTIME(df: pd.DataFrame) -> pd.DataFrame:
    df = common_metadata_df_cleaning(df)

    if "deadline" in df.columns:
        df["deadline"] = pd.to_datetime(df["deadline"], unit="ms")
    else:
        df["deadline"] = pd.NA

    # validate schema and change dtypes to target dtypes
    
    return df


def SEARCH_ID_REALESTATE_NEWBUILDINGS(df: pd.DataFrame) -> pd.DataFrame: 
    df = common_metadata_df_cleaning(df)

    nested_columns = [
        "price_suggestion",
        "price_total",
        "price_shared_cost",
        "area_range",
        "area_plot",
        "bedrooms_range"
    ]

    for nested_column in nested_columns:
        df = extract_nested_df_values(df, nested_column, True)

    return df


def common_metadata_df_cleaning(df: pd.DataFrame, truncate_datetimes_to_ms: bool = True) -> pd.DataFrame:

    # Extract relevant data
    df = extract_nested_df_values(df, "coordinates", True)
    
    # Drop redundant data
    df = df.drop(
        columns=[
            "image", 
            "flags", 
            "labels", 
            "extras", 
            "service_documents", 
            "logo", 
            "styling", 
            "viewing_times", 
            "image_urls",
            "area"
        ], 
        errors="ignore"
    )

    # Format unix timestamps to dates
    if "timestamp" in df.columns:
        df["timestamp"] = pd.to_datetime(df["timestamp"], unit="ms")
    else: 
        df["timestamp"] = pd.NA
    
    if "published" in df.columns:
        df["published"] =  pd.to_datetime(df["published"], unit="ms")
    else:
        df["published"] = pd.NA

    df["y"] = df["timestamp"].dt.year
    df["m"] = df["timestamp"].dt.month

    df["ingestion_ts"] = pd.Timestamp.now()
    
    return df


