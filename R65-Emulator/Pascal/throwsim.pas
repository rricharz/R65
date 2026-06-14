{ throwsim.pas }

{ trajectory simulation }

program throwsim;
uses syslib,mathlib,plotlib;

var angle,speed,xspeed,yspeed: real;
    i: integer;
    x,y: real;
    ch: char;

begin
  _grinit;  _cleargr; _splitview;
  speed:=1.;
  for i:=1 to 11 do begin
    angle:=7.5*conv(i);
    xspeed:=speed*cos(angle);
    yspeed:=speed*sin(angle);
    x:=0.; y:=0.;
    repeat
      if (trunc(y)<YSIZE) then
        _plot(trunc(x),trunc(y),WHITE);
      x:=x+xspeed;
      y:=y+yspeed;
      yspeed:=yspeed-0.005;
    until (trunc(x)>XSIZE) or (trunc(y)<0);
  end;
end.
