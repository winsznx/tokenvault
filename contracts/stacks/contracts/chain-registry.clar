;; TokenVault - Multi-asset custody with timelocks
(define-constant ERR-LOCKED (err u100))
(define-constant ERR-ALREADY-WITHDRAWN (err u101))

(define-map deposits
    { user: principal, deposit-id: uint }
    { token: principal, amount: uint, unlock-time: uint, withdrawn: bool }
)

(define-map deposit-counts { user: principal } { count: uint })

(define-public (deposit (token principal) (amount uint) (lock-duration uint))
    (let (
        (user-count (default-to u0 (get count (map-get? deposit-counts { user: tx-sender }))))
        (deposit-id user-count)
    )
        (map-set deposits { user: tx-sender, deposit-id: deposit-id } {
            token: token,
            amount: amount,
            unlock-time: (+ block-height lock-duration),
            withdrawn: false
        })
        (map-set deposit-counts { user: tx-sender } { count: (+ user-count u1) })
        (ok deposit-id)
    )
)

(define-public (withdraw (deposit-id uint))
    (let (
        (dep (unwrap! (map-get? deposits { user: tx-sender, deposit-id: deposit-id }) ERR-LOCKED))
    )
        (asserts! (>= block-height (get unlock-time dep)) ERR-LOCKED)
        (asserts! (not (get withdrawn dep)) ERR-ALREADY-WITHDRAWN)
        (map-set deposits { user: tx-sender, deposit-id: deposit-id } (merge dep { withdrawn: true }))
        (ok true)
    )
)

(define-read-only (get-deposit (user principal) (deposit-id uint))
    (map-get? deposits { user: user, deposit-id: deposit-id })
)
