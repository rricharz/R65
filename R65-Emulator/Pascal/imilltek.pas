{ IMILLTEK: include file for TEKMILL }

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

    I_PLACE  = 1;
    I_MOVE   = 2;
    I_TAKE   = 3;
    I_NAME   = 4;

proc init_graphics;
begin
  _starttek;
end;

proc init_canvas;
begin
  _clearscreen;
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
  _abort;
end;

proc drawstone(pos,player: integer);
begin
end;

proc drawboard;
begin
end;

proc drawstones;
begin
end;

proc clearstone(stone,player: integer);
begin
end;

proc drawlabels;
begin
end;

proc cleardashstone(stone,player: integer);
begin
end;

proc dashstone(stone,player,color: integer);
begin
end; 