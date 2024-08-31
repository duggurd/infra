import boto3
from botocore.exceptions import ClientError
import requests

import csv 
import io

def get_secret():
    secret_name = "alphavantage"
    region_name = "eu-north-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']

    return secret

def lambda_handler(event, context):
    api_key = get_secret()
    url = "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol={symbol}&apikey={api_key}&datatype=csv"

    symbols = event["symbols"]

    for symbol in symbols:
        req_url = url.format(symbol=symbol, api_key=api_key) 
        
        resp = requests.get(req_url)

        if resp.ok:
            # print(resp.content)
            reader = csv.reader(io.TextIOWrapper(io.BytesIO(resp.content)))
            for row in reader:
                print(row)

        else: 
            raise Exception(f"API request failed 8{resp.status_code}: {resp.content}")