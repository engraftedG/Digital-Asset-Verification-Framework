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

;; Validates the full set of tags
(define-private (validate-tag-collection (tags (list 10 (string-ascii 32))))
  (and
    (> (len tags) u0)
    (<= (len tags) u10)
    (is-eq (len (filter is-valid-tag tags)) (len tags))
  )
)

;; Checks if asset exists in registry
(define-private (asset-exists (asset-identifier uint))
  (is-some (map-get? digital-assets { asset-identifier: asset-identifier }))
)

;; Retrieves file size for an asset
(define-private (get-file-size (asset-identifier uint))
  (default-to u0
    (get file-size
      (map-get? digital-assets { asset-identifier: asset-identifier })
    )
  )
)

;; Ownership verification check
(define-private (is-asset-owner (asset-identifier uint) (viewer principal))
  (match (map-get? digital-assets { asset-identifier: asset-identifier })
    asset-data (is-eq (get asset-owner asset-data) viewer)
    false
  )
)

;; ===== Core Public Functions =====

;; Register new digital asset with complete metadata
(define-public (register-asset
  (title (string-ascii 64))
  (filesize uint)
  (description (string-ascii 128))
  (tags (list 10 (string-ascii 32)))
)
  (let
    (
      (new-asset-id (+ (var-get asset-registry-count) u1))
    )
    ;; Parameter validation
    (asserts! (> (len title) u0) invalid-title-error)
    (asserts! (< (len title) u65) invalid-title-error)
    (asserts! (> filesize u0) invalid-dimension-error)
    (asserts! (< filesize u1000000000) invalid-dimension-error)
    (asserts! (> (len description) u0) invalid-title-error)
    (asserts! (< (len description) u129) invalid-title-error)
    (asserts! (validate-tag-collection tags) invalid-tag-error)

    ;; Create asset entry in registry
    (map-insert digital-assets
      { asset-identifier: new-asset-id }
      {
        asset-title: title,
        asset-owner: tx-sender,
        file-size: filesize,
        registration-block: block-height,
        asset-description: description,
        associated-tags: tags
      }
    )

    ;; Initialize access permission for creator
    (map-insert permission-registry
      { asset-identifier: new-asset-id, viewer: tx-sender }
      { access-allowed: true }
    )

    ;; Update registry counter
    (var-set asset-registry-count new-asset-id)
    (ok new-asset-id)
  )
)

;; Update existing digital asset metadata
(define-public (update-asset-details
  (asset-identifier uint)
  (new-title (string-ascii 64))
  (new-filesize uint)
  (new-description (string-ascii 128))
  (new-tags (list 10 (string-ascii 32)))
)
  (let
    (
      (asset-data (unwrap! (map-get? digital-assets { asset-identifier: asset-identifier })
        asset-not-found-error))
    )
    ;; Validation of ownership and parameters
    (asserts! (asset-exists asset-identifier) asset-not-found-error)
    (asserts! (is-eq (get asset-owner asset-data) tx-sender) not-asset-owner-error)
    (asserts! (> (len new-title) u0) invalid-title-error)
    (asserts! (< (len new-title) u65) invalid-title-error)
    (asserts! (> new-filesize u0) invalid-dimension-error)
    (asserts! (< new-filesize u1000000000) invalid-dimension-error)
    (asserts! (> (len new-description) u0) invalid-title-error)
    (asserts! (< (len new-description) u129) invalid-title-error)
    (asserts! (validate-tag-collection new-tags) invalid-tag-error)

    ;; Update asset record with new information
    (map-set digital-assets
      { asset-identifier: asset-identifier }
      (merge asset-data {
        asset-title: new-title,
        file-size: new-filesize,
        asset-description: new-description,
        associated-tags: new-tags
      })
    )
    (ok true)
  )
)

;; Transfer asset ownership to new principal
(define-public (transfer-asset-ownership (asset-identifier uint) (new-owner principal))
  (let
    (
      (asset-data (unwrap! (map-get? digital-assets { asset-identifier: asset-identifier })
        asset-not-found-error))
    )
    ;; Verify caller is the current owner
    (asserts! (asset-exists asset-identifier) asset-not-found-error)
    (asserts! (is-eq (get asset-owner asset-data) tx-sender) not-asset-owner-error)

    ;; Update ownership record
    (map-set digital-assets
      { asset-identifier: asset-identifier }
      (merge asset-data { asset-owner: new-owner })
    )
    (ok true)
  )
)

;; Delete asset from registry permanently
(define-public (deregister-asset (asset-identifier uint))
  (let
    (
      (asset-data (unwrap! (map-get? digital-assets { asset-identifier: asset-identifier })
        asset-not-found-error))
    )
    ;; Ownership verification
    (asserts! (asset-exists asset-identifier) asset-not-found-error)
    (asserts! (is-eq (get asset-owner asset-data) tx-sender) not-asset-owner-error)

    ;; Remove asset from registry
    (map-delete digital-assets { asset-identifier: asset-identifier })
    (ok true)
  )
)

