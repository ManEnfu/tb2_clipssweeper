(deftemplate tile
    (slot row)
    (slot col)
)

(deftemplate tile-adjacent
    (slot row1)
    (slot col1)
    (slot row2)
    (slot col2)
)

;;; Opened tiles
(deftemplate tile-open
    (slot row)
    (slot col)
    (slot mine-count)
    (slot closed-count)
    (slot flag-count)
    (slot safe-count)
)

(deftemplate tile-flag
    (slot row)
    (slot col)
)

(deftemplate tile-open-adj-closed
    (slot row)
    (slot col)
    (slot closed-count)
)

;;; Checked Closed tiles 
(deftemplate tile-closed-check
    (slot row)
    (slot col)
    (slot status)
)

(deftemplate tile-inc
    (slot row)
    (slot col)
    (slot id)
    (slot type)
)

(deftemplate open-tile
    (slot row)
    (slot col)
)

(deftemplate flag-tile
    (slot row)
    (slot col)
)

(deffacts dummy-data
    (phase init-field)
)

;;; PHASE 1 init-field

;;; If no tile open, assume 0,0 is safe and open it.
(defrule first-move-skip
    (declare (salience 40))
    ?f <- (phase init-field)
    (not (tile-open (row ?r) (col ?c)))
    => 
    (retract ?f)
    (assert (tile-closed-check (row 0) (col 0) (status safe)))
    (assert (phase select-action))
    (printout t "first-move-skip:" crlf
        "No opened tiles." crlf
        "-> Assume tile [0,0] is safe." crlf crlf
    )

)

(defrule gen-field-start
    (declare (salience 20))
    (phase init-field)
    (size ?s)
    (not (tile (row ?r) (col ?c)))
    =>
    (assert (tile (row 0) (col 0)))
)

(defrule gen-field-down
    (declare (salience 5))
    (phase init-field)
    (size ?s)
    (tile (row ?r) (col 0))
    (not (tile (row ?r2&:(= ?r2 (+ ?r 1))) (col 0)))
    (test (< ?r (- ?s 1)))
    =>
    (assert (tile (row (+ ?r 1)) (col 0)))
)

(defrule gen-field-right
    (declare (salience 10))
    (phase init-field)
    (size ?s)
    (tile (row ?r) (col ?c))
    (not (tile (row ?r) (col ?c2&:(= ?c2 (+ ?c 1)))))
    (test (< ?c (- ?s 1)))
    =>
    (assert (tile (row ?r) (col (+ ?c 1))))
)

(defrule gen-field-end
    (declare (salience 2))
    ?f <- (phase init-field)
    (size ?s)
    (tile (row ?r&:(= ?r (- ?s 1))) (col ?c&:(= ?c (- ?s 1))))
    =>
    (retract ?f)
    (assert (phase init-adj))
)


;;; PHASE init-adj

(defrule gen-adjacents
    (phase init-adj)
    (tile (row ?r1) (col ?c1))
    (tile (row ?r2) (col ?c2))
    (test (and
        (< (abs (- ?r1 ?r2)) 2)
        (< (abs (- ?c1 ?c2)) 2)
        (not (and (= ?r1 ?r2) (= ?c1 ?c2)))
    ))
    (not (tile-adjacent (row1 ?r1) (col1 ?c1) (row2 ?r2) (col2 ?c2)))
    =>
    (assert (tile-adjacent(row1 ?r1) (col1 ?c1) (row2 ?r2) (col2 ?c2)))
)

(defrule gen-adjacents-end
    ?f <- (phase init-adj)
    (forall (tile (row ?r1) (col ?c1))
        (forall (tile (row ?r2) (col ?c2))
            (or (not (test (and
                    (< (abs (- ?r1 ?r2)) 2)
                    (< (abs (- ?c1 ?c2)) 2)
                    (not (and (= ?r1 ?r2) (= ?c1 ?c2)))
                )))
                (tile-adjacent (row1 ?r1) (col1 ?c1) (row2 ?r2) (col2 ?c2))
            )
        )
    )
    =>
    (retract ?f)
    (assert (phase init-closed-count))
)

;;; PHASE init-closed-count
(deffunction count-status-adj (?r ?c ?s)
    (bind ?x 0)
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r) (= ?ta:col1 ?c)
            (any-factp ((?tcc tile-closed-check)) (and (= ?ta:row2 ?tcc:row) (= ?ta:col2 ?tcc:col) (eq ?tcc:status ?s)))
        )
        (bind ?x (+ ?x 1))
    )
    (printout t "csa " ?r " " ?c " " ?s " " ?x crlf)
    (return ?x)
)

(defrule count-closed-adj
    (phase init-closed-count)
    ?f <- (tile-open (row ?r) (col ?c) (closed-count nil))
    =>
    (bind ?x 0)
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r) (= ?ta:col1 ?c)
            (not (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col))))
        )
        (bind ?x (+ ?x 1))
    )
    (modify ?f (closed-count ?x) (flag-count 0) (safe-count 0))
)

(defrule count-closed-adj-end
    ?f <- (phase init-closed-count)
    (not (tile-open (row ?r) (col ?c) (closed-count nil)))
    =>
    (retract ?f)
    (assert (phase check-closed))
)

;;; PHASE check-closed

(defrule check-flags
    (declare (salience 30))
    (phase check-closed)
    (tile-flag (row ?r) (col ?c))
    =>
    (assert (tile-closed-check (row ?r) (col ?c) (status flag)))
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r) (= ?ta:col1 ?c)
            (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (assert (tile-inc (row ?ta:row2) (col ?ta:col2) (id (+ (* 100 ?r) ?c)) (type flag)))
    )
)

(defrule all-closed-is-flag
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc))
    (test (= ?mc ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-closed-check (row ?r2) (col ?c2) (status flag)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status flag)))
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r2) (= ?ta:col1 ?c2)
            (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (assert (tile-inc (row ?ta:row2) (col ?ta:col2) (id (+ (* 100 ?r2) ?c2)) (type flag)))
    )
    (printout t "all-closed-is-flag:" crlf
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?cc " closed." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not flagged." crlf 
        "-> Flag all closed adjacent tiles." crlf
        "-> Flag [" ?r2 "," ?c2 "]." crlf crlf
    )
)

(defrule all-closed-is-safe
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count 0) (closed-count ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-closed-check (row ?r2) (col ?c2) (status safe)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status safe)))
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r2) (= ?ta:col1 ?c2)
            (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (assert (tile-inc (row ?ta:row2) (col ?ta:col2) (id (+ (* 100 ?r2) ?c2)) (type safe)))
    )
    (printout t "all-closed-is-safe:" crlf
        "Tile [" ?r "," ?c "] adjacents: " 0 " mines, " ?cc " closed." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not marked as safe." crlf 
        "-> All closed adjacent tiles are safe to open." crlf
        "-> Mark [" ?r2 "," ?c2 "] as safe." crlf crlf
    )
)

(defrule all-closed-is-unsafe
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc))
    (test (and (< ?mc ?cc) (> ?mc 0)))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-closed-check (row ?r2) (col ?c2)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status unsafe)))
    (printout t "all-closed-is-unsafe:" crlf 
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?cc " closed." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not yet marked." crlf 
        "-> Some closed adjacent tiles may be unsafe." crlf
        "-> Mark [" ?r2 "," ?c2 "] as unsafe." crlf crlf
    )
)

(defrule clean-closed-check
    (declare (salience 25))
    (phase check-closed)
    ?f <- (tile-closed-check (row ?r) (col ?c) (status unsafe))
    (tile-closed-check (row ?r) (col ?c) (status flag|safe))
    =>
    (retract ?f)
)

(defrule inc-adj-flag-count
    (declare (salience 20))
    (phase check-closed)
    ?f1 <- (tile-open (row ?r) (col ?c) (flag-count ?fc&~nil))
    ?f2 <- (tile-inc (row ?r) (col ?c) (type flag))
    =>
    (retract ?f2)
    (modify ?f1 (flag-count (+ ?fc 1)))
) 

(defrule inc-adj-safe-count
    (declare (salience 20))
    (phase check-closed)
    ?f1 <- (tile-open (row ?r) (col ?c) (safe-count ?sc&~nil))
    ?f2 <- (tile-inc (row ?r) (col ?c) (type safe))
    =>
    (retract ?f2)
    (modify ?f1 (safe-count (+ ?sc 1)))
) 

(defrule infer-safe-from-flag
    (declare (salience 15))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (flag-count ?fc&~nil))
    (test (= ?fc ?mc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (tile-closed-check (row ?r2) (col ?c2) (status unsafe))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status safe)))
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r2) (= ?ta:col1 ?c2)
            (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (assert (tile-inc (row ?ta:row2) (col ?ta:col2) (id (+ (* 100 ?r2) ?c2)) (type safe)))
    )
    (printout t "infer-safe-from-flag:" crlf 
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?fc " flag." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is previously marked as unsafe." crlf 
        "-> Unflagged closed adjacent tiles are safe to open." crlf
        "-> Mark [" ?r2 "," ?c2 "] as safe." crlf crlf
    )
)

(defrule infer-flag-from-safe
    (declare (salience 15))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc&~nil) (safe-count ?sc&~nil))
    (test (= ?sc (- ?cc ?mc)))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (tile-closed-check (row ?r2) (col ?c2) (status unsafe))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status flag)))
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r2) (= ?ta:col1 ?c2)
            (any-factp ((?to tile-open)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (assert (tile-inc (row ?ta:row2) (col ?ta:col2) (id (+ (* 100 ?r2) ?c2)) (type flag)))
    )
    (printout t "infer-flag-from-safe:" crlf
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?cc " closed, " ?sc " safe." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is previously marked as unsafe." crlf 
        "-> Flag unsafe closed adjacent tiles" crlf
        "-> Flag [" ?r2 "," ?c2 "]." crlf crlf
    )
)

(defrule check-closed-end
    (declare (salience 0))
    ?f <- (phase check-closed)
    =>
    (retract ?f)
    (assert (phase select-action))
)

(defrule action-flag
    (declare (salience 60))
    (phase select-action)
    (tile-closed-check (row ?r) (col ?c) (status flag))
    (not (tile-flag (row ?r) (col ?c)))
    =>
    (assert (flag-tile (row ?r) (col ?c)))
)

(defrule action-safe
    (declare (salience 40))
    ?f <- (phase select-action)
    (tile-closed-check (row ?r) (col ?c) (status safe))
    =>
    (retract ?f)
    (assert (open-tile (row ?r) (col ?c)))
    (printout t "action-safe:" crlf
        "Tile [" ?r "," ?c "] is safe to open." crlf
        "-> Open tile [" ?r "," ?c "]" crlf crlf
    )
)

(defrule action-unsafe
    (declare (salience 20))
    ?f <- (phase select-action)
    (tile-closed-check (row ?r) (col ?c) (status unsafe))
    =>
    (retract ?f)
    (assert (open-tile (row ?r) (col ?c)))
    (printout t "action-unsafe:" crlf
        "Tile [" ?r "," ?c "] is unsafe, but there are no safe tiles to open." crlf
        "-> Open tile [" ?r "," ?c "]" crlf crlf
    )
)

