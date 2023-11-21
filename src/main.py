# Import FastAPI
from fastapi import FastAPI
import uvicorn
import response_models
import requests

title="PyDena | Kadena-Chainweb | Rest-API Server"
description = """
PyDena API helps you do awesome stuff. 🚀
"""
# Create an instance of the FastAPI application
app = FastAPI(title=title, description=description)


# Define a route at the root "/"
@app.get("/")
async def read_root():
    return {"message": "Welcome to the FastAPI server!"}


@app.get("/info")
async def get_chainweb_base_info() -> response_models.Info:
    info_url = "https://estats.chainweb.com/info"
    return response_models.Info(**requests.get(info_url).json())

@app.get("/cut")
async def get_current_cut() -> response_models.Cut:
    cut_url = "https://estats.chainweb.com/chainweb/0.0/mainnet01/cut"
    response = requests.get(cut_url)
    response_json:dict|list = response.json()
    hashes = {k: response_models.ChainCut(**v) for k, v in response_json.get("hashes").items()}
    response_json.update({"hashes":hashes})
    return response_models.Cut(**response_json)

@app.get("/stats")
async def get_chainweb_statistics() -> response_models.Stats:
    stats_url = "https://estats.chainweb.com/stats"
    response = requests.get(stats_url)
    response_json = response.json()
    return response_models.Stats(**response_json)

@app.get("/header/{min_height}/{max_height}")
async def get_headers(min_height:int, max_height:int) -> response_models.Header:
    header_url = f"https://estats.chainweb.com/chainweb/0.0/mainnet01/chain/14/header?minheight={min_height}&limit={max_height}"
    header_url_headers = {"Accept":"application/json;blockheader-encoding=object"}
    response = requests.get(header_url, headers=header_url_headers)
    response_json:dict|list = response.json()
    header_items = [response_models.HeaderItem(**item) for item in response_json.get("items")]
    response_json.update({"items":header_items})
    return response_models.Header(**response_json)

@app.get("/transactions/recent")
async def get_recent_transactions() -> list[response_models.Transaction]:
    recent_tx_url = "https://estats.chainweb.com/txs/recent"
    response = requests.get(recent_tx_url)
    return [response_models.Transaction(**tx) for tx in response.json()]

# The script can be run with Uvicorn using the command:
# uvicorn script_name:app --reload
# Check if the script is run directly (not imported)
if __name__ == "__main__":
    # Run the app with Uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
