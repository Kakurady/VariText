; VariText texture generation script
; (c) 2012 Kakurady
; MIT-licensed

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(define 
    (varitext-make-texture font . args)
;	(lambda x ;font, color, size, width, height, rows, columns
		(let*
			(
				(_tmp args)
				
				(color  (if (null? _tmp) '"white"       (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
				(size   (if (null? _tmp) 50             (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
                (width  (if (null? _tmp) 512            (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
                (height (if (null? _tmp) 512            (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
				(rows   (if (null? _tmp) 10             (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
				(columns(if (null? _tmp) 10             (car _tmp)))
				(_tmp   (if (null? _tmp) '()            (cdr _tmp)))
				
				(chars   (if (null? _tmp) 
				" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~          "
				             (car _tmp)))
                ;(_x (print (list font color size width height rows columns chars)))
			)
			(let*
				(
					;Create Image with width and height in RGB mode.
					
					; GRAY instead of RGB should be fine too, you can add color in-world
					; but while the resulting PNG/TGA will take less space
					; I'm not sure if this will make SL use less memory for the texture.
					(img (car (gimp-image-new width height RGB)))
					(num_chars (string-length chars))
					
					;create a new layer.
					(layer 
							(car 
								(gimp-layer-new img width height RGBA-IMAGE font 1.0 NORMAL-MODE)
								;gimp-layer-new should return a list with one element (in 2.4)
					)	)
				    (f_h (cadr (gimp-text-get-extents-fontname chars size PIXELS font)))
				) 
				(begin
					(gimp-image-undo-disable img)
					(gimp-image-add-layer img layer 0)
					(gimp-context-set-foreground color)
					(letrec
						(
							;(prepend ;not tail-recursive
							;	(lambda (list1 list2)
							;		(cond
							;			((null? list1) list2)
							;			(else (cons (car list1) (prepend (cdr list1) list2)))
							;)	)	) ;prepend ends
							;(derp4
							;	(lambda (extents txt)
							;		(cond
							;			((null? extents) (cons #\[ txt))
							;			(
							;				(null? (cdr extents)) 
							;				(derp4 
							;					(cdr extents) 
							;					(prepend (string->list (number->string (car extents))) txt)
							;			)	)
							;			(else 
							;				(derp4 
							;					(cdr extents) 
							;					(cons #\, ( cons #\space
							;							(prepend (string->list (number->string (car extents))) txt)
							;)	)	)	)	)	)	) ;derp4 ends
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
											(let*
												(
													(charr (string (string-ref chars (+ col (* row columns)))) )
													(c_w 
														(car (gimp-text-get-extents-fontname charr size PIXELS font))
													)
													(y (- (* (+ row 0.5) (/ height rows))   (/ f_h 2)))
													(x (- (* (+ col 0.5) (/ width columns)) (/ c_w 2)))
												)										
												(begin
													;-1 means we want a new layer
													;(because we can't directly write to the mask)
													;Note: This procedure won't accept #t as a substitute of TRUE
													(gimp-text-fontname img -1 x y charr 0 
														TRUE size PIXELS font)
													(col-loop row (+ 1 col) (cons c_w derp2) )
												) 
											); let*	
										); else
									); cond
								); lambda	
							); col-loop ends
						); letrec def list ends
						(let*
							(
								;draw the text, return the font information in extents (in reverse order)
								(extents (row-loop 0 ()))
								
								(merged (car (gimp-image-merge-visible-layers img CLIP-TO-IMAGE)))	
								;transfer the alpha channel to a mask...
								(mask (car (gimp-layer-create-mask merged ADD-ALPHA-MASK)))
							)
							(begin
								;... and fill the layer with the selected color.
								; this is to give even the transparent pixels a color value
								; which will prevent "halos" appearing 
								(gimp-layer-add-mask merged mask)
								(gimp-context-set-foreground color)
								(gimp-drawable-fill merged FOREGROUND-FILL)
								
								; apply-and-remove ("bake") the mask to prevent user accidentally saving it.
								(gimp-layer-remove-mask merged MASK-APPLY)
								
								(gimp-image-undo-enable img)
								(gimp-display-new img)	 

								;return the extents.
								;(list->string (derp4 extents '(#\]) ))
								(reverse extents)
							)	
						)	
					)	
				)	
			)	
		)	
	)	


;(script-fu-register
;	"vwts-make-texture-full"
;	"VWTS Font Texture"
;	"Creates a font texture for the variable width text system"
;	"Kakurayd"
;	"(c)derp" 
;	"Date"
;	""
;	SF-FONT "font" "Sans"
;	SF-COLOR "Color" '(255 255 255)
;	SF-VALUE "Size" 50
;	SF-VALUE "Width" 512
;	SF-VALUE "Height" 512
;  SF-ROWS "Rows" 10
;  SF-COLUMNS "Columns" 10
;  SF-STRING "Characters" " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~          "
;)
