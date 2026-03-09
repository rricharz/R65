{ ######################################
  # setb n: set a breakpoint at line n #
  ######################################

  18.11.2023 rricharz                  }

program setb;
uses syslib,arglib;

mem brkpnt=$00c2: integer;

var n: integer;
    default: boolean;

begin
  _agetval(n,default);
  if default then begin
    writeln(INVVID,'Usage: setb linenumber',NORVID);
    brkpnt:=0; { clear break point }
  end else begin
    brkpnt:=n;
    writeln('Breakpoint set at line ',n);
  end;
end. 