{ test13: target compiler test }

program test13;

var name:array[7] of char;
    i: integer;
    
  proc prtext8(text: array[7] of char);
  
  var i: integer;

  begin
    for i:=0 to 7 do write(text[i]);
  end;

begin
  for i:=0 to 7 do name[i]:=chr(ord('0')+i);
  prtext8(name); writeln;
  name:='abcdefgh';
  prtext8(name); writeln;
end.
