;;; Maximum hash size.
(define hashsize 101)
;;; Hash a string.
(define (hash-string str)
  (let loop ((lst (string->list str))
             (accum 0))
    (if (null? lst)
        (modulo accum hashsize)
        (loop (cdr lst)
              (+ (char->integer (car lst))
                 (* 31 accum))))))
;;; Hash an object.
(define (hash obj)
  (cond ((number? obj)
         (modulo obj hashsize))
        ((string? obj) (hash-string obj))
        ((symbol? obj)
         (hash-string (symbol->string obj)))
        (else #f)))

;;; Hash table type tag.
(define :hash-table '(:hash-table))

;;; Return #t if obj is a hash table.
(define (hash-table? obj)
  (eq? (car obj) :hash-table))

;;; Make a hash table using the specified
;;; associative list procedure.
(define (make-hash-table-helper aproc)
  (list :hash-table aproc
        (make-vector hashsize '())))

;;; Get the associative list procedure
;;; from a hash table.
(define hash-table-aproc cadr)
;;; Get the vector from a hash table.
(define hash-table-vector caddr)

;;; Make a hash table using assoc.
(define (make-hash-table)
  (make-hash-table-helper assoc))
;;; Make a hash table using assq.
(define (make-hash-tableq)
  (make-hash-table-helper assq))
;;; Make a hash table using assv.
(define (make-hash-tablev)
  (make-hash-table-helper assv))

;;; Return #t if obj is a hash table
;;; using assoc.
(define (hash-table-equal? obj)
  (and (hash-table? obj)
       (eq? (hash-table-aproc obj) assoc)))
;;; Return #t if obj is a hash table
;;; using assq.
(define (hash-table-eq? obj)
  (and (hash-table? obj)
       (eq? (hash-table-aproc obj) assq)))
;;; Return #t if obj is a hash table
;;; using assv.
(define (hash-table-eqv? obj)
  (and (hash-table? obj)
       (eq? (hash-table-aproc obj) assv)))

;;; Set a value in a hash table.
(define (hash-table-set! ht key val)
  (let* ((hashval (hash key))
         (vec (hash-table-vector ht))
         (alist (vector-ref vec hashval))
         (pair ((hash-table-aproc ht) key alist)))
    (if pair
        (set-cdr! pair val)
        (vector-set! vec hashval
                     (cons (cons key val)
                           alist)))))

;;; Get a value from a hash table.
(define (hash-table-ref ht key)
  (let ((pair
         ((hash-table-aproc ht)
          key
          (vector-ref (hash-table-vector ht)
                      (hash key)))))
    (if pair
        (cdr pair)
        #f)))

(define (hash-table-pred ht)
  (let ((aproc (hash-table-aproc ht)))
    (cond ((eq? aproc assq) eq?)
          ((eq? aproc assv) eqv?)
          ((eq? aproc assoc) equal?))))

;;; Delete a key from a hash table.
(define (hash-table-delete! ht key)
  (let ((pred? (hash-table-pred ht))
        (vec (hash-table-vector ht))
        (hashval (hash key)))
    (let helper ((alist
                  (vector-ref vec hashval)))
      (cond ((null? alist) alist)
            ((pred? (caar alist) key)
             (vector-set! vec hashval
                          (helper (cdr alist)))
             (vector-ref vec hashval))
            (else
             (helper (cdr alist)))))))

;;; Convert an associative list to
;;; a hash table.
(define (alist->hash-table-helper alist aproc)
  (let ((ht (make-hash-table-helper aproc)))
    (for-each
     (lambda (pair)
       (hash-table-set! ht (car pair) (cdr pair)))
     alist)
    ht))
(define (alist->hash-table alist)
  (alist->hash-table-helper alist assoc))
(define (alist->hash-tableq alist)
  (alist->hash-table-helper alist assq))
(define (alist->hash-tablev alist)
  (alist->hash-table-helper alist assv))

(define (hash-table . args)
  (alist->hash-table args))
(define (hash-tableq . args)
  (alist->hash-tablev args))
(define (hash-tablev . args)
  (alist->hash-tableq args))

;;; Convert a hash table to an
;;; associative list.
(define (hash-table->alist ht)
  (apply append
         (vector->list (hash-table-vector ht))))