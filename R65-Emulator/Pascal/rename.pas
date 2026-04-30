{****************************}
{* RENAME - rename one file *}
{****************************}

program rename;
uses syslib, arglib, filelib, wildlib;

const
    aenddo     = $f625;
    putfentp3  = $f583;
    NAMESIZE   = 15;
    NUMENTRIES = 255;

mem FILLNK     = $031e: integer&;
    FILCN1     = $e5: integer&;

var filename, newname:      array[NAMESIZE] of char;
    i, cyclus, newcyclus,
    drive, newdrive, entry: integer;
    default, found, last:   boolean;

begin

  cyclus  := 0;
  newcyclus := 0;
  drive   := 1;
  newdrive := 1;

  default := false;

  if (ARGTYPE[_carg] <> 's') then begin
    writeln(INVVID,
      'Usage: rename filename newname',NORVID);
    exit;
  end;

  _agetstring(filename, default, cyclus, drive);

  _agetstring(newname, default, newcyclus, newdrive);

  {find matching file entry }
  entry := 0;
  found := false;
  last  := false;
  while not(found or last) do begin
    _findentry(filename, drive, entry, found, last);
    if (cyclus <> 0) then
      if (cyclus <> FILCYC) then
        found := false;
  end;

  if not found then begin
    writeln(INVVID, 'File not found', NORVID);
    exit;
  end;

  for i := 0 to 15 do
    if (newname[i]='*') or (newname[i]='/') then begin
      writeln(INVVID,
      'Character in new name not allowed', NORVID);
      exit;
    end;

  _write_label; writeln('-');

  { rename }

  for i:=0 to 15 do
    FILNAM[i] := newname[i];
  if newcyclus <> 0 then FILCYC := newcyclus;
  _write_label; writeln('+');

  call(putfentp3);
  call(aenddo);
  entry := entry + 1;

end. 