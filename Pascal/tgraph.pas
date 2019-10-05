{ tgraph -                            }
{ display a table of real numbers     }
{ on attached Tektronix 4010 terminal }
{                                     }
{ the first 3   entries in the table  }
{ are fsize,  xmin and xmax           }
{                                     }
{   rricharz 2019                     }

program tgraph;
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

  f:=attach('TABLE:X         ',0,1,fread,
    0,0,'X');
  getword(f,0,size);
  writeln;
  writeln('Elements: ', size);
  getreal(f,1,xmin);
  getreal(f,2,xmax);

  min:=1.0e10;
  max:=-1.0e10;
  for i:=0 to size - 1 do begin
    getreal(f,i+3,v);
    if v>max then max:=v;
    if v<min then min:=v;
  end;
  write('Ymin:   ');
  writefix(output,3,min);
  writeln;
  write('Ymax:   ');
  writefix(output,3,max);
  writeln;
  write('Xmin:   ');
  writefix(output,3,xmin);
  writeln;
  write('Xmax:   ');
  writefix(output,3,xmax);
  writeln;

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

  starttek;
  xs:=leftborder;
  xw:=maxx-leftborder-border;
  ys:=border;
  yw:=maxy-2*border;

  drawrectange(xs,ys,xs+xw,ys+yw);

  setlinemode(dotted);
  setchsize(2);
  repeat
    y:=trunc((axis-min)/(max-min)*conv(yw)+0.5);
    if (y>0) and (y<yw) then
      drawvector(xs,ys+y,xs+xw,ys+y);
    moveto(5,ys+y-5);
    if daxis<0.001 then
      writefix(plotter,4,axis)
    else if daxis<0.01 then
      writefix(plotter,3,axis)
    else if daxis<0.1 then
      writefix(plotter,2,axis)
    else
      writefix(plotter,1,axis);
    axis:=axis+daxis;
    until axis>max;

  repeat
    x:=trunc((xsaxis-xmin)/
                 (xmax-xmin)*conv(xw)+0.5);
    if (x>0) and (x<xw) then
      drawvector(xs+x,ys,xs+x,ys+yw);
    moveto(xs+x-80,6);
    if xaxis<0.001 then
      writef0(plotter,4,xsaxis,12,true)
    else if xaxis<0.01 then
      writef0(plotter,3,xsaxis,12,true)
    else if xaxis<0.1 then
      writef0(plotter,2,xsaxis,12,true)
    else
      writef0(plotter,1,xsaxis,12,true);
    xsaxis:=xsaxis+xaxis;
    until xsaxis>xmax;
  setlinemode(solid);
  setchsize(1);

  getreal(f,3,v);
  y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
  startdraw(xs,ys+y);
  for i:=1 to size-1 do begin
    getreal(f,i+3,v);
    x:=trunc(conv(xw)/conv(size-1)*conv(i)+0.5);
    y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
    draw(xs+x,ys+y);
  end;
  enddraw;

  close(f);
  moveto(1,maxy-24);
  endtek;

end.  