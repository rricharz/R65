program tail;
{ displays text file and ascii codes of last 4 chars }
{ stops at non printable character of text file }

uses syslib, arglib, wildlib;

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

proc show(ch:char);
begin
  write('<',ord(ch),'>');
  if (ord(ch)>32) then write(' ',ch)
  else if (ch = ' ') then write('blank')
  else if (ord(ch) = 13) then write(' EOL')
  else if (ord(ch) = 31) then write(' EOF');
  writeln;
end;

func check(ch: char): boolean;
{ return true if non printable character except CR }
begin
  check:= false;
  if (ch>=chr($20)) and (ch<=chr($7e)) then exit;
  if ch=CR then exit;
  check:=true;
end;

begin
  lastch4:=chr(0);
  lastch3:=chr(0);
  lastch2:=chr(0);
  lastch1:=chr(0);
  linecount:=0;
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);
  entry := 0;
  setsubtype('P');
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
    ch:='&';
    writeln('First characters');
    read(@fno,ch);
    show(ch);
    if (ch=EOF) then exit;
    read(@fno,ch);
    show(ch);
    if (ch=EOF) then exit;
    read(@fno,ch);
    while (ch<>EOF) do
    begin {main loop; while }
      if ch=CR then begin
        linecount := succ(linecount);
        writeln
      end else if check(ch) then begin
        { check for non printable character }
        writeln(INVVID, 'non printable character: <',
          ord(ch),'>',NORVID);
      end else write(ch);
      lastch4:=lastch3;
      lastch3:=lastch2;
      lastch2:=lastch1;
      lastch1:=ch;
      read(@fno,ch);
    end; { main loop while }
    writeln;
    writeln('tail characters:');
    show(lastch4);
    show(lastch3);
    show(lastch2);
    show(lastch1);
  end
  else writeln('usage: tail filnam');
end.
