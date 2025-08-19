;; Instructor Certification Contract
;; Handles instructor verification, credentials, and program assignments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INSTRUCTOR-NOT-FOUND (err u201))
(define-constant ERR-CERTIFICATION-EXPIRED (err u202))
(define-constant ERR-ALREADY-REGISTERED (err u203))
(define-constant ERR-INVALID-CERTIFICATION (err u204))
(define-constant ERR-ASSIGNMENT-NOT-FOUND (err u205))
(define-constant ERR-ALREADY-ASSIGNED (err u206))
(define-constant ERR-INVALID-DATES (err u207))

;; Data Variables
(define-data-var next-instructor-id uint u1)
(define-data-var next-assignment-id uint u1)

;; Data Maps
(define-map instructors
  { instructor-id: uint }
  {
    instructor-address: principal,
    name: (string-ascii 100),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    bio: (string-ascii 500),
    years-experience: uint,
    verification-status: (string-ascii 20),
    registered-at: uint,
    updated-at: uint
  }
)

(define-map instructor-addresses
  { instructor-address: principal }
  { instructor-id: uint }
)

(define-map certifications
  { instructor-id: uint, cert-type: (string-ascii 50) }
  {
    certification-name: (string-ascii 100),
    issuing-organization: (string-ascii 100),
    issue-date: uint,
    expiry-date: uint,
    certification-number: (string-ascii 50),
    verification-status: (string-ascii 20),
    verified-by: (optional principal),
    verified-at: (optional uint)
  }
)

(define-map specializations
  { instructor-id: uint, specialization: (string-ascii 50) }
  {
    proficiency-level: (string-ascii 20),
    years-practicing: uint,
    additional-notes: (string-ascii 200)
  }
)

(define-map program-assignments
  { assignment-id: uint }
  {
    instructor-id: uint,
    program-id: uint,
    role: (string-ascii 50),
    start-date: uint,
    end-date: uint,
    compensation: uint,
    status: (string-ascii 20),
    assigned-by: principal,
    assigned-at: uint
  }
)

(define-map instructor-program-assignments
  { instructor-id: uint, program-id: uint }
  { assignment-id: uint }
)

(define-map certification-authorities
  { authority: principal }
  { authorized: bool, organization-name: (string-ascii 100) }
)

;; Authorization Functions
(define-public (authorize-certification-authority (authority principal) (org-name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set certification-authorities { authority: authority } { authorized: true, organization-name: org-name }))
  )
)

(define-public (revoke-certification-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set certification-authorities { authority: authority } { authorized: false, organization-name: "" }))
  )
)

(define-read-only (is-authorized-authority (authority principal))
  (default-to false (get authorized (map-get? certification-authorities { authority: authority })))
)

;; Instructor Registration Functions
(define-public (register-instructor
  (name (string-ascii 100))
  (email (string-ascii 100))
  (phone (string-ascii 20))
  (bio (string-ascii 500))
  (years-experience uint)
)
  (let
    (
      (instructor-id (var-get next-instructor-id))
    )
    (asserts! (is-none (map-get? instructor-addresses { instructor-address: tx-sender })) ERR-ALREADY-REGISTERED)

    (map-set instructors
      { instructor-id: instructor-id }
      {
        instructor-address: tx-sender,
        name: name,
        email: email,
        phone: phone,
        bio: bio,
        years-experience: years-experience,
        verification-status: "pending",
        registered-at: block-height,
        updated-at: block-height
      }
    )

    (map-set instructor-addresses
      { instructor-address: tx-sender }
      { instructor-id: instructor-id }
    )

    (var-set next-instructor-id (+ instructor-id u1))
    (ok instructor-id)
  )
)

(define-public (update-instructor-profile
  (name (string-ascii 100))
  (email (string-ascii 100))
  (phone (string-ascii 20))
  (bio (string-ascii 500))
  (years-experience uint)
)
  (let
    (
      (instructor-mapping (unwrap! (map-get? instructor-addresses { instructor-address: tx-sender }) ERR-INSTRUCTOR-NOT-FOUND))
      (instructor-id (get instructor-id instructor-mapping))
      (instructor (unwrap! (map-get? instructors { instructor-id: instructor-id }) ERR-INSTRUCTOR-NOT-FOUND))
    )

    (ok (map-set instructors
      { instructor-id: instructor-id }
      (merge instructor {
        name: name,
        email: email,
        phone: phone,
        bio: bio,
        years-experience: years-experience,
        updated-at: block-height
      })
    ))
  )
)

(define-public (verify-instructor (instructor-id uint) (status (string-ascii 20)))
  (let
    (
      (instructor (unwrap! (map-get? instructors { instructor-id: instructor-id }) ERR-INSTRUCTOR-NOT-FOUND))
    )
    (asserts! (is-authorized-authority tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set instructors
      { instructor-id: instructor-id }
      (merge instructor { verification-status: status, updated-at: block-height })
    ))
  )
)

;; Certification Management Functions
(define-public (add-certification
  (instructor-id uint)
  (cert-type (string-ascii 50))
  (certification-name (string-ascii 100))
  (issuing-organization (string-ascii 100))
  (issue-date uint)
  (expiry-date uint)
  (certification-number (string-ascii 50))
)
  (let
    (
      (instructor (unwrap! (map-get? instructors { instructor-id: instructor-id }) ERR-INSTRUCTOR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender (get instructor-address instructor)) (is-authorized-authority tx-sender)) ERR-NOT-AUTHORIZED)
    (asserts! (< issue-date expiry-date) ERR-INVALID-DATES)

    (ok (map-set certifications
      { instructor-id: instructor-id, cert-type: cert-type }
      {
        certification-name: certification-name,
        issuing-organization: issuing-organization,
        issue-date: issue-date,
        expiry-date: expiry-date,
        certification-number: certification-number,
        verification-status: "pending",
        verified-by: none,
        verified-at: none
      }
    ))
  )
)

(define-public (verify-certification (instructor-id uint) (cert-type (string-ascii 50)) (status (string-ascii 20)))
  (let
    (
      (certification (unwrap! (map-get? certifications { instructor-id: instructor-id, cert-type: cert-type }) ERR-INVALID-CERTIFICATION))
    )
    (asserts! (is-authorized-authority tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set certifications
      { instructor-id: instructor-id, cert-type: cert-type }
      (merge certification {
        verification-status: status,
        verified-by: (some tx-sender),
        verified-at: (some block-height)
      })
    ))
  )
)

;; Specialization Management Functions
(define-public (add-specialization
  (instructor-id uint)
  (specialization (string-ascii 50))
  (proficiency-level (string-ascii 20))
  (years-practicing uint)
  (additional-notes (string-ascii 200))
)
  (let
    (
      (instructor (unwrap! (map-get? instructors { instructor-id: instructor-id }) ERR-INSTRUCTOR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get instructor-address instructor)) ERR-NOT-AUTHORIZED)

    (ok (map-set specializations
      { instructor-id: instructor-id, specialization: specialization }
      {
        proficiency-level: proficiency-level,
        years-practicing: years-practicing,
        additional-notes: additional-notes
      }
    ))
  )
)

;; Program Assignment Functions
(define-public (assign-instructor-to-program
  (instructor-id uint)
  (program-id uint)
  (role (string-ascii 50))
  (start-date uint)
  (end-date uint)
  (compensation uint)
)
  (let
    (
      (assignment-id (var-get next-assignment-id))
      (instructor (unwrap! (map-get? instructors { instructor-id: instructor-id }) ERR-INSTRUCTOR-NOT-FOUND))
    )
    (asserts! (< start-date end-date) ERR-INVALID-DATES)
    (asserts! (is-none (map-get? instructor-program-assignments { instructor-id: instructor-id, program-id: program-id })) ERR-ALREADY-ASSIGNED)

    (map-set program-assignments
      { assignment-id: assignment-id }
      {
        instructor-id: instructor-id,
        program-id: program-id,
        role: role,
        start-date: start-date,
        end-date: end-date,
        compensation: compensation,
        status: "active",
        assigned-by: tx-sender,
        assigned-at: block-height
      }
    )

    (map-set instructor-program-assignments
      { instructor-id: instructor-id, program-id: program-id }
      { assignment-id: assignment-id }
    )

    (var-set next-assignment-id (+ assignment-id u1))
    (ok assignment-id)
  )
)

(define-public (update-assignment-status (assignment-id uint) (new-status (string-ascii 20)))
  (let
    (
      (assignment (unwrap! (map-get? program-assignments { assignment-id: assignment-id }) ERR-ASSIGNMENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get assigned-by assignment)) ERR-NOT-AUTHORIZED)

    (ok (map-set program-assignments
      { assignment-id: assignment-id }
      (merge assignment { status: new-status })
    ))
  )
)

;; Read-only Functions
(define-read-only (get-instructor (instructor-id uint))
  (map-get? instructors { instructor-id: instructor-id })
)

(define-read-only (get-instructor-by-address (instructor-address principal))
  (match (map-get? instructor-addresses { instructor-address: instructor-address })
    mapping (map-get? instructors { instructor-id: (get instructor-id mapping) })
    none
  )
)

(define-read-only (get-certification (instructor-id uint) (cert-type (string-ascii 50)))
  (map-get? certifications { instructor-id: instructor-id, cert-type: cert-type })
)

(define-read-only (get-specialization (instructor-id uint) (specialization (string-ascii 50)))
  (map-get? specializations { instructor-id: instructor-id, specialization: specialization })
)

(define-read-only (get-program-assignment (assignment-id uint))
  (map-get? program-assignments { assignment-id: assignment-id })
)

(define-read-only (get-instructor-program-assignment (instructor-id uint) (program-id uint))
  (map-get? instructor-program-assignments { instructor-id: instructor-id, program-id: program-id })
)

(define-read-only (is-certification-valid (instructor-id uint) (cert-type (string-ascii 50)))
  (match (map-get? certifications { instructor-id: instructor-id, cert-type: cert-type })
    certification (and
      (is-eq (get verification-status certification) "verified")
      (> (get expiry-date certification) block-height)
    )
    false
  )
)

(define-read-only (is-instructor-verified (instructor-id uint))
  (match (map-get? instructors { instructor-id: instructor-id })
    instructor (is-eq (get verification-status instructor) "verified")
    false
  )
)

(define-read-only (get-certification-authority-info (authority principal))
  (map-get? certification-authorities { authority: authority })
)

(define-read-only (get-next-instructor-id)
  (var-get next-instructor-id)
)

(define-read-only (get-next-assignment-id)
  (var-get next-assignment-id)
)
