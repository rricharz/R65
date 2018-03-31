{ test6.pas }
{ test case statement}

program test6;

var a: integer;
    b: char;
    
begin {main}
  a := 2;
  case a of
   1: begin write(1); write('-') end;
   2: write(2);
   3: write(3)
  end;
  
  b := 'x';
  case b of
    'a': write(4);
    'x': begin write(5); write('-') end
  end;
    
end.
