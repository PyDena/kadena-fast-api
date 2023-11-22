import coin

class WizArenaTest:
    def __init__(self):
        self.MINTED_POST_COUNT_KEY = "minted-post-count-key"
        self.MINTED_COUNT_KEY = "minted-count-key"
        self.NFTS_COUNT_KEY = "nfts-count-key"
        self.VOLUME_PURCHASE_COUNT = "volume_purchase_count"
        self.MINT_CHAIN_ID_KEY = "mint-chain-id-key"
        self.BUYIN_KEY = "buyin-key"
        self.FEE_KEY = "fee-key"
        self.ADMIN_KEYSET = "free.wizarena-test-keyset"
        self.ADMIN_ADDRESS = "k:90f45921e0605560ace17ca8fbbe72df95ba7034abeec7a8a7154e9eda7114eb"
        self.MAXIMUM_SUPPLY = 1024
        self.MAX_ITEMS_PER_OWNER = "max-items-per-owner"
        self.WIZ_BANK = ("wiz-bank" "Account holding prizes")
        self.WIZ_REVEAL = "wiz-reveal"
    def PRIVATE(self):
        """
        can only be called from a private context
        """
        return True
    def ACCOUNT_GUARD(self, account:str):
        """Verifies account meets format and belongs to caller"""
        assert account.startswith("k:")
        assert_guard(coin.details(account).guard)
    def OWNER(self, account:str, id:str):
        nft_owner = self.nfts.query(id).owner
        assert nft_owner == account
        self.ACCOUNT_GUARD(account)
    def ADMIN(self):
        assert_keyset self.ADMIN_KEYSET
        self.PRIVATE()
        self.ACCOUNT_GUARD(self.ADMIN_KEYSET)
    @event
    def wiz_buy(self, id:str, buyer:str, seller:str, price:float):
