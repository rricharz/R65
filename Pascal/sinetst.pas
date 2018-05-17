{ sinetest.pas }

program sinetst;
uses syslib,mathlib,plotlib;

var a,b: real;
    i,x,y: integer;
    ch: char;

begin
  grinit;
  cleargr;
  move(0,ysize div 2);
  draw(xsize,ysize div 2,white);
  for x:=0 to xsize do begin
    a:=conv(x)*360.0/conv(xsize);
    b:=sin(a);
    y:=trunc(b*conv(ysize)/2.1)+(ysize div 2);
    plot(x,y,white);
  end;
  for x:=0 to xsize do begin
    a:=conv(x)*360.0/conv(xsize);
    b:=cos(a);
    y:=trunc(b*conv(ysize)/2.1)+(ysize div 2);
    plot(x,y,white);
  end;
  read(@key,ch);
  grend;

  writeln(' angle',tab8,'  sin',tab8,'  cos');
  for i:=1 to 24 do begin
    a:=conv(i*15);
    writefix(@0,0,a);
    write(tab8);
    writefix(@0,3,sin(a));
    write(tab8);
    writefix(@0,3,cos(a));
    writeln;
  end;
end.
 