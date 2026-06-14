{ CD diskname                       }
{ Unix style cd command             }
{ Floppy disk 1 is set to diskname  }

{$U+}

program cd;
uses syslib, arglib, striolib, strlib;

var arg0: cpnt;
    cyclus, drive : integer;
    default: boolean;

begin {main}
  arg0 := _new;
  _sgetstring(arg0, _carg, default);

  if default then
    _strcpy('WORK', arg0);

  debug('Setting disk 1 to ', arg0);
  _change_disk(arg0, 1);

  _release(arg0);
end.
