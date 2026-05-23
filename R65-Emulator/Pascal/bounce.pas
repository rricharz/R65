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

const gravity    = 0.15;
      friction   = 0.99; {bounce friction }
      keyfactor  = 1.2;

      erase      = 0;      {bitmap to erase ball}
      ball       = $6ff6;  {bitmap to paint ball}
      ballr      = 4.0; {including corners of bitmap}

      autorepeat = false;
      cleft      = chr($03);
      cright     = chr($16);
      cup        = chr($1a);
      cdown      = chr($18);
      escape     = chr(0);

var   x,y,xspeed,yspeed: real;
      i,xi,yi,xl,yl,keycode,mode,lastmode: integer;
      xc,yc,rc: real;

{$I IRANDOM:P}

proc initmode;
begin
  _cleargr;
  xspeed:=rrandom(0.4,4.0);
  yspeed:=rrandom(0.4,3.0);

  case mode of
    1: begin
         x:=2.5; y:=conv(YSIZE)/2.0;
         xl:=trunc(x); yl:=trunc(y);
       end;
    2: begin
         x:=2.5; y:=conv(YSIZE)/2.0;
         xl:=trunc(x); yl:=trunc(y);
         xc:=conv(XSIZE) * 0.5;
         yc:=conv(YSIZE) * 0.5;
         rc:=conv(YSIZE) * 0.25;
         _circle(trunc(xc),trunc(yc),trunc(rc),WHITE);
       end;
    3: begin
         x:=conv(XSIZE)/2.0; y:=conv(YSIZE)/2.0;
         xl:=trunc(x); yl:=trunc(y);
         xc:=conv(XSIZE) * 0.5;
         yc:=conv(YSIZE) * 0.5;
         rc:=conv(YSIZE) * 0.5 - 5.0;
         _circle(trunc(xc),trunc(yc),trunc(rc),WHITE);
       end
    end {case};
end;

proc apply_friction;
begin
  xspeed := xspeed * friction;
  yspeed := yspeed * friction;
end;

proc reflect;
var radx,rady,l,sp1,sp2,mx,my,rx,ry:real;
begin
  { calculate radius vector }
  rx := xc - x;
  ry := yc - y;
  { normalize this vector, make lenght = 1 }
  l  := sqrt(rx*rx + ry*ry);
  rx := rx / l;
  ry := ry / l;
  { calculate dot product of radius and motion }
  sp1 := rx*xspeed + ry*yspeed;
  { calculate dot product of tangent and motion }
  sp2 := ry*xspeed - rx*yspeed;
  { project motion vector on radius and tangent }
  { invert radial component}
  xspeed := -rx*sp1 + ry*sp2;
  yspeed := -ry*sp1 - rx*sp2;
  { apply friction }
  apply_friction;
  { put ball back inside/outside of circle }
  { and make sure that it does not touch circle }
  if mode = 2 then begin
    x := xc - rx * (rc + ballr);
    y := yc - ry * (rc + ballr);
  end
  else begin
    x := xc - rx * (rc - ballr);
    y := yc - ry * (rc - ballr);
  end;
end;

func expaint:boolean;
begin
  expaint := false;
  if mode<>lastmode then initmode;
  lastmode := mode;

  { limit speed }
  if xspeed>8.0 then xspeed := 8.0
  else if xspeed<-8.0 then xspeed := -8.0;
  if yspeed>8.0 then yspeed := 8.0
  else if xspeed<-8.0 then yspeed := -8.0;

  { apply gravity }
  yspeed := yspeed - gravity;
  { calculate new position on canvas }
  x := x + xspeed;
  y := y + yspeed;

  if x<1.5 then begin
    x := 1.5;
    xspeed := -xspeed;
    apply_friction;
  end else if x>(conv(XSIZE)-1.5) then begin
    x := conv(XSIZE) - 1.5;
    xspeed := -xspeed;
    apply_friction;
  end;
  if y<1.5 then begin
    y := 1.5;
    yspeed := -yspeed;
    apply_friction;
  end else if y>(conv(YSIZE)-1.5) then begin
    yspeed := -yspeed;
    y := conv(YSIZE)-1.5;
    apply_friction;
  end;

  case mode of
    2: if (xc-x)*(xc-x)+(yc-y)*(yc-y)
         <= (rc+ballr)*(rc+ballr) then reflect;
    3: if (xc-x)*(xc-x)+(yc-y)*(yc-y)
         >= (rc-ballr)*(rc-ballr) then reflect
    end {case};

  xi := trunc(x);
  yi := trunc(y);
  _plotmap(xl-1,yl-1,erase);
  _plotmap(xi-1,yi-1,ball);
  xl := xi;
  yl := yi;
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
    'F':     _fullview;
    'S':     _splitview;
    escape:  exkey:=true
  end {case};
  if mode>3 then mode:=1;
end;

{$I IANIMATE:P}

begin
  _grinit;
  _cleargr;
  _fullview;
  for i := 0 to 11 do writeln;
  writeln
('up/down to increase/decrease vertical speed');
   write
('right/left to increase/decrease horizontal speed');
  write
('space bar to change mode');
  mode:=1; lastmode:=0;
  animate(autorepeat);
  _grend;
end.
