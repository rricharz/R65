{ section for MILL on onbard screen (plotlib) }
{ ############################################}

const
    SPACING = 16;
    X0 = 15;
    Y0 = 15;

    DASHX      = 125;
    DASHWHITEY = 63;
    DASHBLACKY = 15;
    DASHWIDTH  = 95;
    DASHHEIGHT = 48;
    MSGOFF     = 3;
    INPUTOFF   = 13;
    STONEOFF   = 29;
    NAMEOFF    = 37;

proc init_canvas;
{***************}
begin
  DEBUG := PRINTER;
  _grinit;
  _fullview;
  _cleargr;
  end;

proc vector(x1,y1,x2,y2, color: integer);
{***************************************}
begin
  _move(x1,y1);
  _draw(x2,y2,color);
end;

proc endpoints(x1,y1,x2,y2: integer);
{***********************************}
begin
  _plot(x1,y1,WHITE);
  _plot(x2,y2,WHITE);
end;

proc message(number: integer; field: packed char;
           player: integer);
{***********************************************}
var  y, dummy: integer;
begin
  if player=WHITE then
    y := DASHWHITEY
  else
    y := DASHBLACKY;

  _move(DASHX+1, y+MSGOFF);
  write(@PLOTDEV,'           '); { 11 blanks }

  _move(DASHX+1, y+MSGOFF);
  case number of
    0: begin end;
    1: write(@PLOTDEV,field,' BAD POS');
    2: write(@PLOTDEV,field,' INVALID');
    3: write(@PLOTDEV,field,' EMPTY');
    4: write(@PLOTDEV,field,' WHITE');
    5: write(@PLOTDEV,field,' BLACK');
    6: write(@PLOTDEV,field,' OCCUPIED');
    7: write(@PLOTDEV,'BAD MOVE');
    8: write(@PLOTDEV,field,' IS MILL');
   10: write(@PLOTDEV,'LOST');
   11: write(@PLOTDEV,'WINS');
   21: write(@PLOTDEV,'THINKING');
   27: write(@PLOTDEV,'SAVED')
   else write(@PLOTDEV,'ERROR ', number)
  end;
  {if number=21 then
    dummy:=_syncscreen;}
end;

proc strmessage(s:cpnt; player: integer);
{***************************************}
var  y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY
  else if player=BLACK then
    y:=DASHBLACKY
  else
    y:=DASHBLACKY+INPUTOFF-MSGOFF;
  _move(DASHX+1, y+MSGOFF);
  write(@PLOTDEV,'           '); { 11 blanks }
  _move(DASHX+1, y+MSGOFF);
  write(@PLOTDEV,s);
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

const
  I_PLACE  = 1;
  I_MOVE   = 2;
  I_TAKE   = 3;
  I_NAME   = 4;

proc getinput(player, request0: integer;
              var p1,p2: integer);
{**************************************}

const TOGGLE    = chr(12);
      BACKSPACE = chr(127);

var s: cpnt;
    x,y,len,maxlen, request, oldrequest: integer;
    valid: boolean;

  proc prompt;
  begin
    _move(DASHX+1,y);
    case request of
      I_PLACE:
        begin
          write(@PLOTDEV,'PLACE?');
          x:=DASHX+1+6*8;
        end;
      I_MOVE:
        begin
          write(@PLOTDEV,'MOVE?');
          x:=DASHX+1+5*8;
        end;
      I_TAKE:
        begin
          write(@PLOTDEV,'TAKE?');
          x:=DASHX+1+5*8;
        end;
      I_NAME:
        begin
          write(@PLOTDEV,'NAME?');
          x:=DASHX+1+5*8;
        end
    end;
  end;

  proc editinput;
  var c: char;
      i: integer;

    proc redraw;
    var j: integer;
    begin
      { clear complete input line }
      _move(DASHX+1,y);
      write(@PLOTDEV,'           ');

      { redraw prompt }
      prompt;

      { redraw input and cursor }
      _move(x,y);
      for j:=0 to len-1 do
        write(@PLOTDEV,s[j]);
      write(@PLOTDEV,'_');
    end;

    func readandblink(x0,y0: integer): char;
    const BLINKTIME = 16;
    var dummy,count: integer;
        ch: char;
        cursoron: boolean;
    begin
      dummy:=_syncscreen;
      count:=0;
      cursoron:=true;

      _move(x0,y0);
      write(@PLOTDEV,'_');

      repeat
        ch:=KEYPRESSED;

        if ch<>chr(0) then begin
          _move(x0,y0);
          write(@PLOTDEV,' ');
          readandblink:=ch;
          KEYPRESSED:=chr(0);
          exit;
        end;

        count:=count+1;
        _delay10msec(3);

        if count>=BLINKTIME then begin
          count:=0;
          _move(x0,y0);

          if cursoron then
            write(@PLOTDEV,' ')
          else
            write(@PLOTDEV,'_');

          cursoron:=not cursoron;
          dummy:=_syncscreen;
        end
      until false;
    end;

  begin
    len:=0;
    s[0]:=ENDMARK;

    if request=I_MOVE then
      maxlen:=5
    else
      maxlen:=4;       { enough for QUIT }

    redraw;

    repeat
      c:=readandblink(x+8*len,y);

      if c=BACKSPACE then begin
        if len>0 then begin
          len:=len-1;
          s[len]:=ENDMARK;
          redraw;
        end
      end

      else if c=TOGGLE then
        write(TOGGLE)

      else if c<>CR then begin
        if len<maxlen then begin
          s[len]:=c;
          len:=len+1;
          s[len]:=ENDMARK;
          redraw;
        end
      end

    until c=CR;

    { clear complete input line }
    _move(DASHX+1,y);
    write(@PLOTDEV,'           ');
  end;

begin { getinput }

  request:=request0;
  s:=_new;
  s[0]:=ENDMARK;

  if player=BLACK then
    y:=DASHBLACKY+INPUTOFF
  else
    y:=DASHWHITEY+INPUTOFF;

  repeat

    oldrequest:=request;
    valid:=false;
    p1:=-1;
    p2:=-1;

    editinput;

    writeln(@DEBUG,'COMMAND ',s);

    if _strcmp(s,'QUIT')=0 then
      quit;

    if _strcmp(s,'SAVE')=0 then begin
      request:=I_NAME;
      editinput;
      writeln(@DEBUG,'NAME ',s);
      savegame(s, player);
      message(27,'  ',player);
      { return to the original request }
      request:=oldrequest;
    end else begin;

      valid:=false;
      p1:=-1;
      p2:=-1;

      case request of

        I_PLACE,I_TAKE:
          begin
            if len=2 then begin
              p1:=findpos(packed(s[0],s[1]));

              if p1>=0 then
                valid:=true
                else
                message(2,packed(s[0],s[1]),player);
              end else
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
            message(1,'  ',player)
        end
      end;

    end;

  until valid;

  message(0,'  ',player);
  _release(s);
end;

proc drawstone(pos, player: integer);
{**********************************}
var x, y: integer;
begin
  x:=X0+(ord(low(label[pos]))-ord('1'))*SPACING;
  y:=Y0+(ord(high(label[pos]))-ord('A'))*SPACING;

  vector(x-1, y-5, x+1, y-5, WHITE);
  vector(x-1, y+5, x+1, y+5, WHITE);

  if player=WHITE then begin
    vector(x-3, y-4, x+3, y-4, WHITE);
    vector(x-3, y+4, x+3, y+4, WHITE);

    vector(x-4, y-3, x+4, y-3, WHITE);
    vector(x-4, y+3, x+4, y+3, WHITE);

    vector(x-5, y-2, x+5, y-2, WHITE);
    vector(x-5, y-1, x+5, y-1, WHITE);
    vector(x-5, y,   x+5, y,   WHITE);
    vector(x-5, y+1, x+5, y+1, WHITE);
    vector(x-5, y+2, x+5, y+2, WHITE)
  end else begin
    vector(x-3, y-4, x-2, y-4, WHITE);
    vector(x+2, y-4, x+3, y-4, WHITE);
    vector(x-3, y+4, x-2, y+4, WHITE);
    vector(x+2, y+4, x+3, y+4, WHITE);

    endpoints(x-4, y-3, x+4, y-3);
    endpoints(x-4, y+3, x+4, y+3);

    endpoints(x-5, y-2, x+5, y-2);
    endpoints(x-5, y-1, x+5, y-1);
    endpoints(x-5, y,   x+5, y);
    endpoints(x-5, y+1, x+5, y+1);
    endpoints(x-5, y+2, x+5, y+2);

    vector(x,   y-4, x,   y+4, BLACK);
    vector(x-4, y,   x+4, y,   BLACK)
  end;
end;

proc drawboard;
{*************}
var i,x1,y1,x2,y2: integer;

begin

  { three nested squares }
  for i:=0 to 2 do begin
    x1 := X0 + i*SPACING;
    y1 := Y0 + i*SPACING;
    x2 := X0 + (6-i)*SPACING;
    y2 := Y0 + (6-i)*SPACING;
    vector(x1,y1,x2,y1,WHITE);
    vector(x2,y1,x2,y2,WHITE);
    vector(x2,y2,x1,y2,WHITE);
    vector(x1,y2,x1,y1,WHITE);
  end;

  { connections between the squares }
  vector(X0+3*SPACING,Y0,
         X0+3*SPACING,Y0+2*SPACING,WHITE);
  vector(X0+3*SPACING,Y0+4*SPACING,
         X0+3*SPACING,Y0+6*SPACING,WHITE);
  vector(X0,Y0+3*SPACING,
         X0+2*SPACING,Y0+3*SPACING,WHITE);
  vector(X0+4*SPACING,Y0+3*SPACING,
         X0+6*SPACING,Y0+3*SPACING,WHITE);
end;

proc drawstones;
{**************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    if board[position]<>EMPTY then
      drawstone(position,board[position]);
end;

proc clearstone(stone, player: integer);
{*************************************}
var i, x, y: integer;
begin
  x:=X0+(ord(low(label[stone]))-ord('1'))*SPACING;
  y:=Y0+(ord(high(label[stone]))-ord('A'))*SPACING;
  for i:=0 to 10 do begin
    _move(x-5,y+i-5);
    _draw(x+5,y+i-5, BLACK);
  end;
  drawboard;
  drawstones;
end;

proc drawlabels;
{**************}
var i: integer;
    c: char;
begin
  { 1..7 below the board }
  for i:=0 to 6 do begin
    c:=chr(ord('1')+i);
    _move(X0+i*SPACING-5, 0);
    write(@PLOTDEV,c);
  end;

  { A..G left of the board }
  for i:=0 to 6 do begin
    c:=chr(ord('A')+i);
    _move(0, Y0+i*SPACING-4);
    write(@PLOTDEV,c);
  end;
end;

proc cleardashstone(stone, player: integer);
{******************************************}
var i, x, y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+STONEOFF
  else
    y:=DASHBLACKY+STONEOFF;
  x:=DASHX+8+stone*10;
  for i:=0 to 8 do begin
    _move(x-4,y+i-4);
    _draw(x+4,y+i-4, BLACK);
  end;
end;

proc dashstone(stone,player,color: integer);
{******************************************}
var x, y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+STONEOFF
  else
    y:=DASHBLACKY+STONEOFF;
  x:=DASHX+8+stone*10;

  vector(x-1, y-4, x+1, y-4, WHITE);
  vector(x-1, y+4, x+1, y+4, WHITE);

  if color=WHITE then begin
    vector(x-3, y-3, x+3, y-3, WHITE);
    vector(x-3, y+3, x+3, y+3, WHITE);

    vector(x-4, y-2, x+4, y-2, WHITE);
    vector(x-4, y-1, x+4, y-1, WHITE);
    vector(x-4, y,   x+4, y,   WHITE);
    vector(x-4, y+1, x+4, y+1, WHITE);
    vector(x-4, y+2, x+4, y+2, WHITE)
  end else begin
    vector(x-3, y-3, x-2, y-3, WHITE);
    vector(x+2, y-3, x+3, y-3, WHITE);
    vector(x-3, y+3, x-2, y+3, WHITE);
    vector(x+2, y+3, x+3, y+3, WHITE);

    endpoints(x-4, y-2, x+4, y-2);
    endpoints(x-4, y-1, x+4, y-1);
    endpoints(x-4, y,   x+4, y);
    endpoints(x-4, y+1, x+4, y+1);
    endpoints(x-4, y+2, x+4, y+2);

    vector(x,   y-3, x,   y+3, BLACK);
    vector(x-3, y,   x+3, y,   BLACK)
  end;
end;
