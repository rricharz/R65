{ IMILLTEK: include file for TEKMILL }

const
    CX    = 536;
    CY    = 450;
    SPACE = 100;

    LEFTX   = 100;
    RIGHTX  = 924;
    RESTOP  = 690;
    RESPACE = 60;

    DASHX      = 125;
    DASHWHITEY = 63;
    DASHBLACKY = 15;
    DASHWIDTH  = 95;
    DASHHEIGHT = 48;
    MSGOFF     = 3;
    INPUTOFF   = 13;
    STONEOFF   = 29;
    NAMEOFF    = 37;

    I_PLACE  = 1;
    I_MOVE   = 2;
    I_TAKE   = 3;
    I_NAME   = 4;

proc init_graphics;
begin
  _starttek;
end;

proc init_canvas;
{***************}
const
  NAMEY  = 725;
var
  charwidth: integer;
begin
  _clearscreen;
  _setchsize(1);

  charwidth:=(MAXX+1) div MAXCOLUMNS;

  if automode then begin
    _moveto(LEFTX-4*charwidth,NAMEY);
    write(@PLOTTER,'COMPUTER');
  end
  else begin
    _moveto(LEFTX-3*charwidth,NAMEY);
    write(@PLOTTER,'PLAYER');
  end;

  _moveto(RIGHTX-4*charwidth,NAMEY);
  write(@PLOTTER,'COMPUTER');
end;

proc _rectangle(x, y, sx, sy, mode: integer);
begin
  if (mode=WHITE) then begin
    _startdraw(x, y);
    _draw(x + sx, y);
    _draw(x + sx, y + sy);
    _draw(x, y + sy);
    _draw(x, y);
    _enddraw;
    end;
end;

proc vector(x1,y1,x2,y2,color: integer);
begin
end;

proc endpoints(x1,y1,x2,y2: integer);
begin
end;

proc message(number: integer; field: packed char;
             player: integer);
begin
end;

proc strmessage(s:cpnt; player: integer);
begin
end;

func findpos(labelvalue: packed char): integer;
begin
  findpos:=-1;
end;

proc getinput(player,request0: integer;
              var p1,p2: integer);
begin
  writeln('abort: getinput not yet implemented');
  _moveto(0,0);
  _abort;
end;

proc tekstone(x,y,player: integer);
{********************************}
begin
  { outline }
  _startdraw(x+16,y);
  _draw(x+14,y+8);
  _draw(x+8,y+14);
  _draw(x,y+16);
  _draw(x-8,y+14);
  _draw(x-14,y+8);
  _draw(x-16,y);
  _draw(x-14,y-8);
  _draw(x-8,y-14);
  _draw(x,y-16);
  _draw(x+8,y-14);
  _draw(x+14,y-8);
  _draw(x+16,y);
  _enddraw;

  { white stones are shaded }
  if player=WHITE then begin
    _drawvector(x-5,y-15,x+15,y-3);
    _drawvector(x-10,y-12,x+15,y+3);
    _drawvector(x-14,y-8,x+14,y+8);
    _drawvector(x-15,y-3,x+10,y+12);
    _drawvector(x-15,y+3,x+5,y+15);
  end;
end;

proc drawstone(pos,player: integer);
{*********************************}
var x,y: integer;
begin
  x:=CX+
    (ord(low(label[pos]))-ord('4'))*SPACE;
  y:=CY+
    (ord(high(label[pos]))-ord('D'))*SPACE;

  tekstone(x,y,player);
end;

proc drawboard;
{*************}
{ draw one quadrant and rotate it four times }
const
  GAP   = 20;

  proc fourvectors(x1,y1,x2,y2: integer);
  begin
    { original }
    _drawvector(CX+x1,CY+y1,
                CX+x2,CY+y2);

    { rotate 90 degrees }
    _drawvector(CX-y1,CY+x1,
                CX-y2,CY+x2);

    { rotate 180 degrees }
    _drawvector(CX-x1,CY-y1,
                CX-x2,CY-y2);

    { rotate 270 degrees }
    _drawvector(CX+y1,CY-x1,
                CX+y2,CY-x2);
  end;

begin
  _setlinemode(SOLID);

  { outer square }
  fourvectors(GAP,3*SPACE,
              3*SPACE-GAP,3*SPACE);
  fourvectors(3*SPACE,3*SPACE-GAP,
              3*SPACE,GAP);

  { middle square }
  fourvectors(GAP,2*SPACE,
              2*SPACE-GAP,2*SPACE);
  fourvectors(2*SPACE,2*SPACE-GAP,
              2*SPACE,GAP);

  { inner square }
  fourvectors(GAP,SPACE,
              SPACE-GAP,SPACE);
  fourvectors(SPACE,SPACE-GAP,
              SPACE,GAP);

  { connections between squares }
  fourvectors(0,SPACE+GAP,
              0,2*SPACE-GAP);
  fourvectors(0,2*SPACE+GAP,
              0,3*SPACE-GAP);
end;

proc drawstones;
{**************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    if board[position]<>EMPTY then
      drawstone(position,board[position]);
end;

proc clearstone(stone,player: integer);
begin
end;

proc drawlabels;
{**************}
const
  HCHARWIDTH  = 7;
  HCHARHEIGHT = 11;
var
  i: integer;
  c: char;
begin
  _setchsize(1);

  { 1..7 below the board }
  for i:=0 to 6 do begin
    c:=chr(ord('1')+i);
    _moveto(CX+(i-3)*SPACE-HCHARWIDTH+4,
            CY-3*SPACE-45);
    write(@PLOTTER,c);
  end;

  { A..G left of the board }
  for i:=0 to 6 do begin
    c:=chr(ord('A')+i);
    _moveto(CX-3*SPACE-45,
            CY+(i-3)*SPACE-HCHARHEIGHT+5);
    write(@PLOTTER,c);
  end;
end;

proc cleardashstone(stone,player: integer);
begin
end;

proc dashstone(stone,player,color: integer);
begin
end;

proc selectdashboard(player: integer);
begin
end;

proc drawreserve(player: integer);
{****************************}
const
  LEFTX    = 100;
  RIGHTX   = 924;
  TOP      = 690;
  RESPACE  = 60;
var
  stone,x,y,color: integer;
begin
  if player=WHITE then
    x:=LEFTX
  else
    x:=RIGHTX;

  for stone:=0 to 8 do begin
    y:=TOP-stone*RESPACE;

    if stone<stones[player] then
      color:=player
    else
      color:=EMPTY;

    if stone>8-captured[player] then
      color:=otherplayer(player);

    if color<>EMPTY then
      tekstone(x,y,color);
  end;
end;

proc redraw;
{**********}
var x,y,mode: integer;
    okay: boolean;
begin
  _clearscreen;
  init_canvas;
  drawboard;
  drawlabels;
  drawstones;
  drawreserve(WHITE);
  drawreserve(BLACK);
  okay:=_query(x,y,mode);
end;