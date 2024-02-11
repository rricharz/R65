{ check for escape flag, return true if set }
{ check for CTRL-L and execute, if typed }

func chkesc(checktoggle:boolean):boolean;
const toggle=chr($0c);
mem sflag=$1781:integer&;
begin
  chkesc:=((sflag and $80) <> 0);
  sflag:=sflag and $7f;
  if checktoggle then
    if keypressed=toggle then begin
      write(toggle);
      keypressed:=chr(0);
    end;
end;
