{
        *****************
        *               *
        *     BOUNCE    *
        *               *
        *****************

A bouncing ball simulation for the
R65 Graphics display.

With circle in the center of the canvas

    Original    1979 rricharz
    New version 2024 rricharz
                                }

program bounce;
uses syslib,plotlib,mathlib;

const gravity=0.15; keyfactor=1.2;
      erase=0; ball=$6ff6;
      autorepeat=false;
      cleft=chr($03); cright=chr($16);
      cup=chr($1a); cdown=chr($18); escape=chr(0);

var x,y,xspeed,yspeed: real;
    xi,yi,xl,yl,keycode,mode,lastmode: integer;
    xc,yc,rc: real;

{$I IRANDOM:P}
{$I ICIRCLE:P }

proc initmode;
begin
  cleargr;
  xspeed:=rrandom(0.4,4.0);
  yspeed:=rrandom(0.4,3.0);

  move(0,ysize);
  draw(0,0,white);
  draw(xsize,0,white);
  draw(xsize,ysize,white);
  draw(0,ysize,white);
  move(0,ysize-14);
  draw(xsize,ysize-14,white);
  move(2,ysize - 11);
  write(@plotdev,'mode ',mode);
  write(@plotdev,' Use arrows,space,esc');

  case mode of
    1: begin
         x:=2.5; y:=conv(ysize)/2.0;
         xl:=trunc(x); yl:=trunc(y);
       end;
    2: begin
         x:=2.5; y:=conv(ysize)/2.0;
         xl:=trunc(x); yl:=trunc(y);
         xc:=conv(xsize) * 0.5;
         yc:=conv(ysize-14) * 0.5;
         rc:=conv(ysize-14) * 0.25;
         circle(trunc(xc),trunc(yc),trunc(rc),white);
       end;
    3: begin
         x:=conv(xsize)/2.0; y:=conv(ysize)/2.0;
         xl:=trunc(x); yl:=trunc(y);
         xc:=conv(xsize) * 0.5;
         yc:=conv(ysize-14) * 0.5;
         rc:=conv(ysize-14) * 0.5 - 1.0;
         circle(trunc(xc),trunc(yc),trunc(rc),white);
       end
    end {case};
end;

proc reflect;
var radx,rady,l,sp1,sp2,mx,my,rx,ry:real;
begin
  { calculate radius vector }
  rx:=xc-x; ry:=yc-y;
  { normalize this vector, make lenght = 1 }
  l:=sqrt(rx*rx+ry*ry);
  rx:=rx/l; ry:=ry/l;
  { calculate dot product of radius and motion }
  sp1:=rx*xspeed+ry*yspeed;
  { calculate dot product of tangent and motion }
  sp2:=ry*xspeed-rx*yspeed;
  { project motion vector on radius and tangent }
  { invert radial component}
  xspeed:=-rx*sp1+ry*sp2; yspeed:=-ry*sp1-rx*sp2;
  { put ball back outside of circle }
  x:=conv(xl); y:=conv(yl);
end;

func expaint:boolean;
begin
  expaint:=false;
  if mode<>lastmode then initmode;
  lastmode:=mode;

  { check speed }
  if xspeed>8.0 then xspeed:=8.0
  else if xspeed<-8.0 then xspeed:=-8.0;
  if yspeed>8.0 then yspeed:=8.0
  else if xspeed<-8.0 then yspeed:=-8.0;
  yspeed:=yspeed-gravity;

  { check position on canvas }
  x:=x+xspeed;
  y:=y+yspeed;
  if x<2.5 then begin
    x:=2.5;
    xspeed:=-xspeed;
  end else if x>conv(xsize-3) then begin
    x:=conv(xsize-3);
    xspeed:=-xspeed;
  end;
  if y<2.5 then begin
    y:=2.5;
    yspeed:=-yspeed+0.5*gravity;
  end else if y>conv(ysize-17) then begin
    yspeed:=-yspeed;
    y:=conv(ysize-18);
  end;

  case mode of
    2: if (xc-x)*(xc-x)+(yc-y)*(yc-y)
         <= (rc+3.1)*(rc+3.1) then reflect;
    3: if (xc-x)*(xc-x)+(yc-y)*(yc-y)
         >= (rc-3.5)*(rc-3.5) then reflect
    end {case};

  xi:=trunc(x);
  yi:=trunc(y);
  plotmap(xl-1,yl-1,erase);
  plotmap(xi-1,yi-1,ball);
  xl:=xi;
  yl:=yi;
end;

func exkey(ch:char):boolean;
begin
  exkey:=false; lastmode:=mode;
  case ch of
    cup:     yspeed:=yspeed*keyfactor;
    cdown:   yspeed:=yspeed/keyfactor;
    cleft:   xspeed:=xspeed/keyfactor;
    cright:  xspeed:=xspeed*keyfactor;
    ' ':     mode:=mode+1;
    'F':     fullview;
    'S':     splitview;
    escape:  exkey:=true
  end {case};
  if mode>3 then mode:=1;
end;

{$I IANIMATE:P}

begin
  grinit; cleargr; fullview;
  mode:=1; lastmode:=0;
  animate(autorepeat);
  splitview;
end.
