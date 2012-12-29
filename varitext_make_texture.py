def python_xytext(font="Tahoma",color=(255,255,255),size=50,
    width=512,height=512,rows=10,columns=10,
    chars = " !\"#$%&'()*+,-./0123456789:;<=>?"
            "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
            "`abcdefghijklmnopqrstuvwxyz{|}~         "):

    img = gimp.Image(width, height, RGB)
    layer = gimp.Layer(img, "blah", width, height, RGBA_IMAGE, 100, NORMAL_MODE)
    img.add_layer(layer, 0)
    gimp.set_foreground(color)
    
    f_w, f_h, f_asc, f_desc = pdb.gimp_text_get_extents_fontname(chars,size,PIXELS,font)
    #print f_w, f_h, f_asc, f_desc
    
    extents = []
    try:
        for row in range(rows):
            for col in range(columns):
                index = row * columns + col
                c_w, c_h, c_asc, c_desc = pdb.gimp_text_get_extents_fontname(chars[index],size,PIXELS,font)
                extents.append(c_w)
                y=(row+0.5)*(height/rows)- f_h/2
                x=(col+0.5)*(width/columns)- c_w/2
                #print repr(chars[index]), c_w, c_h, c_asc, c_desc
                pdb.gimp_text_fontname(img,layer,x,y,chars[index],0,TRUE,size,PIXELS,font)
    except IndexError:
        pass
    
    merged = pdb.gimp_image_merge_visible_layers(img, 1)
    mask = pdb.gimp_layer_create_mask(merged, ADD_ALPHA_MASK)
    pdb.gimp_layer_add_mask(merged, mask)
    merged.fill(WHITE_FILL)
    
    gimp.Display(img)
    print extents

