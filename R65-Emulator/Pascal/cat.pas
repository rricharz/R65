{************************}
{* cat - show text file *}
{************************}

{ maximal MAXLINES lines are shown }
{ usage: cat filename [firstline]  }

program cat;
uses syslib, arglib, strlib, striolib;

{$U+}

const MAXLINES = 38;

var name :          cpnt;
    f:              file;
    ch:             char;
    cyclus, drive:  integer;

    firstline,line: integer;
    default:        boolean;

begin
  name := _new;
  cyclus    := 0;
  drive     := 1;
  firstline := 0;
  default   := true;
  { get parameter 1 (name of file) }
  _sgetstring(name, _carg, default);
  if default then
    writeln('Usage: cat filename [firstline]')
  _agetval(cyclus,    default);
  _agetval(drive,     default);
  _agetval(firstline, default);
  debug(cyclus, drive, firstline)
  _ssetsubtype(name,'P', false);
  _strfio(name, cyclus, drive);
  openr(f);
  { writeln; }

  { skip lines }
  line := 0;
  read(@f, ch);
  while (ch <> EOF) and (line < firstline) do begin
    if (ch = CR) then
      line := line + 1;
    read(@f, ch);
  end;

  { show max 40 lines }
  line := 0;
  while (ch <> EOF) and (line < MAXLINES) do begin
    if (ch = CR) then begin
      writeln;
      line := line + 1;
    end else
      write(ch);
    read(@f, ch);
  end;
  close(f);
  if line = MAXLINES then
  write(INVVID,' Additional lines not shown;',
        ' use VIEW filename', NORVID);
  writeln;
  _release(name);
end.