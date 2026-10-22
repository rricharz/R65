library txtgrlib;

{ TXTGRLIB - Text graphics library for R65.
  Draws horizontal and vertical lines and rectangles
  on the 48x16 character screen using special graphics
  characters. Lines are automatically joined at
  intersections. Supports cyan and yellow colors. }

const
  CYAN = 0;
  YELLOW = 1;

  TGR_UP    = $01;
  TGR_RIGHT = $02;
  TGR_DOWN  = $04;
  TGR_LEFT  = $08;

proc _txtgr(x,y,bits,color);
const
  C_CURLOC = $e294;
  MAXY = 15;
mem
  vidpnt = $00e9: integer;
  curlin = $00ed: integer&;
  curpos = $00ee: integer&;
  offset = $1782: integer&;
  numchr = $178a: integer&;
var
  scurlin,scurpos,c,code: integer;
begin
  if (x>=0) and (x<=numchr) and
     (y>=0) and (y<=MAXY) then begin

    scurlin := curlin;
    scurpos := curpos;

    curlin := offset+y;
    curpos := x;
    call(C_CURLOC);

    code := bits and $7f;

    if code<$10 then begin
      { combine line graphics }
      c := mem[vidpnt];
      if (c and $7f)<$10 then
        code := code or (c and $0f);
    end;

    if color=YELLOW then
      code := code or $80;

    mem[vidpnt] := code;

    curlin := scurlin;
    curpos := scurpos;
  end;
end;

proc _htxtgr(xmin,xmax,y,color);
var
  i: integer;
begin
  for i:=xmin to xmax do begin
    if i=xmin then
      _txtgr(i,y,$02,color)
    else if i=xmax then
      _txtgr(i,y,$08,color)
    else
      _txtgr(i,y,$0a,color);
  end;
end;

proc _vtxtgr(x,ymin,ymax,color);
var
  i: integer;
begin
  for i:=ymin to ymax do begin
    if i=ymin then
      _txtgr(x,i,$04,color)
    else if i=ymax then
      _txtgr(x,i,$01,color)
    else
      _txtgr(x,i,$05,color);
  end;
end;

proc _recttxtgr(xmin,xmax,ymin,ymax,color);
begin
  _htxtgr(xmin,xmax,ymin,color);
  _htxtgr(xmin,xmax,ymax,color);
  _vtxtgr(xmin,ymin,ymax,color);
  _vtxtgr(xmax,ymin,ymax,color);
end;

proc _writetxtgr(bits:integer);
{***************************}
const
  C_CURLOC = $e294;
  C_PRTADV = $e4fb;
mem
  vidpnt = $00e9: integer;
  vflag = $1781: integer&;
var
  code:integer;
begin
  code:=bits and $7f;
  if (vflag and $80)<>0 then
    code:=code or $80;
  call(C_CURLOC);
  mem[vidpnt]:=code;
  call(C_PRTADV);
end;

proc _setcursor(x,y:integer);
{***************************}
const
  C_SETCUR = $e2e2;
mem
  curlin = $00ed: integer&;
  curpos = $00ee: integer&;
  numchr = $178a: integer&;
  offset = $1782: integer&;
begin
  if (x>=0) and (x<=numchr) and
     (y>=0) and (y<16) then begin
    curpos:=x;
    curlin:=offset+y;
    call(C_SETCUR);
  end;
end;

begin
end.