{ graph -                            }
{ display a table of real numbers    }
{                                    }
{   rricharz 2019 to test ralib      }

program graph;
uses syslib,ralib,mathlib,plotlib;

var f:file;
    i,size:integer;
    xs,xw,ys,yw,x,y:integer;
    min,max,v:real;

begin

  dalpha;

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
  writeln('Use ctrl-l to toggle ',
    'alpha and graphics display');

  delay10mses(200);

  dgraphics;
  cleargr;
  xs:=2;
  xw:=xsize-4;
  ys:=2;
  yw:=ysize-4;

  move(xs-1,ys-1);
  draw(xs+xw+1,ys-1,white);
  draw(xs+xw+1,ys+yw+1,white);
  draw(xs-1,ys+yw+1,white);
  draw(xs-1,ys-1,white);

  getreal(f,0,v);
  y:=trunc((v-min)/(max-min)*conv(yw));
  move(xs,ys+y);
  for i:=1 to size-1 do begin
    getreal(f,i,v);
    x:=trunc(conv(xw)/conv(size-1)*conv(i));
    y:=trunc((v-min)/(max-min)*conv(yw));
    draw(xs+x,ys+y,white);
  end;
  delay10msec(200);

  close(f);
  dalpha;

end.  