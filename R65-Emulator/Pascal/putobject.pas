{
{         *****************            }
{         *               *            }
{         *   putobject   *            }
{         *               *            }
{         *****************            }

{    move a object file from           }
{    the WORK disk on the disk PASCAL  }

{    usage: putobject filename         }

{    2019 rricharz (r77@bluewin.ch)    }


program putobject;
uses syslib, arglib, filelib;

const
    afloppy=$c827; { exdos vector }
    VERBOSE = false;

var cyclus,drive,k: integer;
    fname,dname: array[15] of char;
    default,ok,libflag: boolean;

{$I IFILE:P}

begin
  ok:=true;
  FILERR:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  _agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: putobject filename')
  else begin
    { make sure that WORK is on drive 1 }
    if VERBOSE then
      writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    _asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (FILERR<>0) then ok:=false;
    { make sure that PASCAL is on drive 0 }
    if VERBOSE then
      writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    _asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (FILERR<>0) then ok:=false;
    { find out which files to copy }
    libflag := contains('LIB     ');
    { copy the object file(s) }
    ARGTYPE[10]:='i';
    ARGLIST[10]:=0; {copy to drive 0}
    ARGTYPE[11]:=chr(0);
    cyclus:=0; drive:=0; FILERR:=0;
    if VERBOSE then
      writeln('Copying object file(S):');
    if libflag then begin
      setsubtype('L');
      setargs(fname,0,0,1);
      _runprog('COPY:R          ',cyclus,drive);
      if (FILERR <> 0) or (RUNERR <> 0) then begin
        writeln('COPY completed with error');
        ok:=false;
      end else begin
        setsubtype('T');
        setargs(fname,0,0,1);
        _runprog('COPY:R          ',cyclus,drive);
      end
    end else begin  { not a library }
      setsubtype('R');
      setargs(fname,0,0,1);
      _runprog('COPY:R          ',cyclus,drive);
    end;
    if (FILERR<>0) or (RUNERR<>0) then begin
      ok:=false;
      if FILERR=6 then
        writeln(INVVID,
             'Object file not found',NORVID)
      else
        writeln(INVVID,'Copy failed',NORVID);
    end else begin {if successfull}
      { delete the original file }
      setargi(0,8);
      drive:=0; FILERR:=0;
      setargs('/Q              ', 10, 0, 0);
      _runprog('DELETE:R        ',cyclus,drive);
      if (FILERR <> 0) or (RUNERR <> 0) then begin
        write('DELETE completed with error');
        ok:=false;
      end;
      if libflag then begin
        setsubtype('L');
        setargs(fname,0,0,1);
        setargs('/Q              ', 10, 0, 0);
        _runprog('DELETE:R        ',cyclus,drive);
        if (FILERR <> 0) or (RUNERR <> 0) then begin
          write('DELETE completed with error');
          ok:=false;
        end;
      end;
      { delete any remaining :Q files }
      if VERBOSE then
        writeln('Deleting remaining temporary files');
      setsubtype('Q');
      fname[0]:='*';
      setargs(fname,0,0,1);
      setargs('/Q              ', 10, 0, 0);
      _runprog('DELETE:R        ',cyclus,drive);
      { clean the destination drive }
      setargi(0,0);
      ARGTYPE[1]:=chr(0);
      cyclus:=0; drive:=0; FILERR:=0;
      setargs('/Q              ', 1, 0, 0);
      _runprog('CLEAN:R         ',cyclus,drive);
      if (FILERR<>0) or (RUNERR<>0) then begin
         ok:=false;
         writeln('CLEAN completed with error');
      end;
      { pack the destination drive }
      setargi(0, 0);
      ARGTYPE[1] := chr(0);
      cyclus := 0;
      drive := 0;
      FILERR := 0;
      _runprog('PACK:R          ',cyclus,drive);
      if (FILERR <> 0) or (RUNERR <> 0) then begin
        write('PACK completed with error');
        ok:=false;
      end;
    end;
  end;
  if (not ok) or (RUNERR<>0) then begin
    writeln(INVVID,'Putobject failed',NORVID);
    FILERR:=0; RUNERR:=0;
  end;
end.

 