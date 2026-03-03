program tail;
{ displays text file and last 3 chars as ascii codes }

uses syslib, arglib,wildlib;

const cup=chr($1a);
      clrlin=chr($17);

var cyclus,drive,entry,i,linecount: integer;
    found,last,default: boolean;
    ch, answer: char;
    name: array[15] of char;
    fno: file;
    lastch1,lastch2,lastch3,lastch4: char;

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
  agetstring(name,default,cyclus,drive);
  entry := 0;
  setsubtype('P');
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
    while (ch<>eof) and (ch<>chr(0)) do
    begin {main loop; while }
{     if ch=cr then begin
        linecount := succ(linecount);
        writeln;
      end
      else write(ch);  }
      lastch4:=lastch3;
      lastch3:=lastch2;
      lastch2:=lastch1;
      lastch1:=ch;
      read(@fno,ch);
    end; { main loop while }
    writeln;
    writeln('tail characters:');
    writeln('<',ord(lastch4),'>');
    writeln('<',ord(lastch3),'>');
    writeln('<',ord(lastch2),'>');
    writeln('<',ord(lastch1),'>');
    writeln('<',ord(ch),'>');
  end
  else writeln('usage: tail filnam');
end.
