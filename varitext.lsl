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
    float lastwidth = 0.0; float thiswidth = 0.0;
    vector posvec = <0, 0, 0>;
    
    //todo separate prims and char pointer so spaces can be represented without prims
    for (i = 0, j=0; i< prims && j < len; i++, j+=3){
        //might not be that good idea after all- may lead to dangling linksets
        //which isn't possible with new link rules
        while(j < len && todex(input, j) == 0){
            j++;
            lastwidth += (float)(llList2Integer(extents, 0))/em*scale*2;
        }
        integer l = todex(input, j+0);
        integer m = todex(input, j+1);
        integer n = todex(input, j+2);
        integer x_l = llList2Integer(extents, l);
        integer x_m = llList2Integer(extents, m);
        integer x_n = llList2Integer(extents, n);
        thiswidth = (float)(x_l+x_m+x_n)/em*scale;
        list paramslist = [PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, 
            <0.0, 1.0, 0.0>, 0.0, <0.0, 0.0, 0.0 >, <(float)x_m/(x_l+x_m+x_n), 1.0, 0>, 
            <(float)(x_l-x_n)/(2*(x_l+x_m+x_n)), 0.0, 0>,
        PRIM_TEXTURE, 4, tex, <(float)x_l/512, 0.1, 0.0>, getGridOffset(l), PI_BY_TWO,
        PRIM_TEXTURE, 0, tex, <(float)x_m/512, 0.1, 0.0>, getGridOffset(m), 0.0,
        PRIM_TEXTURE, 2, tex, <(float)x_n/512, 0.1, 0.0>, getGridOffset(n), -PI_BY_TWO,
        PRIM_SIZE, <(float)thiswidth, scale,0.01> ];
        //not the best idea, better trim the list when l=0
        if (i != 0){
            posvec.x += lastwidth /2 + thiswidth /2;
            //OpenSim special.
            if (posvec.x > 10){
                posvec.x = thiswidth /2;
                posvec.y -= scale;
            }
            paramslist = [PRIM_POSITION, posvec] + paramslist;
        }
        llSetLinkPrimitiveParamsFast(i+1, paramslist);
        //llOwnerSay((string)thiswidth);
        lastwidth = thiswidth;
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
        PRIM_TYPE, PRIM_TYPE_BOX, PRIM_HOLE_DEFAULT, 
            <0.0, 1.0, 0.0>, 0.0, <0.0, 0.0, 0.0 >, <(float)0.333, 1.0, 0>, 
            <0.0, 0.0, 0>,
        PRIM_TEXTURE, ALL_SIDES, tex, <(float)0.1, 0.1, 0.0>, <0.05,0.05,0>, 0.0,
        PRIM_SIZE, <(float)scale*1.2, scale,0.01>
        ]);
}
default
{


    state_entry()
    {
        llSay(0, "Script running");
        do_layout("The quick brown fox jumps over a lazy dog.");
        llListen(listen_channel, "","","");
    }
    listen(integer channel, string name, key id, string msg){
        do_layout(msg);
    }
}
