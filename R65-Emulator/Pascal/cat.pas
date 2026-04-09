program cat;
uses syslib, strlib, striolib;

const CUP = chr($1a);

var name :         cpnt;
    f:             file;
    ch:            char;
    cyclus, drive: integer;
    default:       boolean;

begin
  name := _new;
  drive := 1;
  default := true;
  { get parameter 1 (name of file) }
  _sgetstring(name, default, cyclus, drive);
  _ssetsubtype(name,'P', false);
  _strfio(name,1);
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