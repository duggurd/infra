# import psycopg2

# def get_latest_dates_pg():
#     hook = BaseHook.get_hook(conn_id="postgres-hyperjob")
#     conn = psycopg2.connect(
#         host=hook.host,
#         port=hook.port,
#         database=hook.schema,
#         user=hook.login,
#         password=hook.password
#     )
#     cursor = conn.cursor()

#     cursor.execute("SELECT MAX(date) FROM ingestion_dates")
#     latest_date = cursor.fetchone()[0]
#     cursor.close()
#     conn.close()
#     return latest_date