VariText Documentation
==============================

Contents
--------

* Foreword
* Setup
* Usage
* Creating different fonts
    * Metrics notecard
* Bugs/Issues
* Thanks
* License

Setup
-----

You will need the script, a notecard with the name "Metrics" (the script won't run without it), any textures, and some prims. 

1. Link the prims (Build > Link or Ctrl-L).
2. Add the notecard, then the script.
3. Touch the object, enter the Setup menu, choose Reset Prims and Black Text.

Now you may enter anything on Channel 12 and it will be displayed in the font of your choosing.

Configuration
-------------

VariText is very configurable.

It's best that you change the permissions after setup. Otherwise the text may be changed by other people or scripts.

Getting different fonts to work in VariText
-------------------------------------------
You need to download GIMP, and then get this Script-Fu script. (If you have Python installed, you can also use the python version)

Of course you will also need the font installed on our computer. [Google Web Fonts](http://www.google.com/webfonts) has a nice collection of open-source fonts.

Open GIMP, select Plugins > Script-fu > Console. Copy and paste the script into the Script-Fu console. You can also install the script to `<Your Personal Folder>\.gimp-<version>\scripts`.

Run the script like this: `(varitext-make-texture "font name" )`. Don't close the Script-Fu window because you still need the output.

Export as PNG or TGA (From File > Export, File > Save As before GIMP 2.4). If you export as PNG, check "save transparent pixel values", don't check "save background color".

Upload the image.

Add this to your metrics notecard:

    [(Your font name)]
    aw=

Copy and paste the output after `aw=`. Because scripts are only allowed to read up to 255 characters per line, you need to break the lines manually.

Select Setup > Reload Fonts in the script menu. After the script finishes reading the notecard, you can go to the Fonts menu to choose your new font!


# Metrics notecard format

The first character must be empty space. The texture creation scripts don't currently enforce this.

Issues
------

*  If there are more than 100 characters in the font, it's easy to run out of memory. In that case you will need to restart the script.
    * The input is not limited in length so it's possible that a mailicious user can make the script crash, if they are into this sort of thing.
* Prim usage is not ideal: 5 characters per prim. As far as I know, someone managed to put 16 characters on the mesh equivalent of half of a prim...
* The menu system easily takes over half the script.
* It's likely that VariText will not support kerning for a long, long time. (_Kerning_ means adjusting the space between two characters, say between uppercase A and V, sohttp://www.google.com/webfonts that the space between characters looks even.)
* If space folding is on, position of some letters might be incorrect.
* The only way to have a linebreak is copy some text outside the viewer and paste it in; VariText doesn't support escape codes.
* No way to invoke the texture script from GUI and obtain the font data.

Thanks
------
VariText is inspired by XyText written by Xylor Baysklef, Thraxis Epsilon, Kermitt Quick, Awsoonn Rawley, Strife Onizuka, and Tdub Dowler; as well by XyzzyText written by Traven Sachs, Gigs Taggart, Thraxis Epsilon, Strife Onizuka, Huney Jewell, Salahzar Stenvaag, Ruud Lathrop, and Joel Cloquet.

VariText includes portions dedicated to the public domain by Nexii Malthus (Progress Bar v1), kimmie Loveless (UTF8Length function) and others.

License
-------
Copyright (c) 2012 Kakurady (a.k.a. Geneko Nemeth)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(While not required by the license, I would appreciate any feedback, even if it's just saying you've used the script somewhere. Thanks!)

Fonts are copyright their owners and are avaliable under their own licenses.

Changelog
---------

