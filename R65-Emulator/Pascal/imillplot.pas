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
var  y: integer;
begin
  debug('message',player,number,field);
  if player=WHITE then
    y := DASHWHITEY
  else
    y := DASHBLACKY;

  _move(DASHX+1, y+MSGOFF);
  write(@PLOTDEV,'           '); { 11 blanks }

  _move(DASHX+1, y+MSGOFF);
  case number of
    0: begin end;
    1: write(@PLOTDEV,'BAD INPUT');
    2: write(@PLOTDEV,field,' INVALID');
    3: write(@PLOTDEV,field,' EMPTY');
    4: write(@PLOTDEV,field,' WHITE');
    5: write(@PLOTDEV,field,' BLACK');
    6: write(@PLOTDEV,field,' OCCUPIED');
    7: write(@PLOTDEV,'BAD MOVE');
    8: write(@PLOTDEV,field,' IS MILL');
    9: write(@PLOTDEV,'REMOVE ONE');
   10: write(@PLOTDEV,'GAME OVER');
   20: write(@PLOTDEV,'YOUR MOVE');
   21: write(@PLOTDEV,'COMPUTING');
   22: write(@PLOTDEV,'WAITING');
   23: write(@PLOTDEV,'THINKING');
   24: write(@PLOTDEV,'WINS');
   25: write(@PLOTDEV,'DRAW');
   26: write(@PLOTDEV,'READY')
   else write(@PLOTDEV,'ERROR ', number)
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

proc getinput(player: integer; var p1,p2: integer;
              var ismove: boolean);
{************************************************}

const TOGGLE    = chr(12);
      BACKSPACE = chr(127);

var s: cpnt;
    y, len, res: integer;
    valid: boolean;

  proc editinput;
  var c: char;
      i: integer;

    proc redraw;
    var j: integer;
    begin
      _move(DASHX+1,y);
      write(@PLOTDEV,'      ');
      _move(DASHX+1,y);
      for j:=0 to len-1 do
        write(@PLOTDEV,s[j]);
      write(@PLOTDEV,'_');
    end;

    func readandblink(x,y: integer): char;
    const BLINKTIME = 16;
    var dummy,count: integer;
        ch: char;
        cursoron: boolean;
    begin
      dummy := _syncscreen;
      count := 0;
      cursoron := true;
      _move(x,y);
      write(@PLOTDEV,'_');
      repeat
        ch := KEYPRESSED;
        if ch<>chr(0) then begin
          { remove cursor before returning }
          _move(x,y);
          write(@PLOTDEV,' ');
          readandblink := ch;
          KEYPRESSED := chr(0);
          exit;
        end;
        count := count+1;
        _delay10msec(3);
        if count>=BLINKTIME then begin
          count := 0;
          _move(x,y);
          if cursoron then
            write(@PLOTDEV,' ')
          else
            write(@PLOTDEV,'_');
          cursoron := not cursoron;
          dummy := _syncscreen;
        end;
      until false;
    end;

  begin
    len := 0;
    for i:=0 to 4 do s[i] := ' ';

    redraw;

    repeat
      c := readandblink(DASHX+1+8*len,y);

      if c=BACKSPACE then begin
        if len>0 then begin
          len:=len-1;
          s[len]:=' ';
          redraw;
        end
      end

      else if c=TOGGLE then begin
        write(TOGGLE);
      end

      else if c<>CR then begin
        if len<5 then begin
          s[len]:=c;
          len:=len+1;
          redraw;
        end
      end
    until c=CR;

    { remove cursor }
    _move(DASHX+1,y);
    write(@PLOTDEV,'      ');
    s[len] := ENDMARK;
  end;

begin { getinput }
  s := _new;
  s[0] := ENDMARK;

  if player=BLACK then
    y := DASHBLACKY + INPUTOFF
  else
    y := DASHWHITEY + INPUTOFF;

  repeat
    editinput;

    if _strcmp(s,'QUIT')=0 then
      _abort;

    valid := false;
    ismove := false;
    p1 := -1;
    p2 := -1;

    if len=2 then begin
      p1 := findpos(packed(s[0],s[1]));
      if p1>=0 then
        valid := true
      else
        message(2,packed(s[0],s[1]),player);
    end

    else if (len=5) and (s[2]='-') then begin
      p1 := findpos(packed(s[0],s[1]));
      if p1<0 then
        message(2,packed(s[0],s[1]),player)
      else begin
        p2 := findpos(packed(s[3],s[4]));
        if p2<0 then
          message(2,packed(s[3],s[4]),player)
        else begin
          ismove := true;
          valid := true;
        end;
      end;
    end

    else
      message(1,packed(' ',' '),player);

  until valid;

  message(0,packed(' ',' '),player);
  _release(s);
end;

proc drawstone(x,y,player: integer);
{**********************************}
begin
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

proc dashstone(x,y,player: integer);
{**********************************}
begin
  vector(x-1, y-4, x+1, y-4, WHITE);
  vector(x-1, y+4, x+1, y+4, WHITE);

  if player=WHITE then begin
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
