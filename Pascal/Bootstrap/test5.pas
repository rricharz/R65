{ test5.pas }
{ test for and repeat loops}

program test5;

var i: integer;

begin {main}

  i:=0;
  repeat
    write(i,' ');
    i:=i+1;
  until i>5;
  writeln;

  for i:=0 to 9 do write(i,' ');
  writeln;
  for i:=9 downto 0 do write(i,' ');  
  writeln;
  
end.
