{ CD filename                       }
{ Unix style cd command             }
{ Floppy disk 1 is set to filename  }

program cd;
uses syslib, arglib, filelib, strlib;

var arg0: cpnt;
    debug: boolean;

{$I IARGCPNT}

begin {main}
  arg0 := _new;
  aget_cpnt(arg0);
  debug := true;

  { diskname must be given }
  if arg0[0] = ENDMARK then begin
    writeln(INVVID, 'Usage: CD diskname', NORVID);
    _release(arg0);
    exit;
  end;
  if debug then writeln('Setting disk 1 to ', arg0);
  change_disk(arg0, 1);

  _release(arg0);
end.
