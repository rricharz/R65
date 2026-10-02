{ IMILLTEK: include file for TEKMILL }

const
    CX    = 536;
    CY    = 450;
    SPACE = 100;

    LEFTX   = 100;
    RIGHTX  = 924;
    RESTOP  = 690;
    RESPACE = 60;

    LEFTMSGX   = 250;
    RIGHTMSGX  = 650;
    MSGY       = 50;
    INPUTHEIGHT = 16;
    NAMEHEIGHT  = 32;

    I_PLACE  = 1;
    I_MOVE   = 2;
    I_TAKE   = 3;
    I_NAME   = 4;

proc redraw; forward;

proc init_graphics;
{*****************}
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

  PROTOCOL:=NULLDEV;
  if DEBUG=PRINTER then DEBUG:=OUTPUT;

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
{***********************************************}
begin
  _setchsize(1);

  if player=WHITE then
    _moveto(LEFTMSGX,MSGY)
  else
    _moveto(RIGHTMSGX,MSGY);

  case number of
    0: begin end;
    1: write(@PLOTTER,field,' BAD POS');
    2: write(@PLOTTER,field,' INVALID');
    3: write(@PLOTTER,field,' EMPTY');
    4: write(@PLOTTER,field,' WHITE');
    5: write(@PLOTTER,field,' BLACK');
    6: write(@PLOTTER,field,' OCCUPIED');
    7: write(@PLOTTER,'BAD MOVE');
    8: write(@PLOTTER,field,' IS MILL');
   10: write(@PLOTTER,'LOST');
   11: write(@PLOTTER,'WINS');
   21: write(@PLOTTER,'THINKING');
   27: write(@PLOTTER,'SAVED')
   else write(@PLOTTER,'ERROR ',number)
  end;
end;

proc strmessage(s:cpnt; player: integer);
{***************************************}
begin
  _setchsize(1);

  if s[0]<>ENDMARK then begin

    if player=WHITE then
      { WHITE message field }
      _moveto(LEFTMSGX,MSGY)

    else if player=BLACK then
      { BLACK message field }
      _moveto(RIGHTMSGX,MSGY)

    else
      { computer action/input field }
      _moveto(RIGHTMSGX,MSGY+INPUTHEIGHT);

    write(@PLOTTER,s);
  end;
end;

func findpos(labelvalue: packed char): integer;
{*********************************************}
var position: integer;
begin
  position:=0;
  while (position<NPOSITIONS) and
        (labelvalue<>label[position]) do
    position:=position+1;

  if position<NPOSITIONS then
    findpos:=position
  else
    findpos:=-1;
end;

proc getinput(player, request0: integer;
              var p1,p2: integer);
{**************************************}

const BACKSPACE = chr(127);

var s: cpnt;
    len,maxlen,request,oldrequest: integer;
    valid: boolean;

  proc prompt;
  var px,py: integer;
  begin
    if player=WHITE then
      px:=LEFTMSGX
    else
      px:=RIGHTMSGX;

    if request=I_NAME then
      py:=MSGY+NAMEHEIGHT
    else
      py:=MSGY+INPUTHEIGHT;

    _moveto(px,py);

    case request of
      I_PLACE: write(@PLOTTER,'PLACE?');
      I_MOVE:  write(@PLOTTER,'MOVE?');
      I_TAKE:  write(@PLOTTER,'TAKE?');
      I_NAME:  write(@PLOTTER,'NAME?')
    end;
  end;

  proc editinput;
  var c: char;
  begin
    len:=0;
    s[0]:=ENDMARK;

    if request=I_MOVE then
      maxlen:=5
    else
      maxlen:=4;       { enough for QUIT }

    prompt;

    repeat
      read(@KEY,c);

      if c=BACKSPACE then begin
        if len>0 then begin
          len:=len-1;
          s[len]:=ENDMARK;
          write(@PLOTTER,BACKSPACE);
        end
      end

      else if c<>CR then begin
        if len<maxlen then begin
          s[len]:=c;
          len:=len+1;
          s[len]:=ENDMARK;
          write(@PLOTTER,c);
        end
      end

    until c=CR;
  end;

begin { getinput }

  request:=request0;
  s:=_new;
  s[0]:=ENDMARK;

  repeat

    oldrequest:=request;
    valid:=false;
    p1:=-1;
    p2:=-1;

    editinput;

    writeln(@PROTOCOL,'COMMAND ',s);

    if _strcmp(s,'QUIT')=0 then
      quit;

    if _strcmp(s,'SAVE')=0 then begin
      request:=I_NAME;

      { put NAME input on the following line }
      editinput;

      writeln(@PROTOCOL,'NAME ',s);

      redraw;
      savegame(s,player);
      message(27,'  ',player);

      { return to the original request }
      request:=oldrequest;

    end

    else begin

      { redraw before validation, so any error
        message is written onto the new screen }

      writeln(@DEBUG,'COMMAND ',s,' LEN ',len);
      redraw;
      writeln(@DEBUG,'AFTER REDRAW');

      valid:=false;
      p1:=-1;
      p2:=-1;

      case request of

        I_PLACE,I_TAKE:
          begin
            if len=2 then begin
              writeln(@DEBUG,'CHARS ',
                    ord(s[0]),' ',ord(s[1]));
              p1:=findpos(packed(s[0],s[1]));
              writeln(@DEBUG,'FINDPOS ',p1);
              if p1>=0 then
                valid:=true
              else
                message(2,packed(s[0],s[1]),player);
            end
            else
              message(1,'  ',player);
          end;

        I_MOVE:
          begin
            if (len=5) and (s[2]='-') then begin
              p1:=findpos(packed(s[0],s[1]));

              if p1<0 then
                message(2,packed(s[0],s[1]),player)

              else begin
                p2:=findpos(packed(s[3],s[4]));

                if p2<0 then
                  message(2,packed(s[3],s[4]),player)
                else
                  valid:=true;
              end
            end
            else
              message(1,'  ',player);
          end
      end;

    end;

    writeln(@DEBUG,'VALID ',valid);
  until valid;

  message(0,'  ',player);
  _release(s);
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
  writeln(@DEBUG,'REDRAW');
  _clearscreen;
  init_canvas;
  drawboard;
  drawlabels;
  drawstones;
  drawreserve(WHITE);
  drawreserve(BLACK);

  _purgeinput;
  okay:=_query(x,y,mode);
end;