{ ********************
  *    CHECKBUILD    *
  ********************

  checks whether all programs can
  be compiled. Uses chain to run COMPILE
  with option /N@.
  COMPILE chains checkbuild again }

{$U+}

program checkbuild;
uses syslib;
{ minimized library calls to save memory }

mem
  FILFLG  = $00da: integer&;
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

proc chainprog(name0: array[15] of char;
               cyc: integer; drv: integer);
{*****************************************}
var ii: integer;
begin
  RUNERR:=0;
  for ii:=0 to 15 do FILNM1[ii]:=name0[ii];
  FILCY1:=cyc; FILDRV:=drv; FILFLG:=$40;
  chain
end;

proc setargi(argi, carg: integer);
{********************************}
begin
  ARGTYPE[carg]:='i';
  ARGLIST[carg]:=argi;
  ARGTYPE[carg+1]:=chr(0);
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

  if (ARGTYPE[20]='i') and (ARGTYPE[21]='i')
                       and (ARGTYPE[22]='i') then
  begin
    { get back values saved in arglist }
    entry:=ARGLIST[20] + 1;
    files:=ARGLIST[21] + 1;
    errors:=ARGLIST[22];
    debug('checkbuild get back',entry,files,errors);
  end;
  repeat
    done := not getentry(drive, entry, deleted);
    debug(entry,files,deleted,done);
    if (not (deleted or done)) and
        (FILSTP = 'P') then begin
      name := '                ';
      i := 0;
      writeln(@PRINTER);
      write(PRTON);
      { compile1 requires name without subtype }
      while (i<=15) and  (FILNAM[i]<>':') do begin
        name[i] := FILNAM[i];
        i := i + 1;
      end;
      cyclus := FILCYC;
      setargs(name,0, cyclus, 1);
      setargs('/N@             ', 10, 0, 1);
      { save values for chain }
      setargi(entry, 20);
      setargi(files, 21);
      setargi(errors,22);
      if _isesc then
        done := true
      else
        chainprog('COMPILE:R       ', 0, 1);
      end;
    end;
    entry := entry + 1;
    if _isesc then done := true;
  until done;
  writeln(PRTON);
  writeln('CHECKBUILD complete, errors: ',errors);
  writeln('Files checked:               ', files);
  if errors > 0 then
    writeln(INVVID,
      'Errors found, check listing for details',
      NORVID);
  write(PRTOFF);

end.
                          