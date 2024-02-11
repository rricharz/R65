{
         *****************
         *               *
         *   putobject   *
         *               *
         *****************

    move a object file from
    the WORK disk on the disk PASCAL

    usage: putobject filename

    2019 rricharz (r77@bluewin.ch)
}

program putobject;
uses syslib,arglib;

const afloppy=$c827; { exdos vector }

mem filerr=$db: integer&;

var cyclus,drive,k: integer;
    fname,dname: array[15] of char;
    default,ok,libflag: boolean;

{$I IFILE:P}

begin
  ok:=true;
  filerr:=0;
  { get the argument (file name) }
  cyclus:=0; drive:=0;
  agetstring(fname,default,cyclus,drive);
  if default or not letter(fname[0]) then
    writeln('Usage: putobject filename')
  else begin
    { make sure that WORK is on drive 1 }
    writeln('Putting disk WORK in drive 1');
    cyclus:=0; drive:=1;
    asetfile('WORK            ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { make sure that PASCAL is on drive 0 }
    writeln('Putting disk PASCAL in drive 0');
    cyclus:=0; drive:=0;
    asetfile('PASCAL          ',cyclus,drive,' ');
    call(afloppy);
    if (filerr<>0) then ok:=false;
    { find out which files to copy }
    libflag := contains('LIB     ');
    { copy the object file(s) }
    argtype[10]:='i';
    arglist[10]:=0; {copy to drive 0}
    argtype[11]:=chr(0);
    cyclus:=0; drive:=0; filerr:=0;
    writeln('Copying the file(s)');
    if libflag then begin
      setsubtype('L');
      setargs(fname,0,0,1);
      runprog('COPY:R          ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then begin
        ok:=false;
      end else begin
        setsubtype('T');
        setargs(fname,0,0,1);
        runprog('COPY:R          ',cyclus,drive);
      end
    end else begin  { not a library }
      setsubtype('R');
      setargs(fname,0,0,1);
      runprog('COPY:R          ',cyclus,drive);
    end;
    if (filerr<>0) or (runerr<>0) then begin
      ok:=false;
      if filerr=6 then
        writeln(invvid,
             'Object file not found',norvid)
      else
        writeln(invvid,'Copy failed',norvid);
    end else begin {if successfull}
      { delete the original file }
      setargi(0,8);
      writeln('Deleting the original file(s)');
      drive:=0; filerr:=0;
      runprog('DELETE:R        ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then begin
        writeln(invvid,
          'Deleting original failed',norvid);
        ok:=false;
      end;
      if libflag then begin
        setsubtype('L');
        setargs(fname,0,0,1);
        runprog('DELETE:R        ',cyclus,drive);
        if (filerr<>0) or (runerr<>0) then begin
          writeln(invvid,
            'Deleting original failed',norvid);
          ok:=false;
        end;
      end;
      { delete any remaining :Q files }
      writeln('Deleting any remaining temporary files');
       setsubtype('Q');
      fname[0]:='*';
      setargs(fname,0,0,1);
      runprog('DELETE:R        ',cyclus,drive);
      { clean the destination drive }
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('CLEAN:R         ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
      { pack the destination drive }
      setargi(0,0);
      argtype[1]:=chr(0);
      cyclus:=0; drive:=0; filerr:=0;
      runprog('PACK:R          ',cyclus,drive);
      if (filerr<>0) or (runerr<>0) then
         ok:=false;
    end;
  end;
  if (not ok) or (runerr<>0) then begin
    writeln(invvid,'Putobject failed',norvid);
    filerr:=0; runerr:=0;
  end;
end.
