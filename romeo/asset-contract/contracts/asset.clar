;; title: asset
;; version:
;; summary: sBTC dev release asset contract
;; description:

;; traits
;;
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; token definitions
;;
(define-fungible-token sbtc u21000000)

;; constants
;;
(define-constant err-invalid-caller (err u1))
(define-constant err-not-token-owner (err u2))

;; data vars
;;
(define-data-var contract-owner principal tx-sender)
(define-data-var bitcoin-wallet-public-key (optional (buff 33)) none)

;; public functions
;;
;; #[allow(unchecked_data)]
(define-public (set-bitcoin-wallet-public-key (public-key (buff 33)))
    (begin
        (try! (is-contract-owner))
        (ok (var-set bitcoin-wallet-public-key (some public-key)))
    )
)

;; #[allow(unchecked_data)]
(define-public (set-contract-owner (new-owner principal))
    (begin
        (try! (is-contract-owner))
        (ok (var-set contract-owner new-owner))
    )
)

;; #[allow(unchecked_data)]
(define-public (mint! (amount uint)
    (destination principal)
    (deposit-txid (buff 32))
    (burn-chain-height uint)
    (merkle-proof (list 14 (buff 32)))
    (tx-index uint)
    (tree-depth uint)
    (block-header (buff 80)))
    (begin
        (try! (is-contract-owner))
        (try! (verify-txid-exists-on-burn-chain deposit-txid burn-chain-height merkle-proof tx-index tree-depth block-header))
        (print deposit-txid)
        (ft-mint? sbtc amount destination)
    )
)

;; #[allow(unchecked_data)]
(define-public (burn! (amount uint)
    (owner principal)
    (withdraw-txid (buff 32))
    (burn-chain-height uint)
    (merkle-proof (list 14 (buff 32)))
    (tx-index uint)
    (tree-depth uint)
    (block-header (buff 80)))
    (begin
        (try! (is-contract-owner))
        (try! (verify-txid-exists-on-burn-chain withdraw-txid burn-chain-height merkle-proof tx-index tree-depth block-header))
        (print withdraw-txid)
        (ft-burn? sbtc amount owner)
    )
)

;; #[allow(unchecked_data)]
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin
		(asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) err-not-token-owner)
		(try! (ft-transfer? sbtc amount sender recipient))
		(match memo to-print (print to-print) 0x)
		(ok true)
	)
)

;; read only functions
;;
(define-read-only (get-bitcoin-wallet-public-key)
    (var-get bitcoin-wallet-public-key)
)

(define-read-only (get-name)
	(ok "sBTC")
)

(define-read-only (get-symbol)
	(ok "sBTC")
)

(define-read-only (get-decimals)
	(ok u8)
)

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance sbtc who))
)

(define-read-only (get-total-supply)
	(ok (ft-get-supply sbtc))
)

(define-read-only (get-token-uri)
	(ok (some u"https://assets.stacks.co/sbtc.pdf"))
)

;; private functions
;;
(define-private (is-contract-owner)
    (ok (asserts! (is-eq (var-get contract-owner) contract-caller) err-invalid-caller))
)

(define-read-only (verify-txid-exists-on-burn-chain (txid (buff 32)) (burn-chain-height uint) (merkle-proof (list 14 (buff 32))) (tx-index uint) (tree-depth uint) (block-header (buff 80)))
    (contract-call? .clarity-bitcoin-mini was-txid-mined burn-chain-height txid block-header { tx-index: tx-index, hashes: merkle-proof, tree-depth: tree-depth})
)
