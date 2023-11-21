from pydantic import BaseModel, Field
from typing import Any
from base64 import urlsafe_b64decode, b64decode

class Info(BaseModel):
    nodeApiVersion:float
    nodeChains:list[int]
    nodeGraphHistory:list[list[int| list[list[int| list[int]]]]]
    nodeLatestBehaviorHeight:int
    nodeNumberOfChains:int
    nodeVersion:str

class ChainCut(BaseModel):
    height:int
    hash:str

class Cut(BaseModel):
    hashes:dict[int, ChainCut]
    origin:Any
    weight:str
    height:int
    instance:str
    id:str
    class Config:
        arbitrary_types_allowed = True

class Stats(BaseModel):
    transactionCount:int
    coinsInCirculation:float

class HeaderItem(BaseModel):
    nonce:str
    creationTime:int
    parent:str
    adjacents:dict[int, str]
    target:str
    payloadHash:str
    chainId:int
    weight:str
    height:int
    chainwebVersion:str
    epochStart:int
    featureFlags:int
    hash:str

class Header(BaseModel):
    limit:int
    items:list[HeaderItem]
    next:str

class Continuation(BaseModel):
    stepCount:int
    stepHasRollback:bool
    pactId:str
    executed:Any
    continuation:Any
    yield_data: dict = Field(..., alias='yield')
    step:int
    class Config:
        populate_by_name = True

class Transaction(BaseModel):
    height:int
    creationTime:str
    result:str
    sender:str
    initialCode:Any
    code:str|Any
    continuation:Continuation|Any
    requestKey:str
    blockHash:str
    previousSteps:Any
    chain:int


if __name__ == "__main__":
    import requests
    '''info_url = "https://estats.chainweb.com/info"
    response = requests.get(info_url)
    response_json = response.json()
    info = Info(**response_json)
    cut_url = "https://estats.chainweb.com/chainweb/0.0/mainnet01/cut"
    response = requests.get(cut_url)
    response_json = response.json()
    hashes = {k: ChainCut(**v) for k, v in response_json.get("hashes").items()}
    response_json.update({"hashes":hashes})
    stats_url = "https://estats.chainweb.com/stats"
    response = requests.get(stats_url)
    response_json = response.json()
    stats = Stats(**response_json)
    header_url = "https://estats.chainweb.com/chainweb/0.0/mainnet01/chain/14/header?minheight=4271947&limit=4271951"
    header_url_headers = {"Accept":"application/json;blockheader-encoding=object"}
    response = requests.get(header_url, headers=header_url_headers)
    response_json = response.json()
    header_items = [HeaderItem(**item) for item in response_json.get("items")]
    response_json.update({"items":header_items})
    header = Header(**response_json)'''
    running = True
    import time
    while running:
        recent_tx_url = "https://estats.chainweb.com/txs/recent"
        response = requests.get(recent_tx_url)
        for tx in response.json():
            transaction = Transaction(**tx)
            if transaction.continuation:
                print(transaction)
                running = False
        time.sleep(2)