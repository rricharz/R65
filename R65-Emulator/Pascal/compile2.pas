
{   ********************************
    *                              *
    *  R65 "Tiny" Pascal Compiler  *
    *      Pass 2  (Loader)        *
    *                              *
    ********************************

First version 19978 by rricharz
Original version 3.1  01/08/82 rricharz

Recovered 2018 by rricharz (r77@bluewin.ch)

Original derived from the publication by
Kin-Man Chung and Herbert Yen in
Byte, Volume 3, Number 9 and Number 10, 1978

Adapted for the R65 computer system and
substantially enhanced by rricharz 1978-1982

usage:
 compile2 name[.cy[,drv]]
  [] means not required                    }

program compile2;
uses syslib,arglib,disklib;

const
    title='R65 PASCAL COMPILER Version 4.2, Pass 2';
    wrfile=$e81b;
    sblock=$5000;
    eblock=topmem;

mem endstk=$e,
    stprog=$11: integer;
    filerr=$db: integer&;
    filsa=$031a,
    filea=$031c,
    filsa1=$0331: integer;
    filtyp=$0300: char&;

var pointer,address,maxsize,dummy,
    scyclus,sdrive,offset,cdrive: integer;
    ch: char;
    source: file;
    stop,def: boolean;
    name: array[15] of char;


{ * error * }

proc error(x:integer);

mem runerr=$0c: integer&;

begin
  writeln;
  write('*** ');
  if x<100 then {file error, bcd}
    writeln('File error ',(x shr 4),(x and 15))
  else
    case x of
      101: writeln('Program too long');
      102: writeln('Data input format ',ch);
      105: writeln('Wrong address');
      106: writeln('Unexpected eof');
      107: writeln('Pointer not matching')
      else writeln('Unknown error ',x)
    end {case}
  close(source);
  runerr:=x;
  abort;
end {error};


{ * testerror * }

proc testerr;

var i: integer;

begin
  if filerr<>0 then error(filerr)
end;


{ * blocksave * }

proc blocksave(lowlim,highlim: integer);

var i: integer;

begin
  asetfile(name,scyclus,sdrive,'R');
  filsa:=lowlim;
  filea:=highlim;
  filsa1:=lowlim;
  filtyp:='B';
  call(wrfile);
  testerr
end {blocksave};


{ * init * }

proc init; {initialize program}

var i: integer;
    default: boolean;

begin
  cdrive:=fildrv; { drive of compile program }
  endstk:=sblock-144;   {reserve memory }
  writeln;
  writeln(title);
  scyclus:=0; sdrive:=1;
  agetstring(name,default,scyclus,sdrive);
  asetfile(name,scyclus,sdrive,'Q');
  openr(source);
  writeln;
  scyclus:=filcyc;
end {init};


{ * getbyte1 * }

func getbyte1: integer;

var byte: integer;

begin
  if (ch<'0') or (ch>'@') then error(102);
  byte:=(ord(ch) and 15) shl 4;
  read(@source,ch);
  if (ch<'0') or (ch>'@') then error(102);
  byte:=byte + ((ord(ch) and 15));
  getbyte1:=byte;
  { heartbeat: }
  if (pointer and 63)=0 then write('.');
end {getbyte1};


{ * getbyte2 * }

func getbyte2: integer;
begin
  read(@source,ch); getbyte2:=getbyte1
end {getbyte2};


{ * getbl * }

proc getbl(base:integer);  {get block }

  proc getlib; {get library }

  var i: integer;
      savsr: file;
      ch1: char;
      lname: array[7] of char;
      lcyclus,ldrive: integer;

  begin
    savsr:=source;
    for i:=0 to 7 do begin
      read(@source,ch1);
      lname[i]:=ch1
    end;
    lcyclus:=0; ldrive:=cdrive;
    write('Loading library ');
    prtext8(output,lname);
    { loading library from same drive }
    { as program compile2 }
    asetfile(lname&'        ',
      lcyclus,ldrive,'T');
    openr(source);
    getbl(offset-2);
    close(source);
    source:=savsr;
    if (pointer+4-sblock)>maxsize then
      error(101);
    mem[pointer-1]:=43;
    mem[pointer]:=0;
    mem[pointer+1]:=3;
    mem[pointer+2]:=0;
    mem[pointer+3]:=0;
    pointer:=pointer+4;
    offset:=pointer-sblock;
    writeln;
    writeln('Library loaded')
  end {getlib};


begin { * body of getbl * }
  stop:=false;
  repeat
    read(@source,ch);
    case ch of

      'F':  begin {fixup}
              address:=getbyte2+
                  (getbyte2 shl 8)+offset;
              if (address<offset) or
                  (address>maxsize) then begin
                writeln;
                write(address,' ',offset);
                error(105);
              end;
              mem[address+sblock]:=getbyte2;
              mem[address+sblock+1]:=getbyte2;
            end {fixup};

      'L':  getlib;

      'E':  stop:=true;

      eof:  error(106)

      else begin {data}
        mem[pointer]:=getbyte1;
        pointer:=pointer+1;
        if (pointer-sblock)>maxsize then
          error(101);
      end {data}
    end {case};
  until stop;
  stop:=false;
  mem[sblock]:=(pointer-sblock) and 255;
  mem[sblock+1]:=(pointer-sblock) shr 8;
  address:=getbyte2+(getbyte2 shl 8)+base;
  if address<>(pointer-sblock) then begin
    writeln(address,' ',pointer-sblock);
    error(107)
  end
end {getbl};


{ * main * }

begin {main}
  init; maxsize:=eblock-sblock-2;
  pointer:=sblock+2; offset:=2;
  getbl(0);
  mem[pointer-1]:=0;
  mem[pointer]:=255;
  mem[pointer+1]:=255;
  pointer:=pointer+1;
  close(source);
  writeln;
  blocksave(sblock,pointer);
  writeln('Program has been stored');
  endstk:=topmem-144;
  dummy:=freedsk(sdrive,true);
end.
