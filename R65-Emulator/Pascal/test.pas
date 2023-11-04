program test;
uses syslib,strlib;

const  cx='x';
       cy='yy';

var i: integer;
    s1,s2,s3,s4: cpnt;
    ch:char;
    res: array[2] of cpnt;
    stack: array[7] of packed char;

proc testcmp(t1,t2:cpnt);
var r: integer;
begin
  r:=strcmp(t1,t2);
  writeln(t1,  ' is ',  res[r+1],  t2);
end;

proc testpos(ch: char; pos:integer);
begin
  writeln('checkpos',  chr($27),  ch,  chr($27),
    ',',  chr($27),  s1,  chr($27),  ',',
    pos, '):',  strpos(ch,s1,pos));
end;

begin
  s1:=nil; s2:=nil; s3:=nil; s4:=nil;
  s1:=strnew; s2:=strnew; s3:=strnew;

  s1:='<testing>';
  writeln('s1: ',  s1);
  writeln('s1 is now a string constant');
  writeln('strlen(s1): ',  strlen(s1));
  strcpy(s1,s2,20);
  writeln('strcpy(s1,s2): s2=',s2);
  stradd(s1,s2);
  writeln('stradd(s1,s2): s2=',s2);
  stradd('<****>',s2);
  writeln('stradd(',  chr($27),
    '****',   chr($27) ,  ',s2): s2=',  s2);
  writeln;
  write(invvid,'Waiting, type any key ',norvid);
  read(@input,ch);

  res[0]:='smaller than ';
  res[1]:='equal to ';
  res[2]:='larger than ';
  testcmp('abcd','abcd');
  testcmp('abc','abcd');
  testcmp('abcd','abc');
  testcmp('abcx','abcd');
  testcmp('abcd','abcx');
  testcmp('axcd','abcd');
  testcmp('abcd','axcd');
  writeln;
  write(invvid,'Waiting, type any key ',norvid);
  read(@input,ch);

  writeln('Checking strpos in ', s1, ':');
  testpos('a',0);
  testpos('e',0);
  testpos('>',0);
  testpos('e',16);
  testpos('t',0);
  testpos('t',2);
  writeln;

  writeln('field size 3:');
  intstr(100,s3,3);   writeln(100,': ',tab8,s3);
  intstr(-20,s3,3);   writeln(-20,': ',tab8,s3);
  intstr(-300,s3,3);  writeln(-300,': ',tab8,s3);
  intstr(32767,s3,3); writeln(32767,': ',tab8,s3);
  intstr(0,s3,3);     writeln(0,': ',tab8,s3);

  repeat
    write('input?'); i:=strread(input,s3);
    writeln(i,  ' chars read, string=', s3);
    until i=0;
end.
 