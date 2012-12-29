//(c) Kakurady 2010, 2011, 2012.
//Includes portions dedicated to the public domain by Nexii Malthus.

string version = "20120902\nSet text on channel 12";

//----- Behaviour -----//
float scale=0.1; // height of line
float line_width = 1.5; //width of line
float height = 0.2; // height of display
integer listen_channel = 12; //channel on which script listens
integer menu_channel = -9013;

integer verbose = 0;
integer say_to_owner = TRUE;

integer centered = TRUE; //center the text on the board instead of starting from the left-top

string nc_name = "metrics"; //name of font notecard

integer access_enabled = FALSE;
////integer access_group = 0; //level 1 can change text, level 2 can access menu
////integer access_public = 0; //
integer access_public = 9013; //
integer access_group = 38; //level 1 can change text, level 2 can access menu
integer access_applied_to_objects = FALSE;

vector float_text_color = <1, 1, 1>;
float  float_text_alpha = 1;

string nc_progress_bar = " ▏▎▍▌▋▊▉█";
list nc_progress_bar_l = ["░","▏","▎","▍","▌","▋","▊","▉","█"];
integer nc_progress_bar_length = 8;

//----- Default Font definition -----//
string tex="droid serif 1"; //name or uuid of texture
string chars=" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         "; //list of characters in order of in texture
list extents=[13, 17, 20, 28, 28, 45, 37, 11, 17, 17, 25, 28, 13, 16, 14, 14, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 14, 13, 28, 28, 28, 25, 46, 35, 33, 31, 36, 31, 30, 36, 40, 18, 18, 35, 31, 47, 38, 37, 30, 37, 33, 27, 31, 36, 34, 52, 33, 31, 30, 18, 14, 18, 28, 23, 29, 28, 31, 25, 31, 27, 18, 27, 32, 16, 15, 29, 16, 47, 32, 29, 31, 31, 24, 23, 18, 32, 29, 43, 29, 28, 26, 21, 28, 21, 28, 13, 13, 13, 13, 13]; //width of each, as a fraction defined by em below
integer em = 50; //font width divider
integer columns = 10; //number of columns in texture
integer rows = 10; //number of row in texture
float bump = -0.01; //some fonts needs some adjustment vertically
//float bump = 0.0;

//----- Some internal stuff -----//
integer LINE_LIST_STRIDE = 3; //how many list items does one line properities occupy

integer dirty = 32767; //what's the highest used item on the last painting

integer DEBUG_LAYOUT = TRUE;

string text;

//notecard reader states
integer NC_DO_NOTHING = 0;
integer NC_INIT = 10;
integer NC_INIT_GET_COUNT = 11;
integer NC_READ_FONT_HEADER = 20;
integer NC_READ_FONT_DEF = 21;

integer nc_line = 1;
integer nc_num_lines = 0;
integer nc_do = 0;
string  nc_what = "";
integer nc_last_section_line = 0;

list typefaces = []; 
list typefaces_index = [];
list typefaces_next_index = [];

list _typefaces;
list _typefaces_index;

string _tex;
string _chars;
list _extents;
integer _em;
integer _columns;
integer _rows;
float _bump;
string _typeface_name = "";
integer nc_type_start_line = 0;
integer nc_type_end_line = 0;

//menu states
//integer PAGE_HOME = 0;
//integer PAGE_FONT_FAMILIES = 1;
integer last_page = 0;

integer num_fonts = 0;
integer typefaces_page = 0;
integer typefaces_total_pages = 0;

key operator_id = NULL_KEY;

integer ACCESS_NONE = 0;
integer ACCESS_WRITE = 1;
integer ACCESS_MENU = 2;

string ACCESS_INDICATOR = "• ";
//string ACCESS_INDICATOR = "";

say(string message, integer verbosity){
    if (verbose >= verbosity){
        if (say_to_owner){
            llOwnerSay(message);
        } else {
            llSay(PUBLIC_CHANNEL, message);
        }
    }
}
warn(string message) {
    if (verbose >= 0){
        if (say_to_owner){
            llOwnerSay(message);
        } else {
            llSay(DEBUG_CHANNEL, message);
        }
    }
}
note(string message) {say(message, 1);}
debug(string message) {say(message, 3);}

integer UTF8Length(string msg)
{
//Returns the number of BYTES a string will have when converted to UTF8 by communication functions
//Simple and efficient!
//Released to the public domain by kimmie Loveless
    integer rNum = llStringLength(msg);
    return rNum + ((llStringLength(llEscapeURL(msg)) - rNum)/4);
}
//-------Menu System-------//
integer divide_and_round_up(integer nom, integer dem){
    if(nom % dem){
        return (nom / dem + 1);
    } else {
        return (nom / dem);
    }
}
list pad(integer length){
    list temp = [];
    integer i;
    for (i = 0; i < length ; i++){
        temp += "□";
    }
    return temp;
}
dlg_main(key avatar){
    llDialog(
        avatar,
        (string)[
        "\n› Main Menu\n",
        "v. ", (string) version
        ],
        ["Fonts","Reset Prims", "Reload Fonts", "Access", "White", "Black"],
        menu_channel
    );
}
dlg_fonts(key avatar){
    
    if (num_fonts > 11){
        string page_indicator = (string)["Page ", typefaces_page+1,"/",typefaces_total_pages];
        integer from = typefaces_page * 9;
        integer to = (typefaces_page + 1) * 9;
        list padding = [];
        if (to > num_fonts){
            padding = pad(to - num_fonts);
            to = num_fonts;
        }
        to -= 1;
        llDialog(
            avatar,
            (string)[
            "\n› Fonts\n", page_indicator
            ],
            ["■ Home", "◀ Prev", "▶ Next"] + llList2List(typefaces, from, to) + padding,
            menu_channel
        );
    } else {
        llDialog(
            avatar,
            (string)[
            "\n› Fonts\n"],
            ["■ Home"] + llList2List(typefaces, 0, 10),
            menu_channel
        );

    }
}
dlg_access(key avatar){
    list buttons = ["■ Home"];
    if (access_public == ACCESS_NONE){
        buttons = buttons + [ACCESS_INDICATOR + "Public Off", "Public On"];
    } else if (access_public == ACCESS_WRITE){
        buttons = buttons + ["Public Off", ACCESS_INDICATOR + "Public On"];
    } else {
        buttons = buttons + ["Public Off", "Public On"];
    }
    
    if (access_group == ACCESS_NONE){
        buttons = buttons + [ACCESS_INDICATOR + "Group Off", "Group On", "Group Menu"];
    } else if (access_group == ACCESS_WRITE){
        buttons = buttons + ["Group Off", ACCESS_INDICATOR + "Group On", "Group Menu"];
    } else if (access_group == ACCESS_MENU){
        buttons = buttons + ["Group Off", "Group On", ACCESS_INDICATOR + "Group Menu"];
    } else {
        buttons = buttons + ["Group Off", "Group On", "Group Menu"];
    }
    
    llDialog(
        avatar,
        (string)[
        "\n› Access\n",
        "The access menu is not yet implemented."],
        //["■ Home", "▶Public Off", "Public On", "Group Off", "Group On", "Group Menu"],
        buttons,
        menu_channel
    );
}

//------Notecard Reader------//

//                  Progress Bar v1                  //
//                  By Nexii Malthus                 //
//                   Public Domain                   //

//http://wiki.secondlife.com/wiki/Progress_Bar
//A bit terse, but why reinvent the wheel?
// (one compelling reason is that this stratergy doesn't work for inputs outside 0.0..1.0)
//for the blank cell.
string Bars( float Cur, integer Bars, list Charset ){
    // Input    = 0.0 to 1.0
    // Bars     = char length of progress bar
    // Charset  = [Blank,<Shades>,Solid];
    integer Shades = llGetListLength(Charset)-1;
            Cur *= Bars;
    integer Solids  = llFloor( Cur );
    integer Shade   = llRound( (Cur-Solids)*Shades );
    integer Blanks  = Bars - Solids - 1;
    string str;
    
    while( Solids-- >0 ) 
        str += llList2String( Charset, -1 );
    if( Blanks >= 0 ) 
        str += llList2String( Charset, Shade );
    while( Blanks-- >0 ) 
        str += llList2String( Charset, 0 );
    return str; 
}
showProgressText(string reason, integer value, integer total){
    if (reason == "") { reason = "Reading Notecard"; }
    float progress = 0.0;
    string progressbar = "";
    if (total > 0){
        progress =  value / (float)total;
        progressbar = Bars(progress, nc_progress_bar_length, nc_progress_bar_l);
    }
    llSetText(
        (string)[reason, "\n", 
            value, "/", total, " ", "|", progressbar, "|"],
        float_text_color, float_text_alpha
    );
}

start_loading_notecard(){
        if(nc_do == NC_DO_NOTHING){
            llSetText((string)["Reading Notecard\n", "..."],float_text_color, float_text_alpha);
            llGetNumberOfNotecardLines(nc_name);
            nc_do = NC_INIT_GET_COUNT;
        } else {
            llOwnerSay("A notecard is currently being read.");
        }
}
notecard_attr_first_line(string what, string value){
    if(what == "chars"){
        
        //to prevent the first space being eaten
        if(llGetSubString(value, 0, 0) != " "){
            value = " " + value;
        }
        notecard_attr_line(what, value);
    } else if (what == "em"){
        _em = (integer) value;
    } else if (what == "columns") {
        _columns = (integer) value;
    } else if (what == "rows") {
        _rows = (integer) value;
    } else if (what == "bump"){
        _bump = (float) value;
    } else {
        notecard_attr_line(what, value);
    }
}
notecard_attr_line(string what, string value){
    if (what == "tex"){
        _tex = _tex + llStringTrim(value, STRING_TRIM);
    } else if (what == "chars") {
        _chars = _chars + value;
    } else if (what == "extents" || what == "aw"){
        list parsed = llParseString2List(value , [",", " "], []);
        list converted = [];
        integer i;
        for (i = 0; i < llGetListLength(parsed); i++){
            converted += (integer) llList2String(parsed, i);
        }
        _extents += converted;
    }

}
notecard_attr_end(string what){
}

integer check_access(key id, integer level){
    if (access_enabled == FALSE) {return TRUE;}
    if (id == llGetOwner())  {return TRUE;}
    if (llSameGroup(id) && level <= access_group) {return TRUE;}
    if (level <= access_public) {return TRUE;}
    if (access_applied_to_objects){
        list l = llGetObjectDetails(id, [OBJECT_OWNER,OBJECT_GROUP]);
        if (llList2Key(l, 0) == llGetOwner()) {return TRUE;}
        //whether the object is owned by someone from the same 
        //group is not checked, because that information isnot avaliable
        // when that person is not in the region. This only checks if
        //the object is deeeded to the same group.
        if (llSameGroup(llList2Key(l, 1)) && level <= access_group) {return TRUE;}
    }
    return FALSE;
}
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

//TODO: Split into Parse and Render stages
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
    text = input;
    
    list lines = do_line_wrapping(input);
    integer num_lines = llGetListLength(lines) / LINE_LIST_STRIDE;
    integer line;
    integer x_line = 0;
    
    integer len = llStringLength(input);
    integer prims = llGetNumberOfPrims();
    integer i = 0; //current prim used
    integer j = 0; //current character
    float lastwidth = 0.0; 
    float thiswidth = 0.0;
    float last_right = 0.0; 
    float this_left = 0.0;
    float first_left= line_width / 2;
    vector posvec = <-first_left, -0.02, 0>;

    //rotation down = llEuler2Rot(<PI_BY_TWO, 0, 0>);
    rotation down = ZERO_ROTATION;
    
    //center text vertically
    //TODO: don't hardcode number of lines
    if (centered){
        posvec.z = (float )(num_lines - 1)/ 2 * scale;
    } else {
        posvec.z =  (height - scale) / 2;
    }
    //todo separate prims and char pointer so spaces can be represented without prims
    //todo switch between starting on 0th prim and 1st prim based on if backing board is present
    for (i = 1, line = 0; i < prims && line < num_lines; line++){
        integer cur_line_begin = llList2Integer(lines, line * LINE_LIST_STRIDE);
        integer cur_line_end   = llList2Integer(lines, line * LINE_LIST_STRIDE + 1);
        integer cur_line_width = llList2Integer(lines, line * LINE_LIST_STRIDE + 2);
        if (x_line < cur_line_width) {x_line = cur_line_width;}

        if(centered){
            posvec.x = posvec.x + (line_width - (float)llList2Integer(lines, line * LINE_LIST_STRIDE + 2) * scale / em)/2;
        }
        for(j = cur_line_begin; j < cur_line_end; i++, j += 5){

            while(j < cur_line_end && llGetSubString(input, j, j) == " "){
                //skip spaces between prims
                j++;
                last_right += (float)(llList2Integer(extents, 0))/em*scale;
            }
            integer x_sp = (llList2Integer(extents, 0));
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
                    sp_post_l = x_sp / 2; sp_pre_m = x_sp - sp_post_l;
                } next++;
            integer m = todex2(input, j+1+skip, cur_line_end);
            
                if (llGetSubString(input, j+2+skip, j+2+skip) == " ") {
                    skip++; next++; 
                    sp_post_m = x_sp / 2; sp_pre_n = x_sp - sp_post_m;
                } next++;
            integer n = todex2(input, j+2+skip, cur_line_end);
            
                if (llGetSubString(input, j+3+skip, j+3+skip) == " ") {
                    skip++; next++;
                    sp_post_n = x_sp / 2; sp_pre_o = x_sp - sp_post_n;
                } next++;            
            integer o = todex2(input, j+3+skip, cur_line_end);
            
                if (llGetSubString(input, j+4+skip, j+4+skip) == " ") {
                    skip++; next++;
                    sp_post_o = x_sp / 2; sp_pre_p = x_sp - sp_post_o;
                } next++;
            integer p = todex2(input, j+4+skip, cur_line_end);
            
            //llOwnerSay((string)[llGetSubString(input, j, j+4+skip), " ", sp_post_l, " " , sp_pre_m, " ", sp_post_o, " ", sp_pre_p]);
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
            //llOwnerSay((string)[x_side, " l", x_left, " ", x_l + x_m + x_n_left, " ",   sp_post_l + sp_pre_m + sp_post_m + sp_pre_n, " r",x_right, " ", x_n_right + x_o + x_p,  " ",  sp_post_n + sp_pre_o + sp_post_o + sp_pre_p]);
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
            
            float x_hollow = (float)sp_pre_n + x_n + sp_post_n;
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
            
            vector offset_l = getGridOffset(l) + <(0.5 - cut_end) * repeat_l + (float)x_l / 2 / 512, 0, 0> + <(float)(sp_post_l) / em / 2 * repeat_l, 0, 0>;
            vector offset_m = getGridOffset(m) + <(float)(x_n_left - x_hollow_gap_left) / 2 / 512, 0, 0> + <(float)(sp_post_m - sp_pre_m)/ em * repeat_m, 0, 0>;;
            vector offset_n = getGridOffset(n) - <(hollow / 2 - 0.5) * repeat_n, 0, 0> ;//-  <(float)(sp_post_n - sp_pre_n)/em / 2 * repeat_n, 0, 0>;
            //llOwnerSay((string)[getGridOffset(n), <(0.5 - hollow / 2), 0, 0>, offset_n]);
            vector offset_o = getGridOffset(o) - <(float)(x_n_right - x_hollow_gap_right) / 2 / 512, 0, 0> + <(float)(sp_post_o - sp_pre_o)/em * repeat_o, 0, 0>;
            vector offset_p = getGridOffset(p) - <(cut_begin - 0.5) * repeat_p + (float)x_p / 2 / 512, 0, 0> + <(float)(- sp_pre_p)/em / 2 * repeat_p, 0, 0>;
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
            PRIM_SIZE, <(float)thiswidth / SQRT2, 0.01 ,scale>,
            PRIM_NAME, llGetSubString(input, j, next)];
            //not the best idea, better trim the list when l=0
            if (i != 0){
                posvec.x += last_right + this_left;
                paramslist =  paramslist + [PRIM_POSITION, posvec, PRIM_ROT_LOCAL, down];
            } else {
                first_left = this_left;
            }
            llSetLinkPrimitiveParamsFast(i+1, paramslist);
            lastwidth = thiswidth;
            last_right = (float) (x_n_right + x_o + x_p +sp_post_n + sp_pre_o + sp_post_o + sp_pre_p) / em * scale;
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
    llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_SIZE, <scale*((float)x_line/(float)em+0.2),0.010, scale*((float)line+0.2)>]);
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
        llSetLinkPrimitiveParams(LINK_ALL_CHILDREN, [
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
        say("Hello, Avatar!", 1);
        do_layout("The quick brown fox jumps over a lazy dog.");
        if (num_fonts < 1){ start_loading_notecard();}
        llListen(menu_channel, "", NULL_KEY, "");
        llListen(listen_channel, "","","");
    }
    touch_start(integer total_number)
    {
//        integer i;
//        key k = NULL_KEY;
//        for (i = 0; i < total_number; i++){
//            key d = llDetectedKey(i);
//            if (d != k){
//                dlg_main(d);
//                k = d;
//            }
//        }

//HACK: Let's hope no more than one person will touch the object each frame!
        if (total_number){
            dlg_main(llDetectedKey(0));
        }
    }
    //text chat event
    listen(integer channel, string name, key id, string msg){
        if (channel == listen_channel){
            if (check_access(id, ACCESS_WRITE)){
                llOwnerSay(name);
                //llOwnerSay(msg);
                do_layout(msg);
            }
        } 
        else if (channel == menu_channel){
            if (check_access(id, ACCESS_MENU)){
                if (operator_id != id){
                    operator_id = NULL_KEY;
                }
                
                //TODO: Seperate out processing for each menu.
                if ("■ Home" == msg){
                    dlg_main(id);
                } 
                else if ("◀ Prev" == msg){
                    typefaces_page -=1;
                    if (typefaces_page < 0){typefaces_page = typefaces_total_pages - 1;}
                    dlg_fonts(id);
                }
                else if ("▶ Next" == msg){
                    typefaces_page +=1;
                    if (typefaces_page >= typefaces_total_pages){typefaces_page = 0;}
                    dlg_fonts(id);
                } 
                else if ("□" == msg){
                    dlg_fonts(id);
                } 
                else if ("Fonts" == msg){
                    dlg_fonts(id);
                }
                else if ("Access" == msg){
                    dlg_access(id);
                } else if ("Reload Fonts" == msg){
                    start_loading_notecard();
                } else if ("Reset Prims" == msg){
                    init();
                    dlg_main(id);
                } else if ("White" == msg){
                    llSetLinkPrimitiveParams(LINK_ALL_CHILDREN, [
                    PRIM_COLOR, ALL_SIDES, <1, 1, 1>, 1.0
                    ]);
                    dlg_main(id);
                } else if ("Black" == msg){
                    llSetLinkPrimitiveParams(LINK_ALL_CHILDREN, [
                    PRIM_COLOR, ALL_SIDES, <0, 0, 0>, 1.0
                    ]);
                    dlg_main(id);
                } else if ("Group Off" == msg){
                    access_group = ACCESS_NONE;
                    say("Group access is now off.", 1);
                    dlg_access(id);
                } else if ("Group On" == msg){
                    access_group = ACCESS_WRITE;
                    note ("Group members can now change messages.");
                    dlg_access(id);
                } else if ("Group Menu" == msg){
                    access_group = ACCESS_MENU;
                    note( "Group members can now access the menu.");
                    dlg_access(id);
                } else if ("Public Off" == msg){
                    access_public = ACCESS_NONE;
                    note("Public access is now off.");
                    dlg_access(id);
                } else if ("Public On" == msg){
                    access_public = ACCESS_WRITE;
                    note("Any person can now change messages.");
                    dlg_access(id);
                } else if (llGetSubString(msg, 0, llStringLength(ACCESS_INDICATOR) - 1) == ACCESS_INDICATOR) {
                    note("Access settings NOT changed.");
                    dlg_access(id);
                } else {
                    integer i;
                    for (i = 0; i < num_fonts; i++){
                        if (llList2String(typefaces, i) == msg){
                            //TODO: Test if avatar and if in region.
                            list noti = ["Selected font", msg , ".\n Now Loading..."];
                            //llInstantMessage(id, (string)noti);
                            //llRegionSayTo(id, PUCLIC_CHANNEL noti)
                            note((string) noti);
                            
                            //dlg_fonts(id);
                            operator_id = id;
                            nc_do = NC_READ_FONT_HEADER;
                            _typeface_name = llList2String(typefaces, i);
                            
                            nc_line = llList2Integer(typefaces_index, i);
                            llGetNotecardLine(nc_name, nc_line);
                            return;
                        }
                    }
                }
            }
        }
    }
    dataserver(key queryid, string data){
//        llOwnerSay((string)["Reading line", nc_line]);
        
        if (nc_do == NC_INIT_GET_COUNT){
            nc_num_lines = (integer) data;
            nc_line = 0;
            _typefaces = [];
            _typefaces_index = [];
            showProgressText("", nc_line, nc_num_lines);
            llGetNotecardLine(nc_name, nc_line);
            nc_do = NC_INIT;
        } else if (nc_do == NC_INIT){
            if (data != EOF){
                integer bytelength = UTF8Length(data);
                
                if(bytelength >= 240 ){
                    if(llGetSubString(data, 0, 0) != "#"){
                        warn((string)["line ", nc_line + 1, " is ", bytelength, " bytes long.\n", 
                        "When read by a script, notecards lines longer than 255 bytes are cut off by Second Life. \n",
                        "This may cause some settings to load incorrectly."  ]);
                    }
                }
                
                if(llGetSubString(data, 0, 0) == "["){
                    integer closing_bracket = llSubStringIndex(data, "]");
                    if (closing_bracket != -1) {
                        string name = llGetSubString(data, 1, closing_bracket -1);
                        _typefaces += [llToLower(name), name, nc_line];
                    }
                }
                //llOwnerSay(data);
                nc_line++;
                showProgressText("", nc_line, nc_num_lines);
                llGetNotecardLine(nc_name, nc_line);
                //nc_do is still NC_INIT
            } else { //data != EOF

                nc_do = NC_DO_NOTHING;
                //FIXME llListSort might be O(n²) on SL and very likely to be O(n²) on OpenSim
                //llOwnerSay(llList2CSV(_typefaces));
                _typefaces = llListSort(_typefaces, 3, TRUE);
                //llOwnerSay(llList2CSV(_typefaces));
                //FIXME llList2ListStrided isn't making any sense.
                typefaces = llList2ListStrided(llDeleteSubList(_typefaces, 0, 0), 0, -1, 3);
                typefaces_index = llList2ListStrided(llDeleteSubList(_typefaces, 0, 1), 0, -1, 3);
                
                num_fonts = llGetListLength(typefaces);
                typefaces_total_pages = divide_and_round_up(num_fonts, 9); // 9 is the number of fonts to display each page, after subtracting the 3 navigation buttons

                say((string)["Loaded ", num_fonts, " fonts."], 2);
                llSetText((string)[""],float_text_color, float_text_alpha);

                //llOwnerSay(llList2CSV(typefaces));
                //llOwnerSay(llList2CSV(typefaces_index));
                //llOwnerSay(llList2CSV(typefaces_next_index));
                
            } // data != EOF
        } else if (nc_do == NC_READ_FONT_HEADER){
            llSetText((string)["Reading Font ", _typeface_name], float_text_color, float_text_alpha);
            //set up temporary variables
            _tex = ""; //required.
            _chars="";
            _extents = []; //required.
            _em = 50;
            _columns = 10;
            _rows = 10;
            _bump = 0;
            
            //TODO verify that we're reading the right section and the notecard was not edited
            nc_do = NC_READ_FONT_DEF;
            nc_what = "";
            nc_line++;
            llGetNotecardLine(nc_name, nc_line);
            
        } else if (nc_do == NC_READ_FONT_DEF){
            llSetText((string)["Reading Font ", _typeface_name], float_text_color, float_text_alpha);

            string leader = llGetSubString(data, 0, 0);
            integer where = 0;                
            if (leader == "#"){
                
                //comment, do nothing
                nc_line++;
                llGetNotecardLine(nc_name, nc_line);
                
            } else if (leader == "[" || data == EOF){
                
                //it's the next section, end reading
                //finish up the previous attribute
                //set variables
                //re-layout and render
                notecard_attr_end(nc_what);
                nc_do = NC_DO_NOTHING;
                
                if (_tex == ""){ //required.
                    //llSay(DEBUG_CHANNEL, "missing texture name in Font definition for [] ");
                    _tex = _typeface_name;
                }; 
                tex = _tex;
                
                if (_em <= 0 ){ // must be positive.
                    llSay(DEBUG_CHANNEL, "character cell size is not a positive integer in Font definition for [] ");
                    _em = 50;
                }
                em = _em;
                
                if (_columns <= 0 ){ // must be positive.
                    llSay(DEBUG_CHANNEL, "number of columns must be larger than zero in Font definition for [] ");
                    _columns = 10;
                } 
                columns = _columns;
                
                if (_rows <= 0 ){ // must be positive.
                    llSay(DEBUG_CHANNEL, "number of rows must be larger than zero in Font definition for [] ");
                    _rows = 10;
                } 
                rows = _rows;
                
                if (_chars == ""){
                    _chars=" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         ";                    
                }
                
                integer cells = columns * rows;
                
                //if (llStringLength(_chars) != llGetListLength(_extents) && cells != llGetListLength(_extents))
                if( FALSE ){
                    llSay(DEBUG_CHANNEL, "number of character data is diferent from the number of characters in Font definition for [] ");
                }
                //comprensate for trimmed spaces
                integer i;
                
                integer num_spaces = cells - llStringLength(_chars);
                string spaces = "";
                for (i = 0; i < num_spaces; i++){
                    spaces += " ";
                }
                chars = _chars + spaces;
                
                if (llGetListLength(_extents) == 0){
                    llSay(DEBUG_CHANNEL, "you need to supply the widths of characters in Font definition for [] ");
                    _extents = [13];
                }
                
                num_spaces = cells - llGetListLength(_extents);
                for (i = 0; i < num_spaces; i++){
                    _extents += llList2Integer(_extents, 0);
                }
                extents = _extents;
                
                bump = _bump;
                
                //Debug: Show the data.
                //llOwnerSay(chars);
                //llOwnerSay(llList2CSV(extents));
                //llOwnerSay(llList2CSV([tex, em, columns, rows, bump]));
                
                llSetText("", float_text_color, float_text_alpha);
                
                dirty = 32767;
                
                do_layout(text);
                //if nobody else have touched the menu, re-show the menu
        
                dlg_fonts (operator_id);
                
            } else if ((where = llSubStringIndex(data, "=")) != -1){
                
                //finish up the previous attribute
                notecard_attr_end(nc_what);
                
                //read in the next attribute
                nc_what = llStringTrim(llGetSubString(data, 0, where - 1 ), STRING_TRIM);
                string contents = llStringTrim(llGetSubString(data, where + 1, -1), STRING_TRIM);
                notecard_attr_first_line(nc_what, contents);
                
                nc_line++;
                llGetNotecardLine(nc_name, nc_line);
                
            } else {
                notecard_attr_line(nc_what, data);
                
                nc_line++;
                llGetNotecardLine(nc_name, nc_line);
            }
//branches except "[" should break to here to get rid of duplicate statements
//            nc_line++;
//            llGetNotecardLine(nc_name, nc_line);
        }
    }
}
