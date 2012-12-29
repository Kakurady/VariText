float scale=0.2; // height of line
float line_width = 3; //width of line
integer listen_channel = 1; //channel on which script listens


string tex="nekotoba2"; //name or uuid of texture
string chars=" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         "; //list of characters in order of in texture
list extents=[15, 12, 17, 39, 28, 37, 25, 10, 14, 14, 19, 35, 12, 21, 21, 23, 27, 13, 26, 27, 30, 29, 25, 25, 27, 24, 13, 12, 22, 31, 23, 17, 41, 31, 27, 30, 33, 30, 26, 37, 32, 12, 18, 26, 28, 47, 35, 37, 31, 35, 24, 34, 34, 30, 38, 39, 34, 31, 36, 19, 25, 19, 22, 35, 25, 24, 24, 22, 25, 24, 23, 23, 21, 10, 14, 22, 11, 28, 25, 22, 21, 25, 22, 22, 25, 22, 24, 30, 22, 27, 26, 15, 11, 16, 30, 15, 15, 15, 15, 15]; //width of each, multiplied by em
integer em=50; //font width divider
integer columns=10; //number of columns in texture
integer rows=10; //number of row in texture
//float bump = -0.01; //some fonts needs some adjustment vertically
float bump = 0.0;

integer LINE_LIST_STRIDE = 2;

vector getGridOffset(integer index){
   integer row = index / columns; 
   integer col = index % columns; 
   
   return <(col + 0.5)/columns - 0.5, -(row+0.5)/rows + 0.5 + bump, 0>;
}
integer space_before(integer dx){
    integer before_dx = (dx/columns + (dx+columns-1)%columns);
    integer x_dx = llList2Integer(extents, dx);
    integer x_before_dx = llList2Integer(extents, before_dx);
    
    return ((em - x_before_dx) + (em - x_dx))/2;
}
integer space_after (integer dx){
    integer after_dx = (dx/columns + (dx+1)%columns);
    integer x_dx = llList2Integer(extents, dx);
    integer x_after_dx = llList2Integer(extents, after_dx);
    
    return ((em - x_after_dx) + (em - x_dx))/2;
}
list do_line_wrapping(string input){
    integer len = llStringLength(input);
    integer prims = llGetNumberOfPrims();
    integer i = 0;

    integer cur_word_begin = 0;
    integer cur_word_end = 0;
    integer x_width = (integer)(line_width / scale * em);
//    llOwnerSay((string) x_width);
    integer x_word = 0;
    list debug_list = [];
    list words = [];
    integer num_words = 0;
    integer WORDS_LIST_STRIDE = 3; //begin, end, advance length
    
    //more variable definitions below before actually wrapping words
    
    //split string into words.
    while (i < len){
        if(llGetSubString(input, i, i) == " "){
            if (cur_word_begin != cur_word_end){
                words += [cur_word_begin, cur_word_end, x_word];
                x_word = 0;
                num_words++;
            }
            cur_word_begin = cur_word_end = (i + 1);
            //don't add just yet
        } else { // character is printable 
        //TODO: What about newlines?
            integer dx = todex(input, i);
            integer x_dx = llList2Integer(extents, dx);
            
            x_word += x_dx;
            cur_word_end = i + 1;
            
        }
        i++;
    }
    if (cur_word_begin != cur_word_end){
        words += [cur_word_begin, cur_word_end, x_word];
        x_word = 0;
        num_words++;
    }
    
    //DEBUG: print all the words.
//    for(i = 0; i < num_words; i++){
//        cur_word_begin = llList2Integer(words, i * WORDS_LIST_STRIDE + 0);
//        cur_word_end = llList2Integer(words, i * WORDS_LIST_STRIDE + 1);
//        integer x_dx = llList2Integer(words, i * WORDS_LIST_STRIDE + 2);
//        if (cur_word_begin < cur_word_end){
//            debug_list += [llGetSubString(input, cur_word_begin, cur_word_end - 1), x_dx];
//        } else {
//            debug_list += ["WARNING: word is empty", cur_word_begin, cur_word_end, x_dx];
//        }
//    }
//    llOwnerSay(llList2CSV(debug_list));

    integer cur_line_begin = 0;
    integer cur_line_end = 0;
    integer x_line = 0;
    integer j = 0;
    list lines = [];
    for(i = 0; i < num_words; i++){
        cur_word_begin = llList2Integer(words, i * WORDS_LIST_STRIDE + 0);
        cur_word_end = llList2Integer(words, i * WORDS_LIST_STRIDE + 1);
        integer x_word  = llList2Integer(words, i * WORDS_LIST_STRIDE + 2);
        if (x_word < x_width){
            integer new_width = x_line + x_word;
            //TODO: switch branches
            //(in the name of performance... not really important)
            if (new_width > x_width){
                //start a new line.
                lines += [cur_line_begin, cur_line_end];
                x_line = x_word;
                cur_line_begin = cur_word_begin;
                cur_line_end = cur_word_end;
            } else {
                x_line = new_width;
                cur_line_end = cur_word_end;
            }
        } else { 
            // this is an overlong word.
            // put as much word on each line.
            for(j = cur_word_begin; j < cur_word_end; j++){
                integer dx = todex(input, j);
                integer x_dx = llList2Integer(extents, dx);
                
                x_line += x_dx;
                if (x_line > x_width){
                    //start a new line.
                    //cur_line_end is "before" j
                    lines += [cur_line_begin, cur_line_end];
                    x_line = x_dx;
                    cur_line_begin = j;
                    cur_line_end = j + 1;
                } else {
                    cur_line_end = j + 1;
                }
            }
        }
        //now add the space for non-printables.
        //TODO: newlines?
        
        //TODO: will fix later, now just pretend spaces don't take spaces
        if((i + 1) < num_words){
            x_line += llList2Integer(extents, 0);
        } else {
            //last word! 
            lines += [cur_line_begin, cur_line_end];
        }
    }
    //DEBUG: print the final layout.
//    len = llGetListLength(lines);
//    for (i = 0; i < len; i += LINE_LIST_STRIDE){
//        cur_line_begin = llList2Integer(lines, i);
//        cur_line_end   = llList2Integer(lines, i + 1);
//        if (cur_line_begin < cur_line_end){
//            llOwnerSay(llGetSubString(input, cur_line_begin, cur_line_end - 1));
//        } else {
//            //empty line
//            llOwnerSay("");
//        }
//    }
    
    return lines;
}
do_layout(string input){
    list lines = do_line_wrapping(input);
    integer num_lines = llGetListLength(lines) / LINE_LIST_STRIDE;
    integer line;
    
    integer len = llStringLength(input);
    integer prims = llGetNumberOfPrims();
    integer i = 0; //current prim used
    integer j = 0; //current character
    float lastwidth = 0.0; 
    float thiswidth = 0.0;
    float last_right = 0.0; 
    float this_left = 0.0;
    vector posvec = <0, 0, 0>;
    float first_left= 0;
    //rotation down = llEuler2Rot(<PI_BY_TWO, 0, 0>);
    rotation down = ZERO_ROTATION / llGetRootRotation();
    
    //todo separate prims and char pointer so spaces can be represented without prims
    for (i = 0, line = 0; i < prims && line < num_lines; line++){
        integer cur_line_begin = llList2Integer(lines, line * LINE_LIST_STRIDE);
        integer cur_line_end   = llList2Integer(lines, line * LINE_LIST_STRIDE + 1);
        for(j = cur_line_begin; j < cur_line_end; i++, j += 5){

            while(j < len && todex(input, j) == 0){
                j++;
                last_right += (float)(llList2Integer(extents, 0))/em*scale;
            }
            //index of character
            integer l = todex2(input, j+0, cur_line_end);
            integer m = todex2(input, j+1, cur_line_end);
            integer n = todex2(input, j+2, cur_line_end);
            integer o = todex2(input, j+3, cur_line_end);
            integer p = todex2(input, j+4, cur_line_end);
            //width of chracter
            integer x_l = llList2Integer(extents, l);
            integer x_m = llList2Integer(extents, m);
            integer x_n = llList2Integer(extents, n);
            integer x_o = llList2Integer(extents, o);
            integer x_p = llList2Integer(extents, p);
            
            integer x_n_left = x_n / 2;
            integer x_n_right = x_n - x_n_left;
            
            integer x_left = x_l + x_m + x_n_left;
            integer x_right = x_n_right + x_o + x_p;
            integer x_side;
            if (x_left > x_right){
                x_side = x_left;
            } else {
                x_side = x_right;
            }
            integer space_before_l = space_before(l);
            integer space_after_m = space_after(m);
            integer space_before_n = space_before(n);
            integer space_after_n = space_after(n);
            integer space_before_o = space_before(o);
            integer space_after_p = space_after(p);
            if (x_side > space_before_l + x_l + x_m + x_n_left || x_side > x_n_right + x_o + x_p + space_after_p){
                //llSay(DEBUG_CHANNEL, "Not enough space in texture avaliable to pad out prim face:" +llGetSubString(input, j, j+3)+ " "+(string)[x_side, " ", space_before_l + x_l + x_m + x_n_left, " ", x_n_right + x_o + x_p + space_after_p]);
            }
            thiswidth = (float)(x_side * 2)/em*scale;
            this_left = (float)(x_left)/em*scale;
            
            float x_hollow = (float)x_n;
            float hollow = x_hollow / 2 / x_side;
            
            float cut_end = 1.0 - (float) (x_m + x_n_left) / x_side;
            float cut_begin = (float) (x_n_right + x_o) / x_side;
            
            float x_hollow_gap_left = (1.0 - cut_end) * x_side * hollow;
            float x_hollow_gap_right = cut_begin * x_side * hollow;
            
            float repeat_l = (float) x_side / 512;
            float repeat_m = (float) (x_m + x_n_left - x_hollow_gap_left) / 512;
            float repeat_n = -(float) x_side / 512 * 4;
            float repeat_o = (float) (x_o + x_n_right - x_hollow_gap_right) / 512;
            float repeat_p = (float) x_side / 512;
            ;
            
            vector offset_l = getGridOffset(l) + <(0.5 - cut_end) * repeat_l + (float)x_l / 2 / 512, 0, 0>;
            vector offset_m = getGridOffset(m) + <(float)(x_n_left - x_hollow_gap_left) / 2 / 512, 0, 0>;
            vector offset_n = getGridOffset(n) - <(hollow / 2 - 0.5) * repeat_n, 0, 0>;
            //llOwnerSay((string)[getGridOffset(n), <(0.5 - hollow / 2), 0, 0>, offset_n]);
            vector offset_o = getGridOffset(o) - <(float)(x_n_right - x_hollow_gap_right) / 2 / 512, 0, 0>;
            vector offset_p = getGridOffset(p) - <(cut_begin - 0.5) * repeat_p + (float)x_p / 2 / 512, 0, 0>;
            //llOwnerSay((string) [repeat_l, " ",repeat_o, offset_l, offset_o]);
            
            list paramslist = [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, 
                <cut_begin / 4, cut_end / 4 + 0.75, 0.0>, hollow, <0.25, 0.25, 0.0 >, 
                ///<(float)x_m/(x_l+x_m+x_n), 1.0, 0>, 
    //            <(float)(x_l-x_n)/(2*(x_l+x_m+x_n)), 0.0, 0>,
            <1.0, 1.0, 0>,
            <0.0, 0.0, 0>,
            PRIM_TEXTURE, 4, tex, <repeat_l, 0.1, 0.0> , offset_l, 0.0,
            PRIM_TEXTURE, 8, tex, <repeat_m, 0.1, 0.0> , offset_m, 0.0,
            PRIM_TEXTURE, 5, tex, <repeat_n, 0.1, 0.0> , offset_n, 0.0,
            PRIM_TEXTURE, 7, tex, <repeat_o, 0.1, 0.0> , offset_o, 0.0,
            PRIM_TEXTURE, 1, tex, <repeat_p, 0.1, 0.0> , offset_p, 0.0,
            PRIM_SIZE, <(float)thiswidth / SQRT2, 0.01 ,scale>];
            //not the best idea, better trim the list when l=0
            if (i != 0){
                posvec.x += last_right + this_left;
                paramslist =  paramslist + [PRIM_POSITION, posvec, PRIM_ROTATION, down];
            } else {
                first_left = this_left;
            }
            llSetLinkPrimitiveParamsFast(i+1, paramslist);
            lastwidth = thiswidth;
            last_right = (float) (x_n_right + x_o + x_p) / em * scale;
        }
        
        //break a new line.
        last_right = 0;
        posvec.x = -first_left;
        posvec.z -= scale;

    }
    //pad everything with spaces from here
    for(; i< prims ; i++){
    llSetLinkPrimitiveParams(i+1,[PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <-0.45,0.45,0>, 0.0]);
    }
}
integer todex(string input, integer pos){
    integer result = llSubStringIndex(chars, llGetSubString(input, pos,pos));
    if (result == -1) return 0;
    return result;
}
integer todex2(string input, integer pos, integer limit){
    if (pos < limit) return todex(input, pos);
    return 0;
}
init(){
        llSetLinkPrimitiveParams(LINK_SET, [
        PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <-0.45, 0.45,0>, 0.0,
        PRIM_SIZE, <(float)scale*1.2, 0.01,scale>
        ]);
}
default
{


    state_entry()
    {
        llSay(0, "Script running");
        init();
        do_layout("The quick brown fox jumps over a lazy dog.");
        llListen(listen_channel, "","","");
    }
    listen(integer channel, string name, key id, string msg){
        do_layout(msg);
    }
}
