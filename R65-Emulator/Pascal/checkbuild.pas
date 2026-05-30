{ ********************
  *    CHECKBUILD    *
  ********************

  checks whether all programs can
  be compiled                      }

{$U+}

program checkbuild;
uses syslib;
{ minimized library calls to save memory }

mem
  FILFLG  = $00da: integer&;
  FILERR  = $db:   integer&;
  FILDRV  = $00dc: integer&;
  FILTYP  = $0300:char&;
  FILNAM  = $0301: array[15] of char&;
  FILCYC  = $0311: integer&;
  FILSTP  = $0312: char&;
  FILNM1  = $0320: array[15] of char&;
  FILCY1  = $0330: integer&;

  ARGLIST  = $0060: array[10] of integer;
  ARGLISTS = $0060: array[63] of char&;
  ARGTYPE  = $00a0: array[31] of char&;

var
  entry, cyclus, drive: integer;
  i, errors, files:     integer;
  done, deleted:        boolean;
  name:                 array[15] of char;

func hex(i8: integer): packed char;
{*********************************}
var hi, lo: integer;
    c1, c2: char;
begin
  hi := (i8 shr 4) and $0f;
  lo := i8 and $0f;
  if hi < 10 then c1 := chr(ord('0') + hi)
             else c1 := chr(ord('A') + hi - 10);
  if lo < 10 then c2 := chr(ord('0') + lo)
             else c2 := chr(ord('A') + lo - 10);
  hex := packed(c1, c2);
end;

proc runprog(name0: array[15] of char;
             cyc: integer; drv: integer);
{****************************************}
var ii: integer;
begin
  RUNERR:=0;
  for ii:=0 to 15 do FILNM1[ii]:=name0[ii];
  FILCY1:=cyc; FILDRV:=drv; FILFLG:=$40;
  run
end;

proc setargs(name0:array[15] of char;
             carg,cyc,drv:integer);
{**********************************}
var k9:integer;
begin
  ARGTYPE[carg] :='s';
  for k9:=0 to 7 do
    ARGLIST[carg+k9]:=
      ord(packed(name0[2*k9+1], name0[2*k9]));
  ARGTYPE[carg+8]:='i';
  ARGLIST[carg+8]:=cyc;
  ARGTYPE[carg+9]:='i';
  ARGLIST[carg+9]:=drv;
  ARGTYPE[carg+10]:=chr(0);
end;

func getentry(drv0, ent0: integer;
              var deleted0: boolean): boolean;
{********************************************}
const
  agetentx = $f63a;
  aenddo   = $f625;
mem
  filtyp   = $0300: char&;
  fillnk   = $031e: integer;
  scyfc    = $037c: integer&;

begin
  scyfc := ent0;
  FILDRV:= drive;
  call(agetentx);
  if FILERR <> 0 then begin
    writeln(INVVID, 'Error: Cannot read directory',
            NORVID);
    _abort;
  end;
  if filtyp = chr(0) then begin { end mark }
    getentry := false;
    call(aenddo);
    getentry := false;
    exit;
  end;
  deleted0 := (fillnk and $80) = $80;
  call(aenddo);
  getentry := true;
end;

begin {main}
{*********}
  entry  := 0;
  drive  := 1;
  errors := 0;
  files  := 0;

  repeat
    done := not getentry(drive, entry, deleted);
{   writeln('deleted= ', deleted,
           ' done= ',done); }
    if (not (deleted or done)) and
        (FILSTP = 'P') then begin
      name := '                ';
      i := 0;
      writeln(@PRINTER);
      write(PRTON);
      { compile1 requires name without subtype }
      while (i<=15) and  (FILNAM[i]<>':') do begin
        name[i] := FILNAM[i];
        write(name[i]);
        i := i + 1;
      end;
      writeln(':P.', hex(FILCYC));
      cyclus := FILCYC;
      setargs(name,0, cyclus, 1);
      setargs('/N              ', 10, 0, 1);
      runprog('COMPILE:R       ', 0, 0);
      files := files + 1;
      { runprog('ARGLIST:R       ', 0, 0); }
      if (RUNERR > 0) and (RUNERR <> 135)
        or (FILERR <> 0) then begin
        errors := errors + 1;
        {writeln('RE=',hex(RUNERR),
               ' FE=',hex(FILERR));}
      end;
    end;
    entry := entry + 1;
  until done;
  writeln(PRTON);
  writeln('CHECKBUILD complete, errors: ',errors);
  writeln('Files checked:               ', files);
  if errors > 0 then
    writeln(INVVID,
      'Errors found, check listing for errors',
      NORVID);
  write(PRTOFF);

end.
                          