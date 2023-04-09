# import packages
import pandas as pd
import plotly.express as px
import plotly.graph_objs as go
import plotly.io as pio
import plotly.subplots as sp
import requests
from shroomdk import ShroomDK

# set plotly default theme
pio.templates.default = 'plotly_white'
# read api key and assign to a variable
with open('/Users/phu/FlipsideCrypto/api_key.txt') as f:
    api_key = f.read()
sdk = ShroomDK(api_key)

# define a function to read sql and get query result set with shroomdk
def get_query_result(sql_file_path:str):
    with open(sql_file_path) as f:
        sql = f.read()
    query_result_set = sdk.query(sql)

    return query_result_set.records