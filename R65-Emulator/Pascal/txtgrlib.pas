library txtgrlib;

const
  CYAN = 0;
  YELLOW = 1;

proc _txtgraph(x,y,bits,color);
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

    code := bits and $0f;
    c := mem[vidpnt];

    if (c and $7f)<$20 then
      code := code or (c and $0f);

    if color=YELLOW then
      code := code or $80;

    mem[vidpnt] := code;

    curlin := scurlin;
    curpos := scurpos;
  end;
end;

proc _htxtgraph(xmin,xmax,y,color);
var
  i: integer;
begin
  for i:=xmin to xmax do begin
    if i=xmin then
      _txtgraph(i,y,$02,color)
    else if i=xmax then
      _txtgraph(i,y,$08,color)
    else
      _txtgraph(i,y,$0a,color);
  end;
end;

proc _vtxtgraph(x,ymin,ymax,color);
var
  i: integer;
begin
  for i:=ymin to ymax do begin
    if i=ymin then
      _txtgraph(x,i,$04,color)
    else if i=ymax then
      _txtgraph(x,i,$01,color)
    else
      _txtgraph(x,i,$05,color);
  end;
end;

proc _recttxtgraph(xmin,xmax,ymin,ymax,color);
begin
  _htxtgraph(xmin,xmax,ymin,color);
  _htxtgraph(xmin,xmax,ymax,color);
  _vtxtgraph(xmin,ymin,ymax,color);
  _vtxtgraph(xmax,ymin,ymax,color);
end;

begin
end.