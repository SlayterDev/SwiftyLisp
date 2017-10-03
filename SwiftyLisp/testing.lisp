(defun triple (X)
	(* 3 X))

(defun negate (X)
	(- X))

(defun factorial (N)
	(if 
		((= N 1) 1)
		(t (* N (factorial (- N 1))))))

(defun fib (N)
	(cond
		((= N 0) 0)
		((= N 1) 1)
		((= N 2) 1)
		(t (+ (fib (- N 2)) (fib (- N 1))))))
