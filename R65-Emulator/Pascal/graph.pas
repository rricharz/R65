{ graph -                            }
{ display a table of real numbers    }
{ the first 3 values in the table    }
{ are fsize, xmin and xmax           }
{                                    }
{   rricharz 2019                    }

program graph;
uses syslib,ralib,mathlib,plotlib;

var f:file;
    i,size:integer;
    xs,xw,ys,yw,x,y:integer;
    min,max,v:real;

begin

  f:=_attach('TABLE:X         ',0,1,FREAD,
    0,0,'X');
  _getword(f,0,size);
  writeln;
  writeln('Elements: ', size);

  min:=1.0e10;
  max:=-1.0e10;
  for i:=0 to size - 1 do begin
    _getreal(f,i+3,v);
    if v>max then max:=v;
    if v<min then min:=v;
  end;
  write('Min: ');
  writefix(OUTPUT,2,min);
  writeln;
  write('Max: ');
  writefix(OUTPUT,2,max);
  writeln;
  _grinit;
  _cleargr;
  _splitview;
  xs:=1;
  xw:=XSIZE-1;
  ys:=1;
  yw:=YSIZE-1;
  _getreal(f,3,v);
  y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
  _move(xs,ys+y);
  for i:=1 to size-1 do begin
    _getreal(f,i+3,v);
    x:=trunc(conv(xw)/conv(size-1)*conv(i)+0.5);
    y:=trunc((v-min)/(max-min)*conv(yw)+0.5);
    _draw(xs+x,ys+y,WHITE);
  end;
  close(f);
end.