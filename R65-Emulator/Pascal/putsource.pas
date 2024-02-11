 {
         *****************
         *               *
         *   putsource   *
         *               *
         *****************

    move the source file from the WORK disk
    on the disk SOURCEPASCAL or SOURCECOMPIL

    usage: putsource filename

    2019 rricharz (r77@bluewin.ch)
}

program putsource;
uses syslib,arglib,disklib;

const afloppy=$c827; { exdos vector }
      aexport=$c82a; { exdos vector }

mem filerr=$db: integer&;

var cyclus,drive,k,dummy: integer;
    fname,dname: array[15] of char;
    default,ok: boolean;

{$I IFILE:P}

begin
  ok:=true;
  filerr:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: putsource filename')
  else begin
    setsubtype('P');
      dname:='PSOURCE         ';
    { make sure that WORK is on drive 1 }
    writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { make sure that dname is on drive 0 }
    write('Putting disk ');  writename(dname);
    writeln(' in drive 0');
    cyclus:=0; drive:=0;
    asetfile(dname,cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { copy the source file }
    if ok then begin
      write('Copying the source file ');
      writename(fname);
      writeln;
      setargs(fname,0,0,1);
      argtype[10]:='i';
      arglist[10]:=0; {copy to drive 0}
      argtype[11]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('COPY:R          ',cyclus,drive);
    end;
    if (filerr<>0) or (runerr<>0) then begin
      ok:=false;
      if filerr=6 then
        writeln(invvid,
          'Source file not found',norvid)
      else
        writeln(invvid,'Copy failed',norvid);
    end else begin {if successfull}
      setargi(filcyc,8);
      { export the source file }
      write('Exporting the source file');
      fildrv:=1;
      call(aexport);
      writeln;

      { delete the source file }
      writeln('Deleting the source file');
      drive:=0; filerr:=0;
      setargi(0,8);
      runprog('DELETE:R        ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then  begin
        ok:=false;
        writeln(invvid,
          'Deleting original failed',norvid);
      end;

      { clean the destination drive }
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('CLEAN:R         ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;

      { pack the destination drive }
      writeln('Packing PSOURCE');
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('PACK:R          ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
      dummy:=freedsk(0,true);
    end;

    { make sure that PASCAL is on drive 0 }
    writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
  end;
  if not ok then begin
    writeln(invvid,'Putsource failed',norvid);
    filerr:=0; runerr:=0;
  end
end.

