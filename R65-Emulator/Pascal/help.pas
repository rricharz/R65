program help;
uses syslib, arglib,wildlib;

const cup=chr($1a);
      clrlin=chr($17);

var cyclus,drive,entry,i: integer;
    found,last,default: boolean;
    ch: char;
    name: array[15] of char;
    fno: file;

proc setsubtype(subtype:char);
{ only set subtype if not already there }
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  if name[i]<>':' then begin
    name[i]:=':';
    name[i+1]:=subtype;
  end;
end;

begin
  cyclus:=0; drive:=1;
  agetstring(name,default,cyclus,drive);
  entry := 0;
  setsubtype('H');
  findentry(name,drive,entry,found,last);
  if not found then begin
    drive:=0; entry:=0;
    findentry(name,drive,entry,found,last);
  end;
  if found then begin
    for i:=0 to 15 do
      name[i] := filnam[i];
    asetfile(name,cyclus,drive,' ');
    write(cup); { avoid empty line }
    openr(fno);
    writeln; write(cup,clrlin);
    ch:='&';
    read(@fno,ch);
    while (ch<>eof) and (ch<>chr(0)) do begin
      if ch=cr then writeln
      else write(ch);
      read(@fno,ch);
      end;
  end else begin
    writeln('Use "help topic". Available topics:');
    name:='*:H             ';
    drive:=0; entry:=0;
    repeat
      findentry(name,drive,entry,found,last);
      if found then begin
        i:=0;
        while (i<16) and (filnam[i]<>':') do begin
          write(filnam[i]);
          i:=i+1;
        end;
        writeln;
      end;
      entry:=entry+1;
    until last;
  end;
end.
