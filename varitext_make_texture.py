def python_xytext(font="Tahoma",color=(255,255,255),size=50,
    width=512,height=512,rows=10,columns=10,
    chars = " !\"#$%&'()*+,-./0123456789:;<=>?"
            "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
            "`abcdefghijklmnopqrstuvwxyz{|}~         "):

    """
The author of this function is too lazy to document it.
"""
    #Create Image with width and height in RGB mode.
    #
    # GRAY instead of RGB should be fine too, you can add color in-world
    # but while the resulting PNG/TGA will take less space
    # I'm not sure if this will make SL use less memory for the texture.
    img = gimp.Image(width, height, RGB)
    layer = gimp.Layer(img, "blah", width, height, RGBA_IMAGE, 100, NORMAL_MODE)
    
    img.disable_undo()
    img.add_layer(layer, 0)
    gimp.set_foreground(color)
    
    f_w, f_h, f_asc, f_desc = pdb.gimp_text_get_extents_fontname(chars,size,PIXELS,font)
    #print f_w, f_h, f_asc, f_desc
    
    #Draw characters.
    extents = []
    try:
        for row in range(rows):
            for col in range(columns):
                index = row * columns + col
                c_w, c_h, c_asc, c_desc = pdb.gimp_text_get_extents_fontname(chars[index],size,PIXELS,font)
                extents.append(c_w)
                y = (row+0.5) * (height/rows) - f_h/2
                x = (col+0.5) * (width/columns) - c_w/2
                #print repr(chars[index]), c_w, c_h, c_asc, c_desc
                pdb.gimp_text_fontname(img,layer,x,y,chars[index],0,TRUE,size,PIXELS,font)
    except IndexError:
        pass

    #Transfer the alpha channel to a mask
    # and fill the layer with the selected color.
    # this is to give even the transparent pixels a color value
    # which will prevent "halos" appearing 
    merged = img.merge_visible_layers(CLIP_TO_IMAGE)
    mask = merged.create_mask(ADD_ALPHA_MASK)
    merged.add_mask(mask)
    merged.fill(FOREGROUND_FILL)
    # apply-and-remove ("bake") the mask to prevent user accidentally saving it.
    merged.remove_mask(MASK_APPLY)
    
    img.enable_undo()
    gimp.Display(img)
    print extents

