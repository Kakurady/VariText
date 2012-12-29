(define vwts-make-texture-full
	(lambda x ;font, color, size, width, height, rows, columns
		(let
			(
				(font   (car x))
				(color  (cadr x))
				(size   (caddr x))
				(width  (car (cdddr x)))
				(height (cadr (cdddr x)))
				(rows   (caddr (cdddr x)))
				(columns (car (cdddr (cdddr x))))
				(chars " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~		 ")

			)
			(let 
				(
					;Create Image with width and height in RGB mode.
					
					; GRAY instead of RGB should be fine too, you can add color in-world
					; but while the resulting PNG/TGA will take less space
					; I'm not sure if this will make SL use less memory for the texture.
					(img (car (gimp-image-new width height RGB)))
					(num_chars (string-length chars))
				) 
				(let 
					;create a new layer.
					(   (layer 
							(car 
								(gimp-layer-new img width height RGBA-IMAGE font 1.0 NORMAL-MODE)
								;gimp-layer-new should return a list with one element (in 2.4)
					)	)	)
					(begin
						(gimp-image-add-layer img layer 0)
						(gimp-context-set-foreground color)
						(letrec
							(
;								(prepend ;not tail-recursive
;									(lambda (list1 list2)
;										(cond
;											((null? list1) list2)
;											(else (cons (car list1) (prepend (cdr list1) list2)))
;								)	)	) ;prepend ends
;								(derp4
;									(lambda (extents txt)
;										(cond
;											((null? extents) (cons #\[ txt))
;											(
;												(null? (cdr extents)) 
;												(derp4 
;													(cdr extents) 
;													(prepend (string->list (number->string (car extents))) txt)
;											)	)
;											(else 
;												(derp4 
;													(cdr extents) 
;													(cons #\, ( cons #\space
;															(prepend (string->list (number->string (car extents))) txt)
;								)	)	)	)	)	)	) ;derp4 ends
								(row-loop
									(lambda (row derp1)
										(cond
											((>= row rows) derp1)
											((>= (* row columns) num_chars) derp1)
											(else (row-loop (+ 1 row) (col-loop row 0 derp1)))
								)	)	) ; row-loop ends
								(col-loop
									(lambda (row col derp2)
										(cond
											;return derp2 if we have went out of bounds.
											((>= col columns) derp2)
											((>= (+ col (* row columns)) num_chars) derp2)
											(else ;draw a character
												(let
													((charr (string (string-ref chars (+ col (* row columns)))) ))
													(let
														(	(c_w 
																(car (gimp-text-get-extents-fontname charr size PIXELS font))
														)	)
														(let
															(
																(y (* row (/ height rows)))
																(x (- (* (+ col 0.5) (/ width columns)) (/ c_w 2)))
															)
															(begin
															; TODO: See if we can use #t instead of TRUE
																(gimp-text-fontname img -1 x y charr 0 
																	TRUE size PIXELS font)
																(col-loop row (+ 1 col) (cons c_w derp2) )
															) ;begin	
														) ;let	
													) ;let	
												);let	
											);else
										) ;cond
									)	
								)	; col-loop ends
							) ; letrec def list ends
							(let
								((extents (row-loop 0 ())))
								(let
									((merged (car (gimp-image-merge-visible-layers img CLIP-TO-IMAGE)))									)
									(let
										((mask (car (gimp-layer-create-mask merged ADD-ALPHA-MASK))))
										(begin
											(gimp-layer-add-mask merged mask)
											(gimp-context-set-foreground color)
											(gimp-drawable-fill merged FOREGROUND-FILL)
											(gimp-layer-remove-mask merged MASK-APPLY)
											(gimp-display-new img)	 
											;(list->string (derp4 extents '(#\]) ))
											(reverse extents)
										)
									)	
								)	
							)	
						)	
					)	
				)	
			)	
		)	
	)	
)

;font, color, size, width, height, rows, columns
(define vwts-make-texture
	(lambda (font)
		(vwts-make-texture-full font '(255 255 255) 50 512 512 10 10)
)	)
