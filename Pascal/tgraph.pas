{ tgraph -                            }
{ display a table of real numbers     }
{ on attached Tektronix 4010 terminal }
{                                     }
{   rricharz 2019 to test ralib       }

program tgraph;
uses syslib,ralib,mathlib,teklib;

var f:file;
    i,size:integer;
    xs,xw,ys,yw,x,y:integer;
    min,max,v:real;

begin

  f:=attach('TABLE:X         ',0,1,fread,
    0,0,'X');
  size:=getsize div 4;
  writeln;
  writeln('Elements: ', size);

  min:=1.0e10;
  max:=-1.0e10;
  for i:=0 to size - 1 do begin
    getreal(f,i,v);
    if v>max then max:=v;
    if v<min then min:=v;
  end;
  write('Min: ');
  writefix(output,2,min);
  writeln;
  write('Max: ');
  writefix(output,2,max);
  writeln;

  starttek;
  xs:=2;
  xw:=maxx-4;
  ys:=2;
  yw:=maxy-4;

  startdraw(xs-1,ys-1);
  draw(xs+xw+1,ys-1);
  draw(xs+xw+1,ys+yw+1);
  draw(xs-1,ys+yw+1);
  draw(xs-1,ys-1);
  enddraw;

  getreal(f,0,v);
  y:=trunc((v-min)/(max-min)*conv(yw));
  startdraw(xs,ys+y);
  for i:=1 to size-1 do begin
    getreal(f,i,v);
    x:=trunc(conv(xw)/conv(size-1)*conv(i));
    y:=trunc((v-min)/(max-min)*conv(yw));
    draw(xs+x,ys+y);
  end;
  enddraw;

  close(f);
  endtek;

end.  