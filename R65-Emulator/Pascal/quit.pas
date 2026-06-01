program quit;
const astop = $2010;
mem  USERST = $2009: integer;
     STPROG = $0011: integer;
begin
  STPROG := USERST; { force exit from Pascal }
  call(astop);
end. 