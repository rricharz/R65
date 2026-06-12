{ RANDOM ACCESS FILE LIBRARY             }
{ for R65 Pascal                         }
{                                        }
{ Original rricharz 1982                 }
{ Reconstructed rricharz 2019            }

{$U+}

library ralib;

const FREAD   = $00;  {existing file, read}
      FWRITE  = $20;  {existing file, write}
      FNEW    = $30;  {new file, write }
      FSILENT = $40;
      { use e.g. FREAD+FSILENT for silent open }

func _uppercase(ch:char):char;
begin
  if (ch>='a') and (ch<='z') then
    _uppercase:=chr(ord(ch)-32)
  else
    _uppercase:=ch
end;

func _attach(fname:array[15] of char;
  cyclus,drive,operation,size,start:integer;
  subtype:char):file;
{ open file for _random access           }
{   operation FNEW,FREAD,FWRITE          }
{   var size in bytes (used for FNEW,    }
{        returned for FREAD and FWRITE)  }
mem maxsize=$0337: integer&;
    filsa=$031a:   integer;
    FILSTP=$0312:  char&;
    FILFLG =$00da: integer&;
    FILDRV =$00dc: integer&;
    FILNM1 =$0320: array[15] of char&;
    FILCY1 =$0330: integer&;
var i:integer;
    f:file;
begin
  for i:=0 to 15 do
    FILNM1[i]:=_uppercase(fname[i]);
  FILCY1:=cyclus; FILDRV:=drive;
  FILFLG:=operation;
  maxsize:=1+((size-1) div 256);
  filsa:=start; FILSTP:=subtype;
  openb(f);
  _attach:=f;
end;

func _getsize:integer;
{ returns size of ra file in bytes      }
{ to be called after _attach, and before }
{ any other io function is called       }
mem filsa=$031a:   integer;
    filea=$031c:   integer;
begin
  _getsize:=filea-filsa+1;
end;

proc _getword(device:file; address:integer;
  var word:integer);
var h,l:integer;
begin
  getbyte(device,2*address,l);
  getbyte(device,2*address+1,h);
  word:=(h shl 8) + l;
end;

proc _putword(device:file; address:integer;
  word:integer);
begin
  putbyte(device,2*address, word and 255);
  putbyte(device,2*address+1, word shr 8);
end;

proc _getreal(device:file; address:integer;
  var rvalue:array[1] of %integer);
var i1,i2:integer;
begin
  _getword(device,2*address,i1);
  _getword(device,2*address+1,i2);
  rvalue[0]:=i1;
  rvalue[1]:=i2;
end;

proc _putreal(device:file; address:integer;
  rvalue:array[1] of %integer);
begin
  _putword(device,2*address, rvalue[0]);
  _putword(device,2*address+1, rvalue[1]);
end;

begin
end.