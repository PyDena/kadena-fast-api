(module wiz-arena-test ADMIN
    "Wizards Arena NFTs"
  
      (use coin)
    ; --------------------------------------------------------------------------
   ; Constants
  ; --------------------------------------------------------------------------
  
      (defconst MINTED_POST_COUNT_KEY "minted-post-count-key")
      (defconst MINTED_COUNT_KEY "minted-count-key")
      (defconst NFTS_COUNT_KEY "nfts-count-key")
      (defconst VOLUME_PURCHASE_COUNT "volume_purchase_count")
      (defconst MINT_CHAIN_ID_KEY "mint-chain-id-key")
      (defconst BUYIN_KEY "buyin-key")
      (defconst FEE_KEY "fee-key")
      (defconst ADMIN_KEYSET "free.wizarena-test-keyset")
      (defconst ADMIN_ADDRESS "k:90f45921e0605560ace17ca8fbbe72df95ba7034abeec7a8a7154e9eda7114eb")
      (defconst MAXIMUM_SUPPLY 1024)
      (defconst MAX_ITEMS_PER_OWNER "max-items-per-owner")
      (defconst WIZ_BANK:string "wiz-bank" "Account holding prizes")
      (defconst WIZ_REVEAL "wiz-reveal")
  
  ; --------------------------------------------------------------------------
  ; Capabilities
  ; --------------------------------------------------------------------------
  
      (defcap PRIVATE ()
          @doc "can only be called from a private context"
          true
      )
  
      ;; checks that the transaction owner
      (defcap ACCOUNT_GUARD(account:string)
          @doc "Verifies account meets format and belongs to caller"
          (enforce (= "k:" (take 2 account)) "For security, only support k: accounts")
          (enforce-guard (at "guard" (coin.details account)))
      )
  
      ;; checks the owner of the nft
      (defcap OWNER (account:string id:string)
          @doc "Enforces that an account owns the nft"
          (let
              (
                  (nft-owner (at "owner" (read nfts id ["owner"])))
              )
              (enforce (= nft-owner account) "Account is not owner of the NFT")
              (compose-capability (ACCOUNT_GUARD account))
          )
      )
  
      (defcap ADMIN() ; Used for admin functions
          @doc "Only allows admin to call these"
          (enforce-keyset ADMIN_KEYSET)
          (compose-capability (PRIVATE))
          (compose-capability (ACCOUNT_GUARD ADMIN_ADDRESS))
      )
  
      (defcap WIZ_BUY (id:string buyer:string seller:string price:decimal)
          @doc "Emitted event whent a Wizard is purchased"
          @event true
      )
  
      (defcap WITHDRAW_PRIZE (winner:string prize:decimal)
          @event true
      )
  
      ; --------------------------------------------------------------------------
    ; Can only happen once
    ; --------------------------------------------------------------------------
  
      (defun initialize ()
          @doc "Initialize the contract the first time its loaded "
          (insert counts MINTED_POST_COUNT_KEY {"count": 0})
          (insert counts MINTED_COUNT_KEY {"count": 0})
          (insert counts NFTS_COUNT_KEY {"count": 0})
          (insert volume VOLUME_PURCHASE_COUNT {"count": 0.0})
          (insert values MINT_CHAIN_ID_KEY {"value": "1"})
          (insert fee FEE_KEY {"fee": 7.0})
          (insert max-items MAX_ITEMS_PER_OWNER {"max": 0})
          (insert buyin BUYIN_KEY {"buyin": 3.0})
  
          (insert values WIZ_REVEAL {"value": "0"})
  
          (coin.create-account WIZ_BANK (create-module-guard "wiz-holdings"))
          (create-account WIZ_BANK (create-module-guard "wiz-holdings"))
      )
  
   ; --------------------------------------------------------------------------
    ; Schema and tables
    ; --------------------------------------------------------------------------
  
      ;;;; SCHEMAS AND TABLES ;;;;;
      (defschema nft-main-schema
          @doc "Stores core information about each nft"
          id:string
          ref:string
          created:time
          traits:object
          owner:string
          name:string
      )
  
      ; key id, value rank
      (defschema nft-rank-schema
          @doc "Store rank for ech nft"
          id:string
          rank:integer
      )
  
      (defschema nft-listed-schema
          @doc "stores info about list and price of nft"
          id:string
          listed:bool
          price:decimal
      )
  
      (defschema creation-schema
          @doc "Initial nft creation"
          ref:string
          traits:object
          name:string
      )
  
      (defschema account-minted-schema
          @doc "keeps track of how many nfts an account has minted"
          minted:integer
      )
  
      (defschema counts-schema
          @doc "Basic schema used for counting things"
          count:integer
      )
  
      (defschema volume-schema
          @doc "Basic schema used for counting volume"
          count:decimal
      )
  
      (defschema values-schema
          @doc "Basic schema used for storing basic values"
          value:string
      )
  
      (defschema fee-schema
          @doc "Fee schema"
          fee:decimal
      )
  
      (defschema max-items-schema
          @doc "Max items schema during whitelist mint time"
          max:integer
      )
  
      (defschema token-schema
          balance:decimal
          guard:guard
      )
  
      (defschema tournament-sub-schema
          round:string
          idnft:string
          address:string
      )
  
      (defschema buyin-schema
          @doc "Buyin schema"
          buyin:decimal
      )
  
      (defschema prizes-schema
          balance:decimal
      )
  
      (deftable nfts:{nft-main-schema})
      (deftable nfts-market:{nft-listed-schema})
      (deftable nfts-rank:{nft-rank-schema})
      (deftable creation:{creation-schema})
      (deftable account-minted:{account-minted-schema})
      (deftable counts:{counts-schema})
      (deftable values:{values-schema})
      (deftable fee:{fee-schema})
      (deftable volume:{volume-schema})
      (deftable max-items:{max-items-schema})
      (deftable token-table:{token-schema})
      (deftable tournaments:{tournament-sub-schema})
      (deftable buyin:{buyin-schema})
      (deftable prizes:{prizes-schema})
  
   ; --------------------------------------------------------------------------
    ; STATE MODIFYING FUNCTIONS, REQUIRE CAPABILITIES
    ; --------------------------------------------------------------------------
  
      (defun create-account:string (account:string guard:guard)
        @doc "create new account"
        (enforce-reserved account guard)
        (insert token-table account {
            "balance": 0.0,
            "guard": guard
        })
      )
  
      (defun enforce-reserved:bool
      ( accountId:string
        guard:guard )
      @doc "Enforce reserved account name protocols."
      (let ((r (check-reserved accountId)))
        (if (= "" r) true
          (if (= "k" r)
            (enforce
              (= (format "{}" [guard])
                 (format "KeySet {keys: [{}],pred: keys-all}"
                         [(drop 2 accountId)]))
              "Single-key account protocol violation")
            (enforce false
              (format "Unrecognized reserved protocol: {}" [r]))))))
  
      (defun check-reserved:string (accountId:string)
          " Checks ACCOUNT for reserved name and returns type if \
          \ found or empty string. Reserved names start with a \
          \ single char and colon, e.g. 'c:foo', which would return 'c' as type."
          (let ((pfx (take 2 accountId)))
            (if (= ":" (take -1 pfx)) (take 1 pfx) "")))
  
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;:;;;;;;; NFT CREATION , ADMIN ONLY ;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
      (defun create-all-wizards (objects-list:list)
          @doc "take a list of multiple wizards, and create each wizard"
          (with-capability (ADMIN)
              (map
                  (create-wizards)
                  objects-list
              )
          )
      )
  
      (defun create-wizards (item-list:object)
          @doc "take a list of traits, to create a wizard"
          (require-capability (ADMIN))
          (let
              (
                  (id (int-to-str 10(get-count NFTS_COUNT_KEY)))
                  (wizcount (get-count NFTS_COUNT_KEY))
              )
              (enforce (<= wizcount MAXIMUM_SUPPLY) "can't create over than 1024 wizards")
              (insert creation id
                  {"ref": (at "ref" item-list),
                  "traits": (at "traits" item-list),
                  "name": (at "name" item-list)}
              )
          )
          (increase-count NFTS_COUNT_KEY)
      )
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;; MINT FUN ;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
      (defun set-max-items(max:integer)
          @doc "Set the max items per address"
          (with-capability (ADMIN)
              (update max-items MAX_ITEMS_PER_OWNER {"max": max})
          )
      )
  
      (defun get-wizards (owner:string amount:integer)
          @doc "Mint part 1"
          (enforce (>= amount 1) "Must mint at least 1 wizard")
          (let (
                  (wiz-minted (get-count MINTED_COUNT_KEY))
                  (wiz-created (get-count NFTS_COUNT_KEY))
                  (max-items (get-max-items))
              )
              (enforce (> max-items 0) "Too early to mint")
              (enforce (<= (+ wiz-minted amount) wiz-created) "Tried to mint more wiz then available! Please reduce the amount")
              (with-default-read account-minted owner
                  {"minted": 0}
                  {"minted":= minted }
                  (enforce (>= (- max-items amount) minted) "Exceed max mint per wallet")
              )
          )
          (with-default-read account-minted owner
            {"minted": 0}
            {"minted":= minted }
            (write account-minted owner {"minted": (+ minted amount)})
          )
          (with-capability (ACCOUNT_GUARD owner)
              (with-capability (PRIVATE)
                  (map
                      (get-wizard owner)
                      (make-list amount 1)
                  )
              )
          )
      )
  
      (defun get-wizard (owner:string number:integer)
          @doc "Mint part 2"
          (enforce (= number 1) "Number enforced to be 1 to avoid confusion but allow mapping to work")
          (require-capability (PRIVATE))
          (require-capability (ACCOUNT_GUARD owner))
          (let (
                  (id (id-for-new-wizard))
              )
              (let (
                      (data (get-latest-wizard-data id))
                  )
                  (mint-wizard id {
                      "id": id,
                      "ref": (at "ref" data),
                      "created": (at "block-time" (chain-data)),
                      "traits": (at "traits" data),
                      "owner": owner,
                      "name": (at "name" data)
                  })
              )
          )
          (increase-count MINTED_COUNT_KEY)
      )
  
      (defun mint-wizard (id:string data:object)
          @doc "Mint part 3"
          (require-capability (PRIVATE))
          (insert nfts id data)
          (insert nfts-market id {
              "id": id,
              "price": 0.0,
              "listed": false
          })
          (increase-count MINTED_POST_COUNT_KEY)
      )
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;; MARKTEPLACE FUN ;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
      (defun list-wizard (sender:string id:string price:decimal)
          @doc "list a wizard on marketplace"
          (enforce (> price 0.0) "amount must be greater then 0")
          (let (
                  (data (get-wizard-fields-for-id (str-to-int id)))
              )
              (enforce (= (at "listed" data) false) "this wizard is already listed")
          )
          (with-capability (OWNER sender id)
              (update nfts-market id {"listed": true, "price": price})
          )
      )
  
      (defun delist-kactus (sender:string id:string)
          @doc "delist a wizard on marketplace"
          (let (
                  (data (get-wizard-fields-for-id (str-to-int id)))
              )
              (enforce (= (at "listed" data) true) "this wizard is not listed")
          )
          (with-capability (OWNER sender id)
              (update nfts-market id {"listed": false, "price": 0.0})
          )
      )
  
      (defun buy-wizard (id:string newowner:string)
          @doc "buy a wizard from marketplace"
          (let (
                  (currentowner (read nfts id ['owner]))
                  (market-data (read nfts-market id ['listed 'price]))
              )
              (enforce (= (at "listed" market-data) true) "this wizard is not listed")
              (enforce (> (at "price" market-data) 0.0) "the price is not valid")
              (enforce (!= (at "owner" currentowner) newowner) "the buyer can't be the owner")
              (let (
                      (fee (/ (* (get-fee) (at "price" market-data)) 100))
                  )
                  (with-capability (ACCOUNT_GUARD newowner)
                    (install-capability (coin.TRANSFER newowner (at "owner" currentowner) (- (at "price" market-data) fee)))
                    (coin.transfer newowner (at "owner" currentowner) (- (at "price" market-data) fee))
                    (install-capability (coin.TRANSFER newowner ADMIN_ADDRESS fee))
                    (coin.transfer newowner ADMIN_ADDRESS fee)
                    (update nfts id {
                      "owner": newowner
                    })
                    (update nfts-market id {
                      "price": 0.0,
                      "listed": false
                    })
                    (emit-event (WIZ_BUY id newowner (at "owner" currentowner) (at "price" market-data)))
                    (with-capability (PRIVATE)
                        (increase-volume-by VOLUME_PURCHASE_COUNT (at "price" market-data))
                    )
                  )
              )
          )
      )
  
      (defun increase-volume-by(key:string amount:decimal)
          @doc "Increases count of a key in a table by 1"
          (require-capability (PRIVATE))
          (update volume key
              {"count": (+ amount (get-volume))}
          )
      )
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;; TOURNAMENT  ;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
      (defun subscribe-tournament (id:string round:string idnft:string address:string)
          @doc "Subscribe a wizard to tournament"
          (with-default-read tournaments id
              {"idnft": ""}
              {"idnft":= idnft }
              (enforce (= (length idnft) 0) "Already subscribed to this tournament")
          )
          (let (
                  (halfbuyin (/ (get-buyin) 2))
              )
  
              (with-capability (OWNER address idnft)
                  (install-capability (coin.TRANSFER address ADMIN_ADDRESS halfbuyin))
                  (coin.transfer address ADMIN_ADDRESS halfbuyin)
                  (install-capability (coin.TRANSFER address WIZ_BANK halfbuyin))
                  (coin.transfer address WIZ_BANK halfbuyin)
                  (insert tournaments id {
                      "round": round,
                      "idnft": idnft,
                      "address": address
                  })
                  (with-default-read token-table WIZ_BANK
                    {"balance": 0.0}
                    {"balance":= oldbalance }
                    (update token-table WIZ_BANK {"balance": (+ oldbalance halfbuyin)})
                  )
              )
          )
      )
  
      (defun set-prizes (winners:list)
          (with-capability (ADMIN)
              (map
                  (set-prize)
                  winners
              )
          )
      )
  
      (defun set-prize (item:object)
          (require-capability (ADMIN))
  
          (with-default-read prizes (at "address" item)
            {"balance": 0.0}
            {"balance":= oldbalance }
            (write prizes (at "address" item) {"balance": (+ oldbalance (at "prize" item))})
          )
      )
  
      (defun check-address-for-prize (address:string)
          (at "balance" (read prizes address ["balance"]))
      )
  
      (defun withdraw-prize (account:string)
          (with-capability (ACCOUNT_GUARD account)
              (with-default-read prizes account
                {"balance": 0.0}
                {"balance":= oldbalance }
                (enforce (> oldbalance 0.0) "you already withdrawn your prize")
                (install-capability (coin.TRANSFER WIZ_BANK account oldbalance))
                (coin.transfer WIZ_BANK account oldbalance)
                (write prizes account {"balance": 0.0})
                (emit-event (WITHDRAW_PRIZE account oldbalance))
  
                (with-default-read token-table WIZ_BANK
                  {"balance": 0.0}
                  {"balance":= wizbalance }
                  (update token-table WIZ_BANK {"balance": (- wizbalance oldbalance)})
                )
              )
          )
      )
  
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;; GENERIC FUN ;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
      ; free kactus from admin to user
      (defun transfer:string
          ( id:string
            sender:string
            receiver:string
            amount:decimal
          )
          @doc " Transfer to an account, failing if the account to account does not exist. "
          (enforce (= 1.0 amount) "Only 1 kactus can be transferred")
          (enforce (= sender ADMIN_ADDRESS) "Can only send from admin account for now")
          (with-capability (ADMIN)
              (with-capability (OWNER sender id)
                  (update nfts id {"owner": receiver})
              )
          )
      )
  
      (defun increase-count(key:string)
          @doc "Increases count of a key in a table by 1"
          (require-capability (PRIVATE))
          (update counts key
              {"count": (+ 1 (get-count key))}
          )
      )
  
      (defun set-value(key:string value:string)
          @doc "Sets the value for a key to store in a table"
          (with-capability (ADMIN)
              (update values key
                  {"value": value}
              )
          )
      )
  
      (defun set-buyin(buyin-value:decimal)
          @doc "Set the buyin"
          (with-capability (ADMIN)
              (update buyin BUYIN_KEY {"buyin": buyin-value})
          )
      )
  
      (defun set-ranks(ranks:list)
          (with-capability (ADMIN)
              (map
                  (set-rank)
                  ranks
              )
          )
      )
  
      (defun set-rank(rank:object)
          (require-capability (ADMIN))
          (insert nfts-rank (at "id" rank)
              {"id": (at "id" rank),
              "rank": (at "rank" rank)}
          )
      )
  
      ;;;;;; NON STATE MODIFYING HELPER FUNCTIONS ;;;;;;;;;
      
      (defun get-buyin()
          (at "buyin" (read buyin BUYIN_KEY ["buyin"]))
      )
  
      (defun get-fee()
          (at "fee" (read fee FEE_KEY ["fee"]))
      )
  
      (defun get-count (key:string)
          @doc "Gets count for key"
          (at "count" (read counts key ['count]))
      )
  
      (defun get-value (key:string)
          @doc "Gets value for a key"
          (at "value" (read values key ['value]))
      )
  
      (defun get-max-items()
          (at "max" (read max-items MAX_ITEMS_PER_OWNER ["max"]))
      )
  
      (defun get-latest-wizard-data (id:string)
          (require-capability (PRIVATE))
          (let (
                  (minted-count (get-count MINTED_COUNT_KEY))
                  (created-count (get-count NFTS_COUNT_KEY))
              )
              (enforce (< 0 created-count) "no wizard created")
              (enforce (< minted-count created-count) "all wizard minted")
              (let (
                      (data (read creation id ['ref 'traits 'name]))
                  )
                  data
              )
          )
      )
  
      (defun id-for-new-wizard ()
          @doc "Returns an id for a new kactus to be minted"
          (int-to-str 10 (get-count MINTED_POST_COUNT_KEY))
      )
  
      (defun read-account-minted (address:string)
          (at "minted" (read account-minted address ['minted]))
      )
  
      (defun wizard-owned-by (owner:string)
          @doc "all ids wizard from owner"
          (select nfts ['id] (where "owner" (= owner)))
      )
  
      (defun get-wizard-fields-for-ids (ids:list)
          @doc "Return fields for a list of ids"
          (map
              (get-wizard-fields-for-id)
              ids
          )
      )
  
      (defun get-wizard-fields-for-id (id:integer)
          @doc "Return the fields for a given id"
          (let (
                  (reveal (get-value WIZ_REVEAL))
                  (info-market (read nfts-market (int-to-str 10 id)))
              )
              (if
                  (!= reveal "0")
                  (if
                      (= reveal "1")
                      (let (
                              (info (read nfts (int-to-str 10 id)))
                          )
                          (+ info info-market)
                      )
                      (let (
                              (info (read nfts (int-to-str 10 id)))
                              (rank (read nfts-rank (int-to-str 10 id) ['rank]))
                          )
                          (let
                              (
                                  (b (+ info info-market))
                              )
                              (+ b rank)
                          )
                      )
                  )
                  (let (
                          (info (read nfts (int-to-str 10 id) ['created 'owner 'name 'id]))
                      )
                      (+ info info-market)
                  )
              )
          )
      )
  
      (defun all-wizards ()
          @doc "Returns all the ids"
          (keys nfts)
      )
  
      (defun get-volume ()
          @doc "get volume of purchase"
          (at "count" (read volume VOLUME_PURCHASE_COUNT ['count]))
      )
  
      (defun get-subscription (id:string)
          @doc "Check if id is subscribed for tournament"
          (read tournaments id)
      )
  
      (defun get-all-subscription-for-tournament (idtournament:string)
          @doc "Get all subscribers for a single tournament"
          (select tournaments (where "round" (= idtournament)))
      )
  
      (defun get-prize ()
          (at "balance" (read token-table WIZ_BANK ['balance]))
      )
  
      ;;;;;; GENERIC HELPER FUNCTIONS ;;;;;;;;;;
  
      (defun curr-chain-id ()
          @doc "Current chain id"
          (at "chain-id" (chain-data))
      )
  )
  
  
  ;(create-table nfts)
      ;(create-table nfts-rank)
      ;(create-table nfts-market)
      ;(create-table creation)
      ;(create-table account-minted)
      ;(create-table counts)
      ;(create-table values)
      ;(create-table fee)
      ;(create-table volume)
      ;(create-table max-items)
      ;(create-table token-table)
      ;(create-table tournaments)
      ;(create-table buyin)
      ;(create-table prizes)
      ;(initialize)
      
  