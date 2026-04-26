
{             *****************               }
{             *               *               }
{             *   putsource   *               }
{             *               *               }
{             *****************               }

{   move the source file from the WORK disk   }
{   on the disk SOURCEPASCAL or SOURCECOMPIL  }

{   usage: putsource filename                 }

{   2019 rricharz (r77@bluewin.ch)            }

{   03/31/2026 rricharz                       }
{   removed clean and pack on drive PSOURCE   }
{   Instead added display of free space       }


program putsource;
uses syslib,arglib,filelib,wildlib;

const afloppy = $c827; { exdos vector }
      aexport = $c82a; { exdos vector }
      CUP    = chr($1a);
      VERBOSE = false;

mem filerr=$db: integer&;

var cyclus,drive,k,dummy,free: integer;
    fname,dname: array[15] of char;
    default,ok: boolean;

{$I IFILE:P}

begin
  ok:=true;
  filerr:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  _agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: putsource filename')
  else begin
    setsubtype('P');
      dname:='PSOURCE         ';
    { make sure that WORK is on drive 1 }
    if VERBOSE then
      writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    _asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { make sure that dname is on drive 0 }
    if VERBOSE then begin
      write('Putting disk ');
      _writename(dname);
      writeln(' in drive 0');
    end;
    cyclus:=0; drive:=0;
    _asetfile(dname,cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
{ copy the source file }
    if ok then begin
      if VERBOSE then begin
        write('Saving and exporting ');
        _writename(fname);
        writeln;
        end;
      setargs(fname,0,0,1);
      ARGTYPE[10]:='i';
      ARGLIST[10]:=0; {copy to drive 0}
      ARGTYPE[11]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('COPY:R          ',cyclus,drive);
    end;
    if (filerr<>0) or (RUNERR<>0) then begin
      ok:=false;
      if filerr=6 then
        writeln(INVVID,
          'Source file not found',NORVID)
      else
        writeln(INVVID,'Copy failed',NORVID);
    end else begin {if successfull}
      setargi(FILCYC,8);
{ export the source file }
      write('Exporting the source file');
      FILDRV:=1;
      call(aexport);
      writeln('=');

      { delete the source file               }
      writeln('Deleting the source file(s) on WORK');
      drive:=0; filerr:=0;
      setargi(0,8);
      runprog('DELETE:R        ',cyclus,drive);
      if (filerr<>0) or (RUNERR<>0) then  begin
        ok:=false;
        writeln(INVVID,
           'Deleting original failed',NORVID);
      end;

      { check free space on destination drive }
      free:=_freedrv(0,false);
      if free<20 then write(INVVID);
      writeln( 'Free space on drive PSOURCE ',
            free,'%',NORVID);

      { clean the destination drive                }
      { setargi(0,0);                              }
      { ARGTYPE[1]:=chr(0);                        }
      { cyclus:=0; drive:=0; filerr:=0; RUNERR:=0; }
      { runprog('CLEAN:R         ',cyclus,drive);  }
      { if (filerr<>0) or (RUNERR<>0) then begin   }
      {    ok:=false;                              }
      {    writeln(INVVID,                         }
      {       'Cleaning PSOURCE failed',NORVID);   }
      { end;                                       }

      { pack the destination drive                 }
      { writeln('Packing PSOURCE');                }
      { setargi(0,0);                              }
      { ARGTYPE[1]:=chr(0);                        }
      { cyclus:=0; drive:=0; filerr:=0;            }
      { runprog('PACK:R          ',cyclus,drive);  }
      { if (filerr<>0) or (RUNERR<>0) then         }
      {  ok:=false;                                }
    end;

    { make sure that PASCAL is on drive 0 }
    if VERBOSE then
      writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    _asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
  end;
  if not ok then begin
    writeln(INVVID,'Putsource failed',NORVID);
    filerr:=0; RUNERR:=0;
  end
end.

