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

(deffacts fil
    (phase init-field)
    (size 4)
    (tile-open (row 1) (col 0) (mine-count 4))
    (tile-open (row 1) (col 1) (mine-count 4))
    (tile-open (row 3) (col 3) (mine-count 0))
)

;;; PHASE 1 init-field

(defrule gen-field-start
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
    (modify ?f (closed-count ?x))
)

(defrule count-closed-adj-end
    ?f <- (phase init-closed-count)
    (not (tile-open (row ?r) (col ?c) (closed-count nil)))
    =>
    (retract ?f)
    (assert (phase check-closed))
)

;;; PHASE check-closed

(defrule all-closed-is-flag
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc))
    (test (= ?mc ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status flag)))
)

(defrule all-closed-is-safe
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count 0) (closed-count ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status safe)))
)

(defrule all-closed-is-unsure
    (declare (salience 20))
    (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc))
    (test (and (< ?mc ?cc) (> ?mc 0)))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    =>
    (assert (tile-closed-check (row ?r2) (col ?c2) (status unsure)))
)

(defrule clean-closed-check
    (declare (salience 20))
    (phase check-closed)
    ?f <- (tile-closed-check (row ?r) (col ?c) (status unsure))
    (tile-closed-check (row ?r) (col ?c) (status flag|safe))
    =>
    (retract ?f)
)

(defrule check-closed-end
    (declare (salience 0))
    ?f <- (phase check-closed)
    =>
    (retract ?f)
    (assert (phase select-action))
)
