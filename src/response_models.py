from pydantic import BaseModel, Field
from typing import List, Any, Dict, Optional


class Info(BaseModel):
    """
    The Info model contains essential data about a blockchain node,
    including its API version, supported chains, graph history,
    latest behavior height, and the total number of chains it interacts with.
    """

    nodeApiVersion: float = Field(..., description="The API version of the node.")
    nodeChains: List[int] = Field(
        ...,
        description="A list of integers representing the chains supported by the node.",
    )
    nodeGraphHistory: List[List[Any]] = Field(
        ...,
        description="A complex list structure representing the graph history of the node.",
    )
    nodeLatestBehaviorHeight: int = Field(
        ..., description="The latest behavior height of the node."
    )
    nodeNumberOfChains: int = Field(
        ..., description="The total number of chains the node interacts with."
    )
    nodeVersion: str = Field(..., description="The version string of the node.")


class ChainCut(BaseModel):
    """
    The ChainCut model provides information about a specific cut in the blockchain,
    including its height and hash.
    """

    height: int = Field(..., description="The height of the cut in the blockchain.")
    hash: str = Field(..., description="The hash of the cut.")


class Cut(BaseModel):
    """
    The Cut model represents a particular state of the blockchain with details like hashes,
    origin, weight, and height of the cut, along with unique identifiers.
    """

    hashes: Dict[int, ChainCut] = Field(
        ..., description="A dictionary mapping integer keys to ChainCut objects."
    )
    origin: Any = Field(..., description="The origin of the cut.")
    weight: str = Field(..., description="The weight of the cut.")
    height: int = Field(..., description="The height of the cut in the blockchain.")
    instance: str = Field(..., description="Instance information of the cut.")
    id: str = Field(..., description="The unique identifier of the cut.")

    class Config:
        arbitrary_types_allowed = True


class Stats(BaseModel):
    """
    The Stats model provides statistical information about the blockchain,
    like the total number of transactions and the amount of coins in circulation.
    """

    transactionCount: int = Field(
        ..., description="The total number of transactions processed."
    )
    coinsInCirculation: float = Field(
        ..., description="The total amount of coins in circulation."
    )


class HeaderItem(BaseModel):
    """
    The HeaderItem model describes the details of a block header in the blockchain,
    including its nonce, creation time, parent hash, and other relevant attributes.
    """

    nonce: str = Field(..., description="The nonce value of the block.")
    creationTime: int = Field(..., description="The creation time of the block.")
    parent: str = Field(..., description="The hash of the parent block.")
    adjacents: Dict[int, str] = Field(
        ...,
        description="A dictionary mapping adjacent block identifiers to their hashes.",
    )
    target: str = Field(..., description="The target hash of the block.")
    payloadHash: str = Field(..., description="The hash of the payload.")
    chainId: int = Field(
        ..., description="The ID of the chain to which the block belongs."
    )
    weight: str = Field(..., description="The weight of the block.")
    height: int = Field(..., description="The height of the block in the blockchain.")
    chainwebVersion: str = Field(
        ..., description="The version of the Chainweb protocol the block adheres to."
    )
    epochStart: int = Field(
        ..., description="The start of the epoch to which this block belongs."
    )
    featureFlags: int = Field(..., description="Feature flags for the block.")
    hash: str = Field(..., description="The unique hash of the block.")


class Header(BaseModel):
    """
    The Header model encapsulates a collection of block headers in the blockchain,
    providing a limit, a list of HeaderItems, and a reference to the next set of headers.
    """

    limit: int = Field(
        ..., description="The maximum number of header items to include."
    )
    items: List[HeaderItem] = Field(
        ...,
        description="A list of HeaderItem objects representing individual block headers.",
    )
    next: str = Field(..., description="A reference to the next set of headers.")


class Continuation(BaseModel):
    """
    The Continuation model represents continuation data in a transaction,
    detailing the steps involved, including any rollbacks, and other relevant data.
    """

    stepCount: int = Field(
        ..., description="The count of steps in the continuation process."
    )
    stepHasRollback: bool = Field(
        ...,
        description="Indicates whether any step in the continuation has a rollback.",
    )
    pactId: str = Field(
        ..., description="The identifier of the pact involved in the continuation."
    )
    executed: Any = Field(
        ..., description="Data regarding what has been executed in the continuation."
    )
    continuation: Any = Field(..., description="Continuation data.")
    yield_data: Dict = Field(
        ..., alias="yield", description="Data yielded from the continuation steps."
    )
    step: int = Field(
        ..., description="The current step number in the continuation process."
    )

    class Config:
        populate_by_name = True


class Transaction(BaseModel):
    """
    The Transaction model captures the details of a blockchain transaction,
    including its height, creation time, result, sender, code, and continuation data.
    """

    height: int = Field(
        ..., description="The block height at which the transaction occurs."
    )
    creationTime: str = Field(
        ..., description="The timestamp of the transaction's creation."
    )
    result: str = Field(..., description="The outcome of the transaction.")
    sender: str = Field(..., description="The identifier of the transaction's sender.")
    initialCode: Any = Field(
        ..., description="The initial code or command associated with the transaction."
    )
    code: Any = Field(..., description="The code executed in the transaction.")
    continuation: Any = Field(
        ..., description="Optional continuation data associated with the transaction."
    )
    requestKey: str = Field(
        ..., description="A unique key identifying the transaction request."
    )
    blockHash: str = Field(
        ..., description="The hash of the block containing the transaction."
    )
    previousSteps: Any = Field(
        ..., description="Information about previous steps in the transaction process."
    )
    chain: int = Field(
        ..., description="The chain number where the transaction takes place."
    )


class Payload(BaseModel):
    """
    The Payload model represents the payload data of a block in the blockchain,
    detailing the transactions, miner data, hashes, and coinbase information.
    """

    transactions: List[List[str]] = Field(
        ..., description="A list of transactions included in the payload."
    )
    minerData: str = Field(
        ..., description="Data pertaining to the miner of the block."
    )
    transactionsHash: str = Field(
        ..., description="The hash of the transactions included in the payload."
    )
    outputsHash: str = Field(
        ..., description="The hash of the outputs of the transactions."
    )
    payloadHash: str = Field(..., description="The overall hash of the payload.")
    coinbase: str = Field(..., description="The coinbase transaction data.")


class TransactionCode(BaseModel):
    """
    The TransactionCode model represents the detailed information of a blockchain transaction.
    It includes data such as the transaction's height in the blockchain, creation time,
    sender, and the specific codes involved. This model is essential for tracking transaction
    history and status within a blockchain network.
    """

    height: int = Field(
        ...,
        description="The block height at which the transaction occurs, indicating its position in the blockchain.",
    )
    creationTime: str = Field(
        ...,
        description="The timestamp of the transaction creation, typically in ISO 8601 format.",
    )
    result: str = Field(
        ...,
        description="The outcome of the transaction, such as 'success', 'failure', or custom status codes.",
    )
    sender: str = Field(
        ...,
        description="The identifier of the transaction's sender, such as a wallet address.",
    )
    initialCode: Any = Field(
        ...,
        description="Initial code or data associated with the transaction, format may vary.",
    )
    code: str = Field(
        ..., description="The executed code or command of the transaction."
    )
    continuation: Optional[Any] = Field(
        None,
        description="An optional field for continuation data, used in multi-step transactions.",
    )
    requestKey: str = Field(
        ..., description="A unique key identifying the transaction request."
    )
    blockHash: str = Field(
        ...,
        description="The hash of the block containing this transaction, serving as a unique identifier.",
    )
    previousSteps: Any = Field(
        ...,
        description="Data or metadata about previous steps in the transaction process, format may vary.",
    )
    chain: int = Field(
        ...,
        description="An identifier for the blockchain network or chain where the transaction is processed.",
    )


if __name__ == "__main__":
    import requests

    """info_url = "https://estats.chainweb.com/info"
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
    header = Header(**response_json)"""
    ...
