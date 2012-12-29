//----- Behaviour -----//
float scale=0.1; // height of line
float line_width = 1.5; //width of line
integer listen_channel = 12; //channel on which script listens

integer centered = TRUE; //center the text on the board instead of starting from the left-top

//----- Font definition -----//
string tex="nekotoba2 (no shadow)"; //name or uuid of texture
string chars=" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         "; //list of characters in order of in texture
//list extents=[13, 17, 20, 28, 28, 45, 37, 11, 17, 17, 25, 28, 13, 16, 14, 14, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 14, 13, 28, 28, 28, 25, 46, 35, 33, 31, 36, 31, 30, 36, 40, 18, 18, 35, 31, 47, 38, 37, 30, 37, 33, 27, 31, 36, 34, 52, 33, 31, 30, 18, 14, 18, 28, 23, 29, 28, 31, 25, 31, 27, 18, 27, 32, 16, 15, 29, 16, 47, 32, 29, 31, 31, 24, 23, 18, 32, 29, 43, 29, 28, 26, 21, 28, 21, 28, 13, 13, 13, 13, 13]; //width of each, as a fraction defined by em below
list extents=[15, 12, 17, 39, 28, 37, 25, 10, 14, 14, 19, 35, 12, 21, 21, 23, 27, 13, 26, 27, 30, 29, 25, 25, 27, 24, 13, 12, 22, 31, 23, 17, 41, 31, 27, 30, 33, 30, 26, 37, 32, 12, 18, 26, 28, 47, 35, 37, 31, 35, 24, 34, 34, 30, 38, 39, 34, 31, 36, 19, 25, 19, 22, 35, 25, 24, 24, 22, 25, 24, 23, 23, 21, 10, 14, 22, 11, 28, 25, 22, 21, 25, 22, 22, 25, 22, 24, 30, 22, 27, 26, 15, 11, 16, 30, 15, 15, 15, 15, 15];
integer em = 50; //font width divider
integer columns = 10; //number of columns in texture
integer rows = 10; //number of row in texture
//float bump = -0.01; //some fonts needs some adjustment vertically
float bump = 0.0;

//----- Some internal stuff -----//
integer LINE_LIST_STRIDE = 3; //how many list items does one line properities occupy

integer dirty = 32767; //what's the highest used item on the last painting

integer DEBUG_LAYOUT = TRUE;

//----- Actual program starts here -----//

//Returns the actual texture coordinates from character index.
vector getGridOffset(integer index){
   integer row = index / columns; 
   integer col = index % columns; 
   
   return <(col + 0.5)/columns - 0.5, -(row+0.5)/rows + 0.5 + bump, 0>;
}

//Returns the empty space avaliable before the character for us to work with.
// This is equal to half of the space around the character,
// plus half of the space around the character before.
integer space_before(integer dx){
    integer before_dx = (dx/columns + (dx+columns-1)%columns);
    integer x_dx = llList2Integer(extents, dx);
    integer x_before_dx = llList2Integer(extents, before_dx);
    
    return ((em - x_before_dx) + (em - x_dx))/2;
}

//Returns the empty space avaliable after the character for us to work with.
// This is equal to half of the space around the character,
// plus half of the space around the character after.
integer space_after (integer dx){
    integer after_dx = (dx/columns + (dx+1)%columns);
    integer x_dx = llList2Integer(extents, dx);
    integer x_after_dx = llList2Integer(extents, after_dx);
    
    return ((em - x_after_dx) + (em - x_dx))/2;
}
integer is_whitespace (string char){
    if (char == " ") return TRUE;
    if (char == "\n") return TRUE;
    //other characters to be done
    return FALSE;
}

//split text into lines
//input: The text to be wrapped.
//return: T list with stride 3, containing the start of the line, the end of it, and the width of the line.
list do_line_wrapping(string input){
    integer len = llStringLength(input);
    integer prims = llGetNumberOfPrims();
    integer i = 0;

    //Note this function uses a somewhat different definition of character position than Second Life's,
    // but more similar to Visual Basic and Python.
    // In this scheme, 0 means "the position before the first character"
    // and 1 means "after the first character".
    // So a range of 1-3 means "the second and the third character".
    // A range of 5-5 represents no character at all.
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
        string current_char = llGetSubString(input, i, i);
        if(is_whitespace(current_char)){
            if (cur_word_begin != cur_word_end){ 
                // we have just came out of a word.
                words += [cur_word_begin, cur_word_end, x_word];
                x_word = 0;
                num_words++;
            }
            // Advance the "cursor" after the current character (a whitespace).
            cur_word_begin = cur_word_end = (i + 1);
        } else { // character is printable 
            
            integer dx = todex(input, i); //This is slow: O(number of chars in texture); but can't go any faster.
            integer x_dx = llList2Integer(extents, dx);
            
            // Add the width of the current character to the current word.
            x_word += x_dx;
            // Advance the selection past the current character.
            cur_word_end = i + 1;
            
        }
        i++;
    }
    //We are in the middle of a word at the end of the string.
    // Add that word.
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

    //The definition of character position is still the same.
    integer cur_line_begin = 0;
    integer cur_line_end = 0;
    integer x_line = 0; //width of line
    integer j = 0;
    list lines = [];
    
    for(i = 0; i < num_words; i++){
        
        cur_word_begin = llList2Integer(words, i * WORDS_LIST_STRIDE + 0);
        cur_word_end = llList2Integer(words, i * WORDS_LIST_STRIDE + 1);
        integer x_word  = llList2Integer(words, i * WORDS_LIST_STRIDE + 2);
        
        if (x_word < x_width){
            // At least this word can fit into one line.
            integer new_width = x_line + x_word;
            if (new_width > x_width){
                // Won't fit into current line: start a new line.
                lines += [cur_line_begin, cur_line_end, x_line];
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
                    lines += [cur_line_begin, cur_line_end, x_line - x_dx];
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
            integer next_word_begin = llList2Integer(words, (i + 1) * WORDS_LIST_STRIDE + 0);
            for (j = cur_word_end; j < next_word_begin; j++){
                string current_char = llGetSubString(input, j, j);
                if (current_char == "\n"){
                    lines += [cur_line_begin, cur_line_end, x_line];
                    x_line = 0;
                    cur_line_begin = j+1;
                    cur_line_end = j+1;
                } else {
                    //assume it's a space.
                    x_line += llList2Integer(extents, 0);
                }
            }
        } else {
            //last word! 
            lines += [cur_line_begin, cur_line_end, x_line];
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
    float first_left= line_width / 2;
    vector posvec = <-first_left, -0.02, 0.05>;

    //rotation down = llEuler2Rot(<PI_BY_TWO, 0, 0>);
    rotation down = ZERO_ROTATION;
    
    //center text vertically
    //TODO: don't hardcode number of lines
    if (centered && num_lines < 2){
        posvec.z -= scale / 2;
    }
    //todo separate prims and char pointer so spaces can be represented without prims
    //todo switch between starting on 0th prim and 1st prim based on if backing board is present
    for (i = 1, line = 0; i < prims && line < num_lines; line++){
        integer cur_line_begin = llList2Integer(lines, line * LINE_LIST_STRIDE);
        integer cur_line_end   = llList2Integer(lines, line * LINE_LIST_STRIDE + 1);

        if(centered){
            posvec.x = posvec.x + (line_width - (float)llList2Integer(lines, line * LINE_LIST_STRIDE + 2) * scale / em)/2;
        }
        for(j = cur_line_begin; j < cur_line_end; i++, j += 5){

            while(j < cur_line_end && llGetSubString(input, j, j) == " "){
                //skip spaces between prims
                j++;
                last_right += (float)(llList2Integer(extents, 0))/em*scale;
            }
            integer skip = 0;
            integer next = j;
            integer sp_post_l = 0;
            integer sp_pre_m  = 0;
            integer sp_post_m = 0;
            integer sp_pre_n  = 0;
            integer sp_post_n = 0;
            integer sp_pre_o  = 0;
            integer sp_post_o = 0;
            integer sp_pre_p  = 0;
            
            integer l = todex2(input, j, cur_line_end);
            
                if (llGetSubString(input, j+1+skip, j+1+skip) == " ") {
                    skip++; next++; 
                    sp_post_l = sp_pre_m = llList2Integer(extents, 0) / 2;
                } next++;
            integer m = todex2(input, j+1+skip, cur_line_end);
            
                if (llGetSubString(input, j+2+skip, j+2+skip) == " ") {
                    skip++; next++; 
                    sp_post_m = sp_pre_n = llList2Integer(extents, 0) / 2;
                } next++;
            integer n = todex2(input, j+2+skip, cur_line_end);
            
                if (llGetSubString(input, j+3+skip, j+3+skip) == " ") {
                    skip++; next++;
                    sp_post_n = sp_pre_o = llList2Integer(extents, 0) / 2;
                } next++;            
            integer o = todex2(input, j+3+skip, cur_line_end);
            
                if (llGetSubString(input, j+4+skip, j+4+skip) == " ") {
                    skip++; next++;
                    sp_post_o = sp_pre_p = llList2Integer(extents, 0) / 2;
                } next++;
            integer p = todex2(input, j+4+skip, cur_line_end);
            
            //width of chracter
            integer x_l = llList2Integer(extents, l);
            integer x_m = llList2Integer(extents, m);
            integer x_n = llList2Integer(extents, n);
            integer x_o = llList2Integer(extents, o);
            integer x_p = llList2Integer(extents, p);
            
            integer x_n_left = x_n / 2;
            integer x_n_right = x_n - x_n_left;
            
            integer x_left = x_l + x_m + x_n_left 
                + sp_post_l + sp_pre_m + sp_post_m + sp_pre_n;
            integer x_right = x_n_right + x_o + x_p
                + sp_post_n + sp_pre_o + sp_post_o + sp_pre_p;
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
            
            float x_hollow = (float)(sp_pre_n + x_n + sp_post_n);
            float hollow = x_hollow / 2 / x_side;
            
            float cut_end = 1.0 - (float) (x_m + x_n_left + sp_pre_m + sp_post_m + sp_pre_n ) / x_side;
            float cut_begin = (float) (x_n_right + x_o + sp_post_n + sp_pre_o + sp_post_o ) / x_side;
            
            float x_hollow_gap_left = (1.0 - cut_end) * x_side * hollow;
            float x_hollow_gap_right = cut_begin * x_side * hollow;
            
            float repeat_l = (float) x_side / 512;
            float repeat_m = (float) ((sp_pre_m + x_m + sp_post_m) + (sp_pre_n + x_n_left) - x_hollow_gap_left) / 512;
            float repeat_n = -(float) x_side / 512 * 4;
            float repeat_o = (float) ((sp_pre_o + x_o + sp_post_o) + (sp_post_n + x_n_right) - x_hollow_gap_right) / 512;
            float repeat_p = (float) x_side / 512;
            ;
            
            vector offset_l = getGridOffset(l) + <(0.5 - cut_end) * repeat_l + (float)x_l / 2 / 512, 0, 0> + <(float)(sp_post_l) / 2 / em / columns, 0, 0>;
            vector offset_m = getGridOffset(m) + <(float)(x_n_left - x_hollow_gap_left) / 2 / 512, 0, 0> + <(float)(-sp_pre_m + sp_post_m) / 2 / em / columns, 0, 0>;
            vector offset_n = getGridOffset(n) - <(hollow / 2 - 0.5) * repeat_n, 0, 0> + <(float)(-sp_pre_n + sp_post_n) / 2 / em / columns, 0, 0>;;
            //llOwnerSay((string)[getGridOffset(n), <(0.5 - hollow / 2), 0, 0>, offset_n]);
            vector offset_o = getGridOffset(o) - <(float)(x_n_right - x_hollow_gap_right) / 2 / 512, 0, 0> + <(float)(-sp_pre_o + sp_post_o) / 2 / em / columns, 0, 0>;;
            vector offset_p = getGridOffset(p) - <(cut_begin - 0.5) * repeat_p + (float)x_p / 2 / 512, 0, 0> + <(float)(-sp_pre_p) / 2 / em /columns , 0, 0>;;
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
                paramslist =  paramslist + [PRIM_POSITION, posvec, PRIM_ROT_LOCAL, down];
            } else {
                first_left = this_left;
            }
            llSetLinkPrimitiveParamsFast(i+1, paramslist);
            lastwidth = thiswidth;
            last_right = (float) ( x_n_right +sp_post_n + sp_pre_o + x_o + sp_post_o + sp_pre_p + x_p) / em * scale;
            j += skip;
        }
        
        //break a new line.
        last_right = 0;
        posvec.x = -first_left;
        posvec.z -= scale;

    }
    //pad everything with spaces from here
    for(j=i; j< prims && j< dirty; j++){
    llSetLinkPrimitiveParamsFast(j+1,[PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <-0.45,0.45,0>, 0.0]);
    }
    dirty = i;
}

//Find the location of a character in string in the texture (which square is it occupying).
//
//llSubStringIndex is probably O(n) but there aren't any better methods for turning a character into a number.
//user-written ord() will probably be slower.
//
//input: string to be displayed on the panel (after unescaping)
//pos: which character in string to look up
integer todex(string input, integer pos){
    integer result = llSubStringIndex(chars, llGetSubString(input, pos,pos));
    if (result == -1) return 0;
    return result;
}
//Like todex, but returns 0 (position reserved for space) for items after a certain position.
//used to "mask out" faces that are past the width of the display.
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
    //script entry point
    //displahy some test words, and start listening
    state_entry()
    {
        llSay(0, "Script running");
        //init();
        do_layout("The quick brown fox jumps over a lazy dog.");
        llListen(listen_channel, "","","");
    }
    //text chat event
    listen(integer channel, string name, key id, string msg){
        do_layout(msg);
    }
    touch_start(integer num_detected){
        llSay(0, (string)["Instructions: type /", listen_channel," <whatever you want> to change the text on the board."]);
    }
}
