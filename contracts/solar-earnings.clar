;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-funds (err u102))

;; Define data vars
(define-data-var total-earnings uint u0)

;; Define maps
(define-map participants principal 
    {
        shares: uint,
        earnings: uint,
        active: bool
    }
)

;; Add new participant
(define-public (add-participant (participant principal) (shares uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set participants participant {
                shares: shares,
                earnings: u0,
                active: true
            })
            (ok true)
        )
        err-owner-only
    )
)

;; Record new solar earnings
(define-public (record-earnings (amount uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (var-set total-earnings (+ (var-get total-earnings) amount))
            (distribute-earnings amount)
            (ok true)
        )
        err-owner-only
    )
)

;; Private function to distribute earnings
(define-private (distribute-earnings (amount uint))
    (let (
        (total-shares (get-total-shares))
    )
    (map-participants amount total-shares)
    )
)

;; Map through participants and distribute earnings
(define-private (map-participants (amount uint) (total-shares uint))
    (map-fn amount total-shares)
)

;; Function to get participant's earnings
(define-public (get-participant-earnings (participant principal))
    (match (map-get? participants participant)
        participant-data (ok (get earnings participant-data))
        err-not-found
    )
)

;; Function to withdraw earnings
(define-public (withdraw-earnings)
    (let (
        (participant-data (unwrap! (map-get? participants tx-sender) err-not-found))
        (earnings-amount (get earnings participant-data))
    )
    (if (> earnings-amount u0)
        (begin
            (map-set participants tx-sender 
                (merge participant-data {earnings: u0})
            )
            (stx-transfer? earnings-amount contract-owner tx-sender)
        )
        err-insufficient-funds
    ))
)

;; Read only functions
(define-read-only (get-total-earnings)
    (ok (var-get total-earnings))
)

(define-read-only (get-participant-shares (participant principal))
    (match (map-get? participants participant)
        participant-data (ok (get shares participant-data))
        err-not-found
    )
)

(define-private (get-total-shares)
    (default-to u0 
        (fold + 
            (map get-share-if-active 
                (map-get? participants)
            )
            u0
        )
    )
)

(define-private (get-share-if-active (participant-data {shares: uint, earnings: uint, active: bool}))
    (if (get active participant-data)
        (get shares participant-data)
        u0
    )
)
