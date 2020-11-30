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

(deftemplate tile-unsafe
    (slot row)
    (slot col)
)

(deftemplate tile-safe
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
    (assert (phase clear-act))
)

;;; PHASE clear
(defrule clear-open-tile
    (phase clear-act)
    ?f <- (open-tile (row ?r) (col ?c))
    =>
    (retract ?f)
)

(defrule clear-flag-tile
    (phase clear-act)
    ?f <- (flag-tile (row ?r) (col ?c))
    =>
    (retract ?f)
)

(defrule reset-tile-open-closed-count
    (phase clear-act)
    ?f <- (tile-open (row ?r) (col ?c) (closed-count ?v&~nil))
    =>
    (modify ?f (closed-count nil))
)

(defrule reset-tile-open-flag-count
    (phase clear-act)
    ?f <- (tile-open (row ?r) (col ?c) (flag-count ?v&~nil))
    =>
    (modify ?f (flag-count nil))
)

(defrule clear-act-end
    ?f <- (phase clear-act)
    (not (open-tile (row ?r) (col ?c)))
    (not (flag-tile (row ?r) (col ?c)))
    (not (tile-open (row ?r) (col ?c) (closed-count ?v&~nil)))
    (not (tile-open (row ?r) (col ?c) (flag-count ?v&~nil)))
    =>
    (retract ?f)
    (open ".log" logfile "w")
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

(defrule count-flag-adj
    (phase init-closed-count)
    ?f <- (tile-open (row ?r) (col ?c) (flag-count nil))
    =>
    (bind ?x 0)
    (do-for-all-facts ((?ta tile-adjacent))
        (and 
            (= ?ta:row1 ?r) (= ?ta:col1 ?c)
            (any-factp ((?to tile-flag)) (and (= ?ta:row2 ?to:row) (= ?ta:col2 ?to:col)))
        )
        (bind ?x (+ ?x 1))
    )
    (modify ?f (flag-count ?x))
)

(defrule count-closed-adj-end
    ?f <- (phase init-closed-count)
    (not (tile-open (row ?r) (col ?c) (closed-count nil)))
    (not (tile-open (row ?r) (col ?c) (flag-count nil)))
    =>
    (retract ?f)
    (assert (phase check-closed))
)

;;; PHASE check-closed
(defrule first-move-skip
    (declare (salience 40))
    ?f <- (phase check-closed)
    (not (tile-open (row ?r) (col ?c)))
    => 
    (retract ?f)
    (assert (phase end-phase))
    (assert (open-tile (row 0) (col 0)))
    (printout logfile "first-move-skip:" crlf
        "No opened tiles." crlf
        "-> Assume tile [0,0] is safe." crlf
        "-> Open [0,0]." crlf crlf
    )

)

(defrule act-flag
    (declare (salience 20))
    ?f <- (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc&~nil))
    (test (= ?mc ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-flag (row ?r2) (col ?c2)))
    =>
    (retract ?f)
    (assert (phase end-phase))
    (assert (flag-tile (row ?r2) (col ?c2)))
    (printout logfile "act-flag:" crlf
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?cc " closed." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not flagged." crlf 
        "-> Flag all closed adjacent tiles." crlf
        "-> Flag [" ?r2 "," ?c2 "]." crlf crlf
    )
)

(defrule act-safe
    (declare (salience 15))
    ?f <- (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (flag-count ?fc&~nil))
    (test (= ?fc ?mc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-flag (row ?r2) (col ?c2)))
    =>
    (retract ?f)
    (assert (phase end-phase))
    (assert (open-tile (row ?r2) (col ?c2)))
    (printout logfile "act-safe:" crlf 
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?fc " flag." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not flagged." crlf 
        "-> Unflagged closed adjacent tiles are safe to open." crlf
        "-> Tile [" ?r2 "," ?c2 "] is safe to open." crlf
        "-> Open [" ?r2 "," ?c2 "]" crlf crlf
    )
)

(defrule act-unsafe
    (declare (salience 10))
    ?f <- (phase check-closed)
    (tile-open (row ?r) (col ?c) (mine-count ?mc) (closed-count ?cc))
    (tile-adjacent (row1 ?r) (col1 ?c) (row2 ?r2) (col2 ?c2))
    (not (tile-open (row ?r2) (col ?c2)))
    (not (tile-flag (row ?r2) (col ?c2)))
    =>
    (retract ?f)
    (assert (phase end-phase))
    (assert (open-tile (row ?r2) (col ?c2)))
    (printout logfile "act-unsafe:" crlf 
        "Tile [" ?r "," ?c "] adjacents: " ?mc " mines, " ?cc " closed." crlf 
        "Tile [" ?r2 "," ?c2 "] is adjacent to tile [" ?r "," ?c "]." crlf 
        "Tile [" ?r2 "," ?c2 "] is closed and not flagged." crlf 
        "-> Some closed adjacent tiles may be unsafe." crlf
        "-> Tile [" ?r2 "," ?c2 "] is not safe to open." crlf
        "-> Open [" ?r2 "," ?c2 "] (unsafe)" crlf crlf
    )
)

(defrule close-log
    ?f <- (phase end-phase)
    =>
    (retract ?f)
    (close logfile)
)


