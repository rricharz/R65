
{        *****************             }
{        *               *             }
{        *   getsource   *             }
{        *               *             }
{        *****************             }

{   make a copy of a source file from  }
{    from the disk SOURCEPASCAL or     }
{   SOURCECOMPIL on the disk WORK in   }
{    drive 1.                          }

{   usage: getsource filename          }

{   2019 rricharz (r77@bluewin.ch)     }

{$U+}

program getsource;
uses syslib,arglib,filelib,wildlib;

const
    afloppy=$c827; { exdos vector }
    VERBOSE = false;

var cyclus,drive,k,dummy: integer;
    fname,dname: array[15] of char;
    default,ok: boolean;

{$I IFILE:P}

begin
  ok:=true;
  FILERR:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  _agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: getsource filename')
  else begin
    setsubtype('P');
    dname:='PSOURCE         ';
    { make sure that WORK is on drive 1 }
    if VERBOSE then
      writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    _asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (FILERR<>0) then ok:=false;
    { make sure that dname is on drive 0 }
    if VERBOSE then begin
      write('Putting disk ');
      _writename(dname);
      writeln(' in drive 0');
    end;
    cyclus:=0; drive:=0;
    _asetfile(dname,cyclus,drive,' ');
    call(afloppy);
    if (FILERR<>0) then ok:=false;
    { copy the source file }
    if VERBOSE then begin
      write('Copying ');
      _writename(fname);
      writeln(',0,1');
    end;
    setargs(fname,0,0,0);
    ARGTYPE[10]:='i';
    ARGLIST[10]:=1; {copy to drive 1}
    cyclus:=0; drive:=0;
    FILERR:=0; RUNERR:=0;
    _runprog('COPY:R          ',cyclus,drive);
    if (FILERR<>0) or (RUNERR<>0) then begin
      ok:=false;
      if FILERR=6 then writeln(INVVID,
        'Source file not found',NORVID)
      else writeln(INVVID,
        'Copy failed',NORVID);
    end;
    { make sure that PASCAL is on drive 0 }
    if VERBOSE then
      writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    _asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (FILERR<>0) then ok:=false;
  end;
  if (not ok) or (RUNERR<>0) then begin
    writeln(INVVID,'Getsource failed',NORVID);
    FILERR:=0; RUNERR:=0;
  end;
  dummy:=_freedrv(1,true);
end.
