{ tekgraph -                          }
{ display a table of real numbers     }
{ on attached Tektronix 4010 terminal }
{                                     }

program tekgraph;
uses syslib,ralib,mathlib,teklib,writelib,strlib,ftlib
;

const border = 50;
      leftborder = 120;

      LEFT = 0;     { to justify in _plotstr }
      CENTER = 1;
      RIGHT = 2;

var f:file;
    i,size:integer;
    xs,xw,ys,yw,x,y:integer;
    min,max,nmax,v:real;
    xmin,xmax,xaxis,xsaxis:real;
    axis,daxis,daxis0:real;
    labelstr : cpnt;

proc _plotstr(s: cpnt; x, y: integer;
                              justify: integer);
{**********************************************}
const
  CHARWIDTH = 12.642;   { _setchsize(2) }
  XOFFSET   = 2.0;
  YOFFSET   = -4.0;
var
  xpos: real;
  width: real;
begin
  width := conv(_strlen(s)) * CHARWIDTH;

  xpos := conv(x);

  case justify of
    CENTER: xpos := xpos - width/2.0;
    RIGHT:  xpos := xpos - width
  end;

  _moveto(trunc(xpos + XOFFSET + 0.5),
          trunc(conv(y) + YOFFSET + 0.5));
  write(@PLOTTER,s);
end;

begin
  labelstr := _new;

  writeln('Displaying values stored in FUNCDATA:X');
  f:=_attach('FUNCDATA:X      ', 0, 1,
    FREAD + FSILENT, 0, 0, 'X');
  if _getsize <> DATAFILESIZE + 256 then
    _abortwith('Wrong data file size');
  _getdataheader(f);

  size := _n;
  xmin := _min;
  xmax := _max;

  min := -0.6;
  max := 0.6;

  writeln('N:      ',size);
  writeln('Ymin:   ',min);
  writeln('Ymax:   ',max);
  writeln('Xmin:   ',xmin);
  writeln('Xmax:   ',xmax);

  daxis0:=(max-min)/2.;
  daxis:=1.;
  while daxis>daxis0 do
    daxis:=daxis*0.1;
  while daxis<0.1*daxis0 do
    daxis:=daxis*10.;

  if ((min/daxis)<=32767.) and
    ((min/daxis)>=-32768.) then
    axis:=daxis*conv(trunc(min/daxis))
  else
    axis:=min;
  min:=axis;
  if ((max/daxis)<=32767.) and
    ((max/daxis)>=-32768.) then begin
    nmax:=daxis*conv(trunc(max/daxis));
    if nmax<max then nmax:=nmax+daxis;
    max:=nmax;
  end;

  daxis0:=(xmax-xmin)/2.;
  xaxis:=1.;
  while xaxis>daxis0 do
    xaxis:=xaxis*0.1;
  while xaxis<0.1*daxis0 do
    xaxis:=xaxis*10.;

  if ((xmin/xaxis)<=32767.) and
    ((xmin/xaxis)>=-32768.) then
    xsaxis:=xaxis*conv(trunc(xmin/xaxis))
  else
    xsaxis:=xmin;
  if xsaxis<xmin then xsaxis:=xsaxis+xaxis;

  _starttek(T_HALF);
  xs:=leftborder;
  xw:=MAXX-leftborder-border;
  ys:=border;
  yw:=MAXY-2*border;

  _drawrectangle(xs,ys,xs+xw,ys+yw);

  _setlinemode(DOTTED);
  _setchsize(2);
  repeat
    labelstr[0] := chr(0);
    y:=trunc((axis-min)/(max-min)*conv(yw)+0.5);
    if (y>0) and (y<yw) then
      _drawvector(xs,ys+y,xs+xw,ys+y);
    _moveto(5,ys+y-5);
    if daxis<0.001 then
      write(@labelstr,axis:1:4)
    else if daxis<0.01 then
      write(@labelstr,axis:1:3)
    else if daxis<0.1 then
      write(@labelstr,axis:1:2)
    else
      write(@labelstr,axis:1:1);
    _plotstr(labelstr,xs,
      ys + y, RIGHT);
    axis:=axis+daxis;
  until axis>max;

  repeat
    labelstr[0] := chr(0);
    x:=trunc((xsaxis-xmin)/
                 (xmax-xmin)*conv(xw)+0.5);
    if (x>0) and (x<xw) then
      _drawvector(xs+x,ys,xs+x,ys+yw);
    if xaxis<0.001 then
      write(@labelstr,xsaxis:1:4)
    else if xaxis<0.01 then
      write(@labelstr,xsaxis:1:3)
    else if xaxis<0.1 then
      write(@labelstr,xsaxis:1:2)
    else
      write(@labelstr,xsaxis:1:1);
    _plotstr(labelstr,xs + x,
      ys - trunc(0.6 * conv(border)), CENTER);
    xsaxis:=xsaxis+xaxis;
  until xsaxis>xmax;

  _setlinemode(SOLID);
  _setchsize(1);

  _getreal(f,REALBASE,v);
  y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
  _startdraw(xs,ys+y);
  for i:=1 to size-1 do begin
    _getreal(f,REALBASE+i,v);
    x:=trunc(conv(xw)/conv(size)*conv(i)+0.5);
    y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
    _draw(xs+x,ys+y);
  end;
  _enddraw;

  close(f);
  _moveto(1,MAXY-24);
  _endtek;

end.  