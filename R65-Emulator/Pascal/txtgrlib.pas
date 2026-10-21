library txtgrlib;

const
  CYAN = 0;
  YELLOW = 1;

proc _txtgr(x,y,bits,color);
const
  C_CURLOC = $e294;
  MAXX = 47;
  MAXY = 15;
mem
  vidpnt = $00e9: integer;
  curlin = $00ed: integer&;
  curpos = $00ee: integer&;
var
  scurlin,scurpos,c,code: integer;
begin
  if (x>=0) and (x<=MAXX) and
     (y>=0) and (y<=MAXY) then begin

    scurlin := curlin;
    scurpos := curpos;

    curlin := y;
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

begin
end.