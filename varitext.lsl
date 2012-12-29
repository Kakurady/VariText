string chars=" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~         ";
list extents=[15, 12, 17, 39, 28, 37, 25, 10, 14, 14, 19, 35, 12, 21, 21, 23, 27, 13, 26, 27, 30, 29, 25, 25, 27, 24, 13, 12, 22, 31, 23, 17, 41, 31, 27, 30, 33, 30, 26, 37, 32, 12, 18, 26, 28, 47, 35, 37, 31, 35, 24, 34, 34, 30, 38, 39, 34, 31, 36, 19, 25, 19, 22, 35, 25, 24, 24, 22, 25, 24, 23, 23, 21, 10, 14, 22, 11, 28, 25, 22, 21, 25, 22, 22, 25, 22, 24, 30, 22, 27, 26, 15, 11, 16, 30, 15, 15, 15, 15, 15];
integer em=50;
float scale=1;
integer columns=10;
integer rows=10;
string tex="nekotoba2";
integer listen_channel = 1;

vector getGridOffset(integer index){
   integer row = index / columns; 
   integer col = index % columns; 
   
   return <(col + 0.5)/columns - 0.5, -(row+0.5)/rows + 0.5, 0>;
}
do_layout(string input){
    integer len = llStringLength(input);
    integer prims = llGetNumberOfPrims();
    integer i = 0; integer j = 0;
    float lastwidth = 0.0; 
    float thiswidth = 0.0;
    float last_right = 0.0; 
    float this_left = 0.0;
    vector posvec = <0, 0, 0>;
    float first_left= 0;
    //rotation down = llEuler2Rot(<PI_BY_TWO, 0, 0>);
    rotation down = ZERO_ROTATION / llGetRootRotation();
    
    //todo separate prims and char pointer so spaces can be represented without prims
    for (i = 0, j=0; i< prims && j < len; i++, j+=4){
        while(j < len && todex(input, j) == 0){
            j++;
            //lastwidth += (float)(llList2Integer(extents, 0))/em*scale*2;
            last_right += (float)(llList2Integer(extents, 0))/em*scale;
        }
        //index of character
        integer l = todex(input, j+0);
        integer m = todex(input, j+1);
        integer n = todex(input, j+2);
        integer o = todex(input, j+3);
        //width of chracter
        integer x_l = llList2Integer(extents, l);
        integer x_m = llList2Integer(extents, m);
        integer x_n = llList2Integer(extents, n);
        integer x_o = llList2Integer(extents, o);
        
        integer x_left = x_l + x_m;
        integer x_right = x_n + x_o;
        integer x_side;
        if (x_left > x_right){
            x_side = x_left;
        } else {
            x_side = x_right;
        }
        integer space_before_l = ((em - llList2Integer(extents, (l/columns + (l+columns-1)%columns))) + (em - x_l))/2;
        integer space_after_o = ((em - llList2Integer(extents, (o/columns + (o+1)%columns))) + (em - x_o))/2;
        if (x_side > space_before_l + x_l + x_m || x_side > x_n + x_o + space_after_o){
            llOwnerSay("Not enough space: " +llGetSubString(input, j, j+3)+ " "+(string)[x_side, " ", space_before_l + x_l + x_m, " ", x_n + x_o + space_after_o]);
        }
        thiswidth = (float)(x_side * 2)/em*scale;
        this_left = (float)(x_l+x_m)/em*scale;
        
        float cut_end = 1.0 - (float) x_m / x_side;
        float cut_begin = (float) x_n / x_side;
        
        float repeat_l = (float) x_side / 512;
        float repeat_m = (float) x_m / 512;
        float repeat_n = (float) x_n / 512;
        float repeat_o = (float) x_side / 512;
        vector offset_l = getGridOffset(l) + <(0.5 - cut_end) * repeat_l + (float)x_l / 2 / 512, 0, 0>;
        vector offset_m = getGridOffset(m);
        vector offset_n = getGridOffset(n);
        vector offset_o = getGridOffset(o) - <(cut_begin - 0.5) * repeat_o + (float)x_o / 2 / 512, 0, 0>;
        //llOwnerSay((string) [repeat_l, " ",repeat_o, offset_l, offset_o]);
        
        list paramslist = [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, 
            <cut_begin / 4, cut_end / 4 + 0.75, 0.0>, 0.0, <0.25, 0.25, 0.0 >, 
            ///<(float)x_m/(x_l+x_m+x_n), 1.0, 0>, 
//            <(float)(x_l-x_n)/(2*(x_l+x_m+x_n)), 0.0, 0>,
        <1.0, 1.0, 0>,
        <0.0, 0.0, 0>,
        PRIM_TEXTURE, 4, tex, <repeat_l, 0.1, 0.0> , offset_l, 0.0,
        PRIM_TEXTURE, 7, tex, <repeat_m, 0.1, 0.0> , offset_m, 0.0,
        PRIM_TEXTURE, 6, tex, <repeat_n, 0.1, 0.0> , offset_n, 0.0,
        PRIM_TEXTURE, 1, tex, <repeat_o, 0.1, 0.0> , offset_o, 0.0,
        PRIM_SIZE, <(float)thiswidth / SQRT2, 0.01 ,scale>];
        //not the best idea, better trim the list when l=0
        if (i != 0){
            posvec.x += last_right + this_left;
            if (posvec.x > 10){
                posvec.x = -first_left +this_left;
                posvec.z -= scale;
            }
            paramslist =  paramslist + [PRIM_POSITION, posvec, PRIM_ROTATION, down];
        } else {
            first_left = this_left;
        }
        llSetLinkPrimitiveParamsFast(i+1, paramslist);
        lastwidth = thiswidth;
        last_right = (float) (x_n + x_o) / em * scale;
    }
    //pad everything with spaces from here
    for(; i< prims ; i++){
    llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <-0.45,0.45,0>, 0.0]);
    }
}
integer todex(string input, integer pos){
    integer result = llSubStringIndex(chars, llGetSubString(input, pos,pos));
    if (result == -1) return 0;
    return result;
}
init(){
        llSetLinkPrimitiveParams(LINK_SET, [
        PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <0.45,-0.45,0>, 0.0,
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
