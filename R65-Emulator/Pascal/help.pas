program help;

{ Display help files (*:H)                }
{ 2024-2026 rricharz                      }
{ usage: help topic                       }
{ where topic is the file name without :H }

uses syslib, arglib,wildlib;

const cup=chr($1a);
      clrlin=chr($17);

var cyclus,drive,entry,i,linecount: integer;
    found,last,default: boolean;
    ch, answer: char;
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
  linecount:=0;
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);
  entry := 0;
  setsubtype('H');
  _findentry(name,drive,entry,found,last);
  if not found then begin
    drive:=0; entry:=0;
    _findentry(name,drive,entry,found,last);
  end;
  if found then begin
    for i:=0 to 15 do
      name[i] := FILNAM[i];
    _asetfile(name,cyclus,drive,' ');
    write(cup); { avoid empty line }
    openr(fno);
    writeln; write(cup,clrlin);
    read(@fno,ch);
    while (ch<>EOF) and (ch<>chr(0)) do
    begin {main loop; while }
      if ch=CR then begin { end of line }
        linecount := succ(linecount);
        writeln;
      end { end of line }
      else write(ch);
      read(@fno,ch);
    end; { main loop while }
    writeln;
  end else begin { not fount }
    writeln
      ('Use "help topic". Available topics:');
    name:='*:H             ';
    drive:=0; entry:=0;
    repeat
      _findentry(name,drive,entry,found,last);
      if found then begin
        i:=0;
        while (i<16) and (FILNAM[i]<>':') do
        begin
          write(FILNAM[i]);
          i:=i+1;
        end;
        writeln;
      end;
    until last;
  end;
end.