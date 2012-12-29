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
    (chars " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         ")

   )
   (let 
    (
     ;GRAY instead of RGB should be fine too, you can add color in-world
     ;but I'm not sure if this will make SL use less memory for the texture.
     (img (car (gimp-image-new width height RGB)))
     (num_chars (string-length chars))
    ) 
    (let 
     ((layer dcar (gimp-layer-new img width height RGBA-IMAGE "blah" 1.0 NORMAL-MODE))))
     (begin
      (gimp-image-add-layer img layer 0)
      (gimp-context-set-foreground color)
      (letrec
       (
        (prepend ;not tail-recursive
         (lambda (list1 list2)
          (cond
           ((null? list1) list2)
           (else (cons (car list1) (prepend (cdr list1) list2)))
        ))) ;prepend ends
        (derp4
         (lambda (extents txt)
          (cond
           ((null? extents) (cons #\[ txt))
           (
            (null? (cdr extents)) 
            (derp4 
             (cdr extents) 
             (prepend (string->list (number->string (car extents))) txt)
           ))
           (else 
            (derp4 
             (cdr extents) 
             (cons #\, ( cons #\space
               (prepend (string->list (number->string (car extents))) txt)
        ))))))) ;derp4 ends
        (row-loop
         (lambda (row derp1)
          (cond
           ((>= row rows) derp1)
           ((>= (* row columns) num_chars) derp1)
           (else (row-loop (+ 1 row) (col-loop row 0 derp1)))
        ))) ; row-loop ends
        (col-loop
         (lambda (row col derp2)
          (cond
           ((>= col columns) derp2)
           ((>= (+ col (* row columns)) num_chars) derp2)
           (else
            (let
             ((charr (string (string-ref chars (+ col (* row columns)))) ))
             (let
              ((c_w 
                (car (gimp-text-get-extents-fontname charr size PIXELS font))
              ))
              (let
               (
                (y (* row (/ height rows)))
                (x (- (* (+ col 0.5) (/ width columns)) (/ c_w 2)))
               )
               (begin
               ; Can I use #t instead of TRUE?
                ;(print (list img layer x y charr 0 
                ; TRUE size PIXELS font))
                (gimp-text-fontname img -1 x y charr 0 
                 TRUE size PIXELS font)
                (col-loop row (+ 1 col) (cons c_w derp2) )
       ))))))))) ; col-loop ends
       (let
        ((extents (row-loop 0 ())))
        (begin
         (gimp-image-merge-visible-layers img CLIP-TO-IMAGE)
         (gimp-display-new img)      
         (list->string (derp4 extents '(#\])))
))))))))) ; define ends

;font, color, size, width, height, rows, columns
(define vwts-make-texture
 (lambda (font)
  (vwts-make-texture-full font '(255 255 255) 50 512 512 10 10)
))
