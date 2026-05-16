{ tekgraph -                          }
{ display a table of real numbers     }
{ on attached Tektronix 4010 terminal }
{                                     }
{ the first 3   entries in the table  }
{ are fsize,  xmin and xmax           }
{                                     }
{   rricharz 2019                     }

program tekgraph;
uses syslib,ralib,mathlib,teklib;

const border=25;
      leftborder=140;

var f:file;
    i,size:integer;
    xs,xw,ys,yw,x,y:integer;
    min,max,nmax,v:real;
    xmin,xmax,xaxis,xsaxis:real;
    axis,daxis,daxis0:real;

begin

  write('Displaying values stored in TABLE:X');
  f:=_attach('TABLE:X         ',0,1,FREAD,
    0,0,'X');
  _getword(f,0,size);
  writeln;
  writeln('Points: ', size);
  _getreal(f,1,xmin);
  _getreal(f,2,xmax);

  min:=1.0e10;
  max:=-1.0e10;
  for i:=0 to size - 1 do begin
    _getreal(f,i+3,v);
    if v>max then max:=v;
    if v<min then min:=v;
  end;
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
    y:=trunc((axis-min)/(max-min)*conv(yw)+0.5);
    if (y>0) and (y<yw) then
      _drawvector(xs,ys+y,xs+xw,ys+y);
    _moveto(5,ys+y-5);
    if daxis<0.001 then
      write(@PLOTTER,axis:10:4)
    else if daxis<0.01 then
      write(@PLOTTER,axis:10:3)
    else if daxis<0.1 then
      write(@PLOTTER,axis:10:2)
    else
      write(@PLOTTER,axis:10:1);
    axis:=axis+daxis;
    until axis>max;

  repeat
    x:=trunc((xsaxis-xmin)/
                 (xmax-xmin)*conv(xw)+0.5);
    if (x>0) and (x<xw) then
      _drawvector(xs+x,ys,xs+x,ys+yw);
    _moveto(xs+x-80,6);
    if xaxis<0.001 then
      write(@PLOTTER,xsaxis:10:4)
    else if xaxis<0.01 then
      write(@PLOTTER,xsaxis:10:3)
    else if xaxis<0.1 then
      write(@PLOTTER,xsaxis:10:2)
    else
      write(@PLOTTER,xsaxis:10:1);
    xsaxis:=xsaxis+xaxis;
    until xsaxis>xmax;
  _setlinemode(SOLID);
  _setchsize(1);

  _getreal(f,3,v);
  y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
  _startdraw(xs,ys+y);
  for i:=1 to size-1 do begin
    _getreal(f,i+3,v);
    x:=trunc(conv(xw)/conv(size-1)*conv(i)+0.5);
    y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
    _draw(xs+x,ys+y);
  end;
  _enddraw;

  close(f);
  _moveto(1,MAXY-24);
  _endtek;

end.  