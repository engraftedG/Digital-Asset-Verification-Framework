;; Digital Asset Verification Framework -  Blockchain-based solution for certified digital asset management with granular permissions
;; 
;; This system enables secure registration, transfer, and management of digital assets
;; with complete audit trails and customizable access controls

;; Global Registry Counter
(define-data-var asset-registry-count uint u0)

;; System Administrator
(define-constant admin-authority tx-sender)

;; Error Response Definitions

(define-constant not-asset-owner-error (err u306))
(define-constant admin-only-error (err u300))
(define-constant asset-not-found-error (err u301))
(define-constant duplicate-asset-error (err u302))
(define-constant invalid-title-error (err u303))
(define-constant invalid-dimension-error (err u304))
(define-constant permission-denied-error (err u305))
(define-constant restricted-view-error (err u307))
(define-constant invalid-tag-error (err u308))

;; Primary Data Storage
(define-map digital-assets
  { asset-identifier: uint }
  {
    asset-title: (string-ascii 64),
    asset-owner: principal,
    file-size: uint,
    registration-block: uint,
    asset-description: (string-ascii 128),
    associated-tags: (list 10 (string-ascii 32))
  }
)

;; Permission Management System
(define-map permission-registry
  { asset-identifier: uint, viewer: principal }
  { access-allowed: bool }
)

;; ===== Utility Functions =====

;; Validates tag format requirements
(define-private (is-valid-tag (tag (string-ascii 32)))
  (and
    (> (len tag) u0)
    (< (len tag) u33)
  )
)
