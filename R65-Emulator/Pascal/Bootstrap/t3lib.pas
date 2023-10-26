{ test3.pas }
{ test syslib procedure call }

library t3lib;

func abs(x: integer): integer;
begin
  if x<0 then abs:=-x else  abs:=x
end;

begin
end.
  
