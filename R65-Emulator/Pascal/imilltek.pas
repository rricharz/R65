{ IMILLTEK: include file for TEKMILL (graphics) }

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

var
    savedinput: cpnt;       { EMPTY = 4 }
    drawsuppressed: boolean;

    markplace,marktake,markmove1,markmove2: integer;

proc redraw; forward;

proc init_graphics;
{*****************}
begin
  _starttek;
  savedinput:=_new;
  savedinput[0]:=ENDMARK;
  drawsuppressed:=false;
  markplace:=-1;
  marktake:=-1;
  markmove1:=-1;
  markmove2:=-1;
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


  _moveto(LEFTX-3*charwidth,NAMEY);
   write(@PLOTTER,'PLAYER');

  _moveto(RIGHTX-4*charwidth,NAMEY);
  write(@PLOTTER,'COMPUTER');
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
    1: write(@PLOTTER,'Invalid input');
    2: write(@PLOTTER,field,' is not a position');
    3: write(@PLOTTER,field,' is empty');
    4: write(@PLOTTER,field,' is white');
    5: write(@PLOTTER,field,' is black');
    6: write(@PLOTTER,field,' is occupied');
    7: write(@PLOTTER,'Invalid move');
    8: write(@PLOTTER,field,' is in a mill');
   10: write(@PLOTTER,'Loser');
   11: write(@PLOTTER,'Winner');
   12: write(@PLOTTER,'Game aborted');
   21: write(@PLOTTER,'Thinking...');
   27: write(@PLOTTER,'Game saved')
   else write(@PLOTTER,'Error ',number)
  end;
end;

proc strmessage(s:cpnt; player: integer);
{***************************************}
begin
  _setchsize(1);

  { save persistent computer information }
  if player=EMPTY then
    _strcpy(s,savedinput);

  if player=BLACK then exit;

  { an empty string changes the saved state,
    but writes nothing on the Tek screen }
  if s[0]<>ENDMARK then begin

    if player=WHITE then
      _moveto(LEFTMSGX,MSGY)

    else if player=BLACK then
      _moveto(RIGHTMSGX,MSGY)

    else
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

proc square(pos: integer);
{************************}
const SIZE=18;
var   x,y:integer;
begin
  if drawsuppressed then exit;
  x:=CX+
    (ord(low(label[pos]))-ord('4'))*SPACE;
  y:=CY+
    (ord(high(label[pos]))-ord('D'))*SPACE;
  _startdraw(x-SIZE,y-SIZE);
  _draw(x+SIZE,y-SIZE);
  _draw(x+SIZE,y+SIZE);
  _draw(x-SIZE,y+SIZE);
  _draw(x-SIZE,y-SIZE);
  _enddraw;
end;

proc rect(pos1,pos2: integer);
{*****************************}
const SIZE=18;
var x1,y1,x2,y2,xmin,xmax,ymin,ymax: integer;
begin
  if drawsuppressed then exit;

  x1:=CX+
    (ord(low(label[pos1]))-ord('4'))*SPACE;
  y1:=CY+
    (ord(high(label[pos1]))-ord('D'))*SPACE;

  x2:=CX+
    (ord(low(label[pos2]))-ord('4'))*SPACE;
  y2:=CY+
    (ord(high(label[pos2]))-ord('D'))*SPACE;

  if x1<x2 then begin
    xmin:=x1-SIZE;
    xmax:=x2+SIZE;
  end else begin
    xmin:=x2-SIZE;
    xmax:=x1+SIZE;
  end;

  if y1<y2 then begin
    ymin:=y1-SIZE;
    ymax:=y2+SIZE;
  end else begin
    ymin:=y2-SIZE;
    ymax:=y1+SIZE;
  end;

  _startdraw(xmin,ymin);
  _draw(xmax,ymin);
  _draw(xmax,ymax);
  _draw(xmin,ymax);
  _draw(xmin,ymin);
  _enddraw;
end;

proc getinput(player, request0: integer;
              var p1,p2: integer);
{**************************************}

const BACKSPACE = chr(127);
      STOPCODE  = $2010;
      GAP       = 20;

var s: cpnt;
    len,maxlen,request,oldrequest: integer;
    valid: boolean;

  func findtekpos(x,y: integer): integer;
  var p,px,py,result: integer;
  begin
    result:=-1;

    p:=0;
    while (p<NPOSITIONS) and
          (result<0) do begin

      px:=CX+
        (ord(low(label[p]))-ord('4'))*SPACE;
      py:=CY+
        (ord(high(label[p]))-ord('D'))*SPACE;

      if (x>=px-GAP) and (x<=px+GAP) and
         (y>=py-GAP) and (y<=py+GAP) then
        result:=p;

      p:=p+1;
    end;

    findtekpos:=result;
  end;

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
      x,y,p: integer;
      ok: boolean;
  begin
    len:=0;
    s[0]:=ENDMARK;

    if request=I_MOVE then
      maxlen:=5
    else
      maxlen:=4;       { enough for QUIT }

    prompt;
    _purgeinput;

    repeat
      _moveto(0,0);
      ok:=_getcrosshair(c,x,y);

      if ok then begin

        prompt;
        write(@PLOTTER,s);

        { capitalize like read(@KEY,c) }
        if (c>='a') and (c<='z') then
            c:=chr(ord(c)-ord('a')+ord('A'));

        { mouse input }
        if c=' ' then begin
          p:=findtekpos(x,y);

          if p>=0 then begin

            case request of

              I_PLACE,I_TAKE:
                begin
                  s[0]:=high(label[p]);
                  s[1]:=low(label[p]);
                  s[2]:=ENDMARK;
                  len:=2;
                  write(@PLOTTER,s);
                  c:=CR;
                end;

              I_MOVE:
                begin
                  if len=0 then begin
                    s[0]:=high(label[p]);
                    s[1]:=low(label[p]);
                    s[2]:='-';
                    s[3]:=ENDMARK;
                      len:=3;
                    write(@PLOTTER,s);

                    _setlinemode(SHORTDASH);
                    square(p);
                    _setlinemode(SOLID);
                  end else if len=3 then begin
                    s[3]:=high(label[p]);
                    s[4]:=low(label[p]);
                    s[5]:=ENDMARK;
                    len:=5;
                    write(@PLOTTER,label[p]);
                    c:=CR;
                  end;
                end
            end
          end
        end

        { normal keyboard input }
        else if c=BACKSPACE then begin

          { cancel completed FROM position }
          if (request=I_MOVE) and (len=3) then begin
            len:=0;
            s[0]:=ENDMARK;
            redraw;
            prompt;

          end else if len>0 then begin
            len:=len-1;
            s[len]:=ENDMARK;
            write(@PLOTTER,BACKSPACE);
          end

        end else if c<>CR then begin
          if len<maxlen then begin
            s[len]:=c;
            len:=len+1;
            s[len]:=ENDMARK;
            write(@PLOTTER,c);

            { mark keyboard-entered FROM position }
            if (request=I_MOVE) and
                 (len=3) and (s[2]='-') then begin
              p:=findpos(packed(s[0],s[1]));
              if p>=0 then begin
                _setlinemode(SHORTDASH);
                square(p);
                _setlinemode(SOLID);
              end
            end
          end
        end

      end;

    until (c=CR) or not ok;

    _purgeinput;
  end;

begin { getinput }
  if firstredraw then
    firstredraw:=false
  else
    redraw;
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

    if _strcmp(s,'QUIT')=0 then begin

      quit;
      message(12,'  ',WHITE);
      _moveto(0,0);
      call(STOPCODE);
    end;

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
      redraw;

    end

    else begin

      valid:=false;
      p1:=-1;
      p2:=-1;

      case request of

        I_PLACE,I_TAKE:
          begin
            if len=2 then begin
              p1:=findpos(packed(s[0],s[1]));
              debug('FINDPOS',p1);

              if p1>=0 then
                valid:=true
              else begin
                redraw;
                message(2,packed(s[0],s[1]),player);
              end;
            end
            else begin
              redraw;
              message(1,'  ',player);
            end;
          end;

        I_MOVE:
          begin
            if (len=5) and (s[2]='-') then begin
              p1:=findpos(packed(s[0],s[1]));

              if p1<0 then begin
                redraw;
                message(2,packed(s[0],s[1]),player);
              end

              else begin
                p2:=findpos(packed(s[3],s[4]));

                if p2<0 then begin
                  redraw;
                  message(2,packed(s[3],s[4]),player);
                end
                else
                  valid:=true;
              end
            end
            else begin
              redraw;
              message(1,'  ',player);
            end;
          end
      end;
    end;

    debug('VALID',valid);
  until valid;

  message(0,'  ',player);
  drawsuppressed:=true;
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
  if drawsuppressed then exit;
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
  if marks then begin
    _setlinemode(SHORTDASH);

    if markplace>=0 then square(markplace);

    if marktake>=0 then square(marktake);

    if (markmove1>=0) and (markmove2>=0) then
      if isneighbor(markmove1,markmove2) then
        rect(markmove1,markmove2)
      else begin
        { FLY: mark source and destination }
        square(markmove1);
        square(markmove2);
      end;

    _setlinemode(SOLID);
  end;
end;

proc clearstone(stone,player: integer);
{*************************************}
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
{************************************}
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
  if drawsuppressed then exit;
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
  debug('REDRAW');

  drawsuppressed:=false;
  _clearscreen;
  init_canvas;
  drawboard;
  drawlabels;
  drawstones;
  drawreserve(WHITE);
  drawreserve(BLACK);

  if savedinput[0]<>ENDMARK then begin
    _moveto(RIGHTMSGX,MSGY+INPUTHEIGHT);
    write(@PLOTTER,savedinput);
  end;

  _purgeinput;
  okay:=_query(x,y,mode);
end;

proc quit;
{********}
var result: integer;
const C_SHELL = 10;
      C_FLUSHPRINT = 13;
      C_NEWPRINT = 14;

  proc shell(s: cpnt);
  { uses flp scratch register to transfer pointer }
  mem   str    = $0004: cpnt;
  var result:   integer;
  begin
    str := s;
    result:=_emulator(C_SHELL);
  end;

begin
  redraw;
  _moveto(0,0);
  if PROTOCOL<>NULLDEV then begin
    result := _emulator(C_FLUSHPRINT);
    shell('./backup_print mill');
    result := _emulator(C_NEWPRINT);
  end;
end;


proc screenmessage(s:cpnt);
{*************************}
begin
  writeln(s);
end;

proc clearmarks;
{***************}
begin
  markplace:=-1;
  marktake:=-1;
  markmove1:=-1;
  markmove2:=-1;
end;
