{
  CD filename
  Unix style cd command
  Floppy disk 1 is set to filename
}

program cd;
uses syslib,arglib,strlib;

var arg0: cpnt;
    debug: boolean;

proc conv_to_cpnt(n:array[15] of char; s: cpnt);
{**********************************************}
{ convert from array of char to cpnt string }
begin
end;

proc _aget_cpnt(s: cpnt);
{**********************}
{ gets next string from arglist }
var i:integer;
begin
  if ARGTYPE[_carg] <>'s' then begin
    s[0] := ENDMARK;
  end else begin
    for i:=0 to 15 do begin
      s[i]:=ARGLISTS[2 *_carg + i];
      if s[i] = ' ' then s[i] := ENDMARK;
    end;
    _carg:=_carg + 8;
    s[16] := ENDMARK;
  end;
end;

proc change_disk(s: cpnt; drv: integer);
{*************************************}
{ set drv (drive) to s (name) }
const afloppy=$c827; { exdos vector }
var  name: array[15] of char;
     i, cyclus, drive: integer;
begin
  i := 0;
  cyclus := 0;
  drive := drv;
  while (s[i] <> ENDMARK) and (i <= 15) do begin
    name[i] := s[i];
    i:=succ(i);
  end;
  while i <= 15 do begin
    name[i] := ' ';
    i:=succ(i);
  end;
  _asetfile(name,cyclus,drive,' ');
  call(afloppy);
end;

begin {main}
  arg0 := _new;
  _aget_cpnt(arg0);
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