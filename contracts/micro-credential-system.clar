;; Micro-Credential System Smart Contract
;; Issue skill-based credentials, verify competencies, and integrate with employer hiring systems

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var credential-counter uint u0)

;; Data Maps
(define-map credentials uint {
    recipient: principal,
    skill-name: (string-ascii 128),
    issuer: principal,
    competency-level: uint,
    issue-date: uint,
    verified: bool
})

(define-map skill-providers principal {
    name: (string-ascii 128),
    reputation-score: uint,
    credentials-issued: uint,
    is-verified: bool
})

(define-map user-credentials principal (list 50 uint))

;; Public Functions
(define-public (issue-credential (recipient principal) (skill-name (string-ascii 128)) (competency-level uint))
    (let ((credential-id (+ (var-get credential-counter) u1)))
        (map-set credentials credential-id {
            recipient: recipient,
            skill-name: skill-name,
            issuer: tx-sender,
            competency-level: competency-level,
            issue-date: stacks-block-height,
            verified: false
        })
        (var-set credential-counter credential-id)
        
        ;; Add to user's credential list
        (let ((user-creds (default-to (list) (map-get? user-credentials recipient))))
            (map-set user-credentials recipient
                (match (as-max-len? (append user-creds credential-id) u50)
                    new-list new-list
                    user-creds
                )
            )
        )
        (ok credential-id)
    )
)

(define-public (verify-credential (credential-id uint))
    (let ((cred-data (unwrap! (map-get? credentials credential-id) err-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (map-set credentials credential-id 
            (merge cred-data {verified: true})
        )
        (ok true)
    )
)

(define-public (register-provider (name (string-ascii 128)))
    (begin
        (map-set skill-providers tx-sender {
            name: name,
            reputation-score: u100,
            credentials-issued: u0,
            is-verified: false
        })
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-credential (credential-id uint))
    (map-get? credentials credential-id)
)

(define-read-only (get-user-credentials (user principal))
    (map-get? user-credentials user)
)

(define-read-only (get-provider-info (provider principal))
    (map-get? skill-providers provider)
)

(define-read-only (get-platform-stats)
    {
        total-credentials: (var-get credential-counter)
    }
)

