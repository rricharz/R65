program cat;
uses syslib, arglib, strlib, striolib;

{$U+}

const
    CUP = chr($1a);
    DEBUG = false;

var name :         cpnt;
    f:             file;
    ch:            char;
    cyclus, drive: integer;
    default:       boolean;

begin
  name := _new;
  cyclus := 0;
  drive := 1;
  default := true;
  { get parameter 1 (name of file) }
  _sgetstring(name, _carg, default);
  _agetval(cyclus, default);
  _agetval(drive, default);
  if DEBUG then
    writeln('cyclus=',cyclus,' drive=', drive)
  _ssetsubtype(name,'P', false);
  _strfio(name, cyclus, drive);
  write(CUP); { avoid an empty line }
  openr(f);
  read(@f, ch);
  writeln;
  while (ch <> EOF) do begin
    if (ch = CR) then
      writeln
    else
    write(ch);
      read(@f, ch);
  end;
  writeln;
  _release(name);
end.