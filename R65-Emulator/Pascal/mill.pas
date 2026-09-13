program mill;

uses plotlib, syslib, strlib;

const
  NPOSITIONS   = 24;
  NSTONES      = 9;
  NMILLS       = 16;
  MAXNEIGHBORS = 4;

  EMPTY = 4;

var
  board: array[23] of integer;
  stones: array[BLACK] of integer;
  DEBUG: file;

{ section for MILL on onbard screen }
{ ##################################}

const
    SPACING = 16;
    X0 = 15;
    Y0 = 15;
    DASHX      = 125;

    WHITEDASHY = 63;
    BLACKDASHY = 15;
    DASHWIDTH  = 95;
    DASHHEIGHT = 48;

proc init_canvas;
{***************}
begin
  DEBUG := PRINTER;
  _grinit;
  _splitview;
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

proc drawreserve;
{****************}
var stone,x,y: integer;
begin

  y:=82;
  for stone:=0 to stones[WHITE]-1 do begin
    x:=121+stone*11;
    drawstone(x,y,WHITE);
  end;

  y:=22;
  for stone:=0 to stones[BLACK]-1 do begin
    x:=121+stone*12;
    drawstone(x,y,BLACK);
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

proc debugdash(y,player: integer);
{********************************}
var stone,x0,y0: integer;
begin
  _move(DASHX+1,y+37);

  if player=WHITE then
    write(@PLOTDEV,'Player')
  else
    write(@PLOTDEV,'Computer');

  y0:=y+29;
  for stone:=0 to stones[player]-1 do begin
    x0:=DASHX+8+stone*10;
    dashstone(x0,y0,player);
  end;

  _move(DASHX+1,y+13);
  write(@PLOTDEV,'Move:');

  _move(DASHX+1,y+3);
  write(@PLOTDEV,'Occupied---');

  if player=WHITE then
    _rectangle(DASHX,y,DASHWIDTH,DASHHEIGHT,WHITE);
end;

{ common section for MILL and TEKMILL }
{#####################################}

const
  LABELS =
  'A1A4A7D7G7G4G1D1B2B4B6D6F6F4F2D2C3C4C5D5E5E4E3D3';

var
  label:    array[23] of packed char;
  mills:    array[47] of integer;
  neighbor: array[95] of integer;
  { There is no INVERSE stone; BLACK and WHITE used }

proc setmill(mill,p1,p2,p3: integer);
{***********************************}
var millbase: integer;
begin
  millbase:=mill*3;
  mills[millbase]:=p1;
  mills[millbase+1]:=p2;
  mills[millbase+2]:=p3;
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

proc init_common;
{***************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    board[position]:=EMPTY;

  stones[WHITE]:=NSTONES;
  stones[BLACK]:=NSTONES;

  for position:=0 to NPOSITIONS-1 do
    label[position]:=
      packed(LABELS[2*position],LABELS[2*position+1]);

  { initialize mills }

  { outer square }
  setmill(0,
    findpos('A1'),findpos('A4'),findpos('A7'));
  setmill(1,
    findpos('A7'),findpos('D7'),findpos('G7'));
  setmill(2,
    findpos('G7'),findpos('G4'),findpos('G1'));
  setmill(3,
    findpos('G1'),findpos('D1'),findpos('A1'));

  { middle square }
  setmill(4,
    findpos('B2'),findpos('B4'),findpos('B6'));
  setmill(5,
    findpos('B6'),findpos('D6'),findpos('F6'));
  setmill(6,
    findpos('F6'),findpos('F4'),findpos('F2'));
  setmill(7,
    findpos('F2'),findpos('D2'),findpos('B2'));

  { inner square }
  setmill(8,
    findpos('C3'),findpos('C4'),findpos('C5'));
  setmill(9,
    findpos('C5'),findpos('D5'),findpos('E5'));
  setmill(10,
    findpos('E5'),findpos('E4'),findpos('E3'));
  setmill(11,
    findpos('E3'),findpos('D3'),findpos('C3'));

  { connections between the squares }
  setmill(12,
    findpos('A4'),findpos('B4'),findpos('C4'));
  setmill(13,
    findpos('D7'),findpos('D6'),findpos('D5'));
  setmill(14,
    findpos('G4'),findpos('F4'),findpos('E4'));
  setmill(15,
    findpos('D1'),findpos('D2'),findpos('D3'));

  { initialize neighbor }
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
var position,x,y: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    if board[position]<>EMPTY then begin
      x:=X0+
        (ord(low(label[position]))-ord('1'))*SPACING;
      y:=Y0+
        (ord(high(label[position]))-ord('A'))*SPACING
;
      drawstone(x,y,board[position]);
    end;
end;

proc debuglabels;
{****************}
var position,neighbornumber,neighborbase: integer;
    nextposition: integer;
begin
  writeln(@DEBUG);
  writeln(@DEBUG,'Board positions and neighbors');
  writeln(@DEBUG);

  for position:=0 to NPOSITIONS-1 do begin
    write(@DEBUG, label[position], ': ');

    neighborbase:=position*MAXNEIGHBORS;

    for neighbornumber:=0 to MAXNEIGHBORS-1 do begin
      nextposition:=
        neighbor[neighborbase+neighbornumber];

      if nextposition>=0 then
        write(@DEBUG, label[nextposition], ' ');
    end;

    writeln(@DEBUG);
  end;
end;

proc removeneighbor(position1,position2: integer);
{***********************************************}
var neighbornumber,neighborbase: integer;
begin
  neighborbase:=position1*MAXNEIGHBORS;

  for neighbornumber:=0 to MAXNEIGHBORS-1 do
    if neighbor[neighborbase+neighbornumber]
       =position2 then
      neighbor[neighborbase+neighbornumber]:=-1;
end;

proc initneighbors;
{******************}
var position,neighborbase: integer;
    x,y: char;
    p: integer;
begin
  for position:=0 to NPOSITIONS-1 do begin

    neighborbase:=position*MAXNEIGHBORS;

    neighbor[neighborbase]:=-1;
    neighbor[neighborbase+1]:=-1;
    neighbor[neighborbase+2]:=-1;
    neighbor[neighborbase+3]:=-1;

    { up }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (y<'G') and (p<0) do begin
      y:=chr(ord(y)+1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase]:=p;

    { right }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (x<'7') and (p<0) do begin
      x:=chr(ord(x)+1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+1]:=p;

    { down }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (y>'A') and (p<0) do begin
      y:=chr(ord(y)-1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+2]:=p;

    { left }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (x>'1') and (p<0) do begin
      x:=chr(ord(x)-1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+3]:=p;

    { no cross in the center }
    removeneighbor(findpos('D3'),findpos('D5'));
    removeneighbor(findpos('D5'),findpos('D3'));
    removeneighbor(findpos('C4'),findpos('E4'));
    removeneighbor(findpos('E4'),findpos('C4'));

  end;
end;

func ismill(position,player: integer): boolean;
{****************************************}
var mill,millbase,i,p: integer;
    found: boolean;
begin
  for mill:=0 to NMILLS-1 do begin
    millbase:=mill*3;

    { is this position in the current mill? }
    if (mills[millbase]=position) or
       (mills[millbase+1]=position) or
       (mills[millbase+2]=position) then begin
      found:=true;
      for i:=0 to 2 do begin
        p:=mills[millbase+i];
        if board[p]<>player then found:=false;
      end;
      if found then begin
        ismill:=true;
       exit;
       end;
    end;
  end;
  ismill:=false;
end;

begin {main}
  init_canvas;
  init_common;
  initneighbors;

  { set a few stones for debugging }
  board[findpos('A1')]:=WHITE;
  board[findpos('A7')]:=WHITE;
  board[findpos('D5')]:=WHITE;
  board[findpos('D6')]:=WHITE;
  board[findpos('D7')]:=WHITE;
  board[findpos('G7')]:=BLACK;
  board[findpos('G1')]:=BLACK;

  writeln(@DEBUG,
    '----------------------------------------------');
  writeln(@DEBUG, 'MILL initialized');

  drawboard;
  drawlabels;
  drawstones;
  { drawreserve; }

  debuglabels;
  debugdash(WHITEDASHY,WHITE);
  debugdash(BLACKDASHY,BLACK);

end.
