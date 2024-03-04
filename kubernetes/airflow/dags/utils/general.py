import os 
from base64 import b64decode

def decode_b64_secret_from_env(env_var):
    from base64 import b64decode
    secret = os.environ.get(env_var)
    assert env_var is not None, f"{env_var} not found!"

    return str(b64decode(secret), encoding="utf-8")