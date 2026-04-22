proc circle(xx,yy,r,c:integer);
var step,rr,angle:real;
begin
 rr:=conv(r); step:=180.0/rr; angle:=0.0;
 if step>22.5 then step:=22.5;
 _move(xx+r,yy);
 repeat
   angle:=angle+step;
   _draw(xx+trunc(rr*cos(angle)+0.5),
        yy+trunc(rr*sin(angle)+0.5),c);
 until angle>=360.0;
end;
