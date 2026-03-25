program extract;
uses syslib, arglib, strlib;

var
  f_in, f_out: file;
  line: cpnt;
  name: array[15] of char;
  lineno: integer;
  ateof: boolean;
  llen: integer;

proc strread(f:file;
               s:cpnt;
                 var ateof0:boolean;
                   var len:integer);
{**********************************}
var ch  : char;
    i   : integer;
    done: boolean;
begin
  ateof0 := false;
  i := 0;
  done := false;

  while not done do
  begin
    read(@f, ch);

    if ch = EOF then
    begin
      ateof0 := true;
      done := true;
    end;

    if (not done) and (ch = chr($0d)) then
      done := true;

    if (not done) and (ch = chr($0a)) then
      done := true;

    if not done then
      if i < STRSIZE-1 then
      begin
        s[i] := ch;
        i := i + 1;
      end;
  end;

  s[i] := ENDMARK;
  len := i;
end;

proc strwrite(f:file; s:cpnt);
{****************************}
{ bypass a bug in compile1, cannot write s to f }
var i: integer;
begin
  i := 0;
  while s[i] <> ENDMARK do
  begin
    write(@f, s[i]);
    i := i + 1;
  end;
end;

proc setsubtype(subtype:char);
{****************************}
{ set subtype in name }
var i:integer;
begin
  i := 0;
  repeat
    i:=i + 1;
  until (name[i]=':') or
    (name[i] = ' ') or (i >= 14);
  name[i] := ':';
  name[i+1]:=subtype;
end;

proc open_files(outsubtype: char);
{********************************}
var default: boolean;
    i, cyclus, drive: integer;
begin
  drive   := 1;
  cyclus  := 0;
  default := true;

  { open input file, must be :P }
  _agetstring(name, default, cyclus, drive);
  setsubtype('P');
  _asetfile(name, cyclus, drive, ' ');
  openr(f_in);
  writeln; { required if openr is not silent }

  { open output file }
  cyclus := 0;
  setsubtype(outsubtype);
  _asetfile(name, cyclus, drive, ' ');
  openw(f_out);
end;

proc close_files;
{***************}
begin
  close(f_in);
  close(f_out);
end;

{ main program }
{**************}
begin
  write(PRTON);

  open_files('H'); { for first pass }

  line := _new;
  lineno := 0;
  repeat
    strread(f_in, line, ateof, llen);
    writeln('DEBUG: llen=', llen,
            ', ateof=', ateof);

    writeln('DEBUG: const strcmp=',
      _strcmp('const', line));
    writeln('DEBUG: var strcmp=',
      _strcmp('var', line));

    writeln(line);
    strwrite(f_out, line); writeln(@f_out);
  until ateof;

  close_files;
  _release(line);
  writeln;
  write(PRTOFF);
end.
