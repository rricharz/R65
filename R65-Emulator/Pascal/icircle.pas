proc circle(x,y,r,c:integer);
var step,rr,angle:real;
begin
 rr:=conv(r); step:=180.0/rr; angle:=0.0;
 if step>22.5 then step:=22.5;
 move(x+r,y);
 repeat
   angle:=angle+step;
   draw(x+trunc(rr*cos(angle)+0.5),
        y+trunc(rr*sin(angle)+0.5),c);
 until angle>=360.0;
end;