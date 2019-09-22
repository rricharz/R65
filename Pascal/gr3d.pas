{ TEK3D:P R65 tiny Pascal math demo
  rricharz 2019 }

program gr3d;
uses syslib,mathlib,plotlib;

var mask:array[xsize] of integer;
    i:integer;
    x1,y1,x2,y2:real;
    x,y,step,max,scale:real;
    sx,sy,dx,dy:real;

func f1(x,y:real):real;
begin
  f1:=sin(2.0*x+y);
end;

func f2(x,y:real):real;
var r:real;
begin
  r:=sqrt(x * x + y * y);
  if r=0.0 then f2:= 1.0
  else f2:=sin(r)/r;
end;

proc drawvec(x1,y1,x2,y2);
{ draw vector, do not leave graphics mode }
{ to avoid cursor showing up }
begin
  move(x1,y1);
  draw(x2,y2,white);
end;

proc drawmasked(x1,y1,x2,y2:integer;
                visible:boolean);
var i,start,vstart:integer;
    dodraw:boolean;
    step,v:real;
begin
  if x2 = x1 then step:=conv(y2-y1)
  else begin
    step:=conv(y2-y1)/conv(x2-x1);
    if (x2-x1)<0 then step:=-step
  end;

  dodraw:=false;
  v:=conv(y1);
  start:=x1;
  vstart:=y1;

  for i:=x1 to x2-1 do begin
    if trunc(v)<=mask[i] then begin
      { hidden point }
      if dodraw then begin
        { draw up to here }
        if ((i-x1)>1) and visible then
          drawvec(start,vstart,i,trunc(v));
      end;
      dodraw:=false;
    end
    else begin
      { visible point }
      mask[i]:=trunc(v);
      if not dodraw then begin
        { draw from here }
        start:=i;
        vstart:=trunc(v);
      end;
      dodraw:=true;
    end;
    v:=v+step;
  end;

  for i:=x1 downto x2+1 do begin
    if trunc(v)<=mask[i] then begin
      { hidden point }
      if dodraw then begin
        { draw up to here }
        if ((x1-i)>1) and visible then
          drawvec(start,vstart,i,trunc(v));
      end;
      dodraw:=false;
    end
    else begin
      { visible point }
      mask[i]:=trunc(v);
      if not dodraw then begin
        { draw from here }
        start:=i;
        vstart:=trunc(v);
      end;
      dodraw:=true;
    end;
    v:=v+step;
  end;

  if dodraw and visible {and (x2<>start)} then
    drawvec(start,vstart,x2,y2);
  if y2<mask[x2] then
    mask[x2]:=y2;
end;

begin
  sx:=conv(xsize)/2.0;
  sy:=conv(ysize)/8.0;
  dx:=6.0;
  dy:=3.0;

  grinit; cleargr;

{*******************************************}

  step:=20.0;
  max:=360.0;
  scale:=5.0;

  dx:=conv(xsize)/(2.2*max);
  dy:=dx/2.0;

  for i:=0 to xsize do mask[i]:=0;

  { Generate a first mask }
  x:=0.0;
  y:=0.0;
  x1:=dx*x-dx*y;
  y1:=dy*x+dy*y+f1(x,y)*scale;
  x:=0.0;
  while x<max do begin
    x2:=dx*x-dx*y;
    y2:=dy*x+dy*y+f1(x,y)*scale;
    drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
      trunc(x2+sx),trunc(y2+sy)-1,false);
    x1:=x2;
    y1:=y2;
    x:=x+step;
  end;

  x:=0.0;
  while x<(max+step) do begin
    y:=0.0;
    x1:=dx*x-dx*y;
    y1:=dy*x+dy*y+f1(x,y)*scale;
    y:=0.0;
    while y<max do begin
      y:=y+step;
      x2:=dx*x-dx*y;
      y2:=dy*x+dy*y+f1(x,y)*scale;
      drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
        trunc(x2+sx),trunc(y2+sy)-1,true);
      x1:=x2;
      y1:=y2;
    end;
    x:=x+step;
  end;

  for i:=0 to xsize do mask[i]:=0;

    { Generate a first mask }
  x:=0.0;
  y:=0.0;
  x1:=dx*x-dx*y;
  y1:=dy*x+dy*y+f1(x,y)*scale;
  y:=0.0;
  while y<max do begin
    x2:=dx*x-dx*y;
    y2:=dy*x+dy*y+f1(x,y)*scale;
    drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
      trunc(x2+sx),trunc(y2+sy)-1,false);
    x1:=x2;
    y1:=y2;
    y:=y+step;
  end;

  y:=0.0;
  while y<(max+step) do begin
    x:=0.0;
    x1:=dx*x-dx*y;
    y1:=dy*x+dy*y+f1(x,y)*scale;
    x:=0.0;
    while x<max do begin
      x:=x+step;
      x2:=dx*x-dx*y;
      y2:=dy*x+dy*y+f1(x,y)*scale;
      drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
        trunc(x2+sx),trunc(y2+sy)-1,true);
      x1:=x2;
      y1:=y2;
    end;
    y:=y+step;
  end;

  delay10msec(300);

{*******************************************}

  cleargr;

  step:=80.0;
  max:=1440.0;
  scale:=2000.0;

  dx:=conv(xsize)/(2.2*max);
  dy:=dx/2.0;

  for i:=0 to xsize do mask[i]:=0;

  { Generate a first mask }
  x:=0.0;
  y:=0.0;
  x1:=dx*x-dx*y;
  y1:=dy*x+dy*y+
    f2(x-max/2.0,y-max/2.0)*scale;
  x:=0.0;
  while x<max do begin
    x2:=dx*x-dx*y;
    y2:=dy*x+dy*y+
      f2(x-max/2.0,y-max/2.0)*scale;
    drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
      trunc(x2+sx),trunc(y2+sy)-1,false);
    x1:=x2;
    y1:=y2;
    x:=x+step;
  end;

  x:=0.0;
  while x<(max+step) do begin
    y:=0.0;
    x1:=dx*x-dx*y;
    y1:=dy*x+dy*y+
      f2(x-max/2.0,y-max/2.0)*scale;
    y:=0.0;
    while y<max do begin
      y:=y+step;
      x2:=dx*x-dx*y;
      y2:=dy*x+dy*y+
        f2(x-max/2.0,y-max/2.0)*scale;
      drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
        trunc(x2+sx),trunc(y2+sy)-1,true);
      x1:=x2;
      y1:=y2;
    end;
    x:=x+step;
  end;

  for i:=0 to xsize do mask[i]:=0;

    { Generate a first mask }
  x:=0.0;
  y:=0.0;
  x1:=dx*x-dx*y;
  y1:=dy*x+dy*y+
    f2(x-max/2.0,y-max/2.0)*scale;
  y:=0.0;
  while y<max do begin
    x2:=dx*x-dx*y;
    y2:=dy*x+dy*y+
      f2(x-max/2.0,y-max/2.0)*scale;
    drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
      trunc(x2+sx),trunc(y2+sy)-1,false);
    x1:=x2;
    y1:=y2;
    y:=y+step;
  end;

  y:=0.0;
  while y<(max+step) do begin
    x:=0.0;
    x1:=dx*x-dx*y;
    y1:=dy*x+dy*y+
      f2(x-max/2.0,y-max/2.0)*scale;
    x:=0.0;
    while x<max do begin
      x:=x+step;
      x2:=dx*x-dx*y;
      y2:=dy*x+dy*y+
        f2(x-max/2.0,y-max/2.0)*scale;
      drawmasked(trunc(x1+sx),trunc(y1+sy)-1,
        trunc(x2+sx),trunc(y2+sy)-1,true);
      x1:=x2;
      y1:=y2;
    end;
    y:=y+step;
  end;

{*******************************************}

  waitforkey;
  grend;

end.