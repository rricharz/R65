 {
         *****************
         *               *
         *   getsource   *
         *               *
         *****************

    make a copy of a source file from
    from the disk SOURCEPASCAL or
    SOURCECOMPIL on the disk WORK in
    drive 1.

    usage: getsource filename

    2019 rricharz (r77@bluewin.ch)
}

program getsource;
uses syslib,arglib,disklib;

const afloppy=$c827; { exdos vector }

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
    writeln('Usage: getsource filename')
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
    write('Copying ');
    writename(fname);
    writeln(',0,1');
    setargs(fname,0,0,0);
    argtype[10]:='i';
    arglist[10]:=1; {copy to drive 1}
    cyclus:=0; drive:=0;
    filerr:=0;
    runprog('COPY:R          ',cyclus,drive);
    if (filerr<>0) or (runerr<>0) then begin
      ok:=false;
      if filerr=6 then writeln(invvid,
        'Source file not found',norvid)
      else writeln(invvid,
        'Copy failed',norvid);
    end;
    { make sure that PASCAL is on drive 0 }
    writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
  end;
  if (not ok) or (runerr<>0) then begin
    writeln(invvid,'Getsource failed',norvid);
    filerr:=0; runerr:=0;
  end;
  dummy:=freedsk(1,true);
end.
