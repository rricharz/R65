{ RANDOM ACCESS FILE LIBRARY             }
{ for R65 Pascal                         }
{                                        }
{ Original rricharz 1982                 }
{ Reconstructed rricharz 2019            }

library ralib;

const fread=$00;  {existing file, read}
      fwrite=$20; {existing file, write}
      fnew=$30;   {new file, write }

func uppercase(ch:char):char;
begin
  if (ch>='a') and (ch<='z') then
    uppercase:=chr(ord(ch)-32)
  else
    uppercase:=ch
end;

func attach(fname:array[15] of char;
  cyclus,drive,operation,size,start:integer;
  subtype:char):file;
{ open file for random access            }
{   operation fnew,fread,fwrite          }
{   var size in bytes (used for fnew,    }
{        returned for fread and fwrite)  }
mem maxsize=$0337: integer&;
    filsa=$031a:   integer;
    filstp=$0312:  char&;
    filflg =$00da: integer&;
    fildrv =$00dc: integer&;
    filnm1 =$0320: array[15] of char&;
    filcy1 =$0330: integer&;
var i:integer;
    f:file;
begin
  for i:=0 to 15 do
    filnm1[i]:=uppercase(fname[i]);
  filcy1:=cyclus; fildrv:=drive;
  filflg:=operation;
  maxsize:=1+((size-1) div 256);
  filsa:=start; filstp:=subtype;
  openb(f);
  attach:=f;
end;

func getsize:integer;
{ returns size of ra file in bytes      }
{ to be called after attach, and before }
{ any other io function is called       }
mem filsa=$031a:   integer;
    filea=$031c:   integer;
begin
  getsize:=filea-filsa+1;
end;

proc getword(device:file; address:integer;
  var word:integer);
var h,l:integer;
begin
  getbyte(device,2*address,l);
  getbyte(device,2*address+1,h);
  word:=(h shl 8) + l;
end;

proc putword(device:file; address:integer;
  word:integer);
begin
  putbyte(device,2*address, word and 255);
  putbyte(device,2*address+1, word shr 8);
end;

proc getreal(device:file; address:integer;
  var rvalue:array[1] of %integer);
var i1,i2:integer;
begin
  getword(device,2*address,i1);
  getword(device,2*address+1,i2);
  rvalue[0]:=i1;
  rvalue[1]:=i2;
end;

proc putreal(device:file; address:integer;
  rvalue:array[1] of %integer);
begin
  putword(device,2*address, rvalue[0]);
  putword(device,2*address+1, rvalue[1]);
end;

begin
end.

  