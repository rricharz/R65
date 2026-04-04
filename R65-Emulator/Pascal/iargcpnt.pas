{ IARGCPNT.PAS                     }
{ Include file providing acces to  }
{ arguments with   cpnt srrings    }

 proc conv_to_cpnt(n:array[15] of char; s: cpnt);
{**********************************************}
{ convert from array of char to cpnt string }
var i:integer;
begin
  i:=15;
  { skip trailing blanks }
  while (i>=0) and (n[i]=' ') do begin
    s[i]:=chr(0);
    i:=i-1;
  end;
  while i>=0 do begin
    s[i]:=n[i];
    i:=i-1;
    end;
end;

proc aget_cpnt(s: cpnt);
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
