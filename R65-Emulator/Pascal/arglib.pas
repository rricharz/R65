
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal LIBRARY ARGLIB              *  }
{  *                                     *  }
{  ***************************************  }

{      Version 07 01/08/82 rricharz         }
{      Recovered 2018 by rricharz           }

{ gets arguments given to app               }
{ prepares system disk io                   }


library arglib;

mem
    NUMARG   = $005f: integer&;
    ARGLIST  = $0060: array[10] of integer;
    ARGLISTS = $0060: array[63] of char&;
    ARGTYPE  = $00a0: array[31] of char&;
    FILFLG   = $00da: integer&;
    FILDRV   = $00dc: integer&;
    FILCYC   = $0311: integer&;
    FILCY1   = $0330: integer&;
    FILNAM   = 0301: array[15] of char&;
    FILNM1   = $0320: array[15] of char&;
    FILSTP   = $0312: char&;

var _carg: integer;

proc _argerror(e: integer);
{ display argument error e and stops app }
const STOP=$2010;
mem RUNERR=$000c: integer&;
begin
    writeln;
    writeln('Argument error ',e);
    RUNERR:=255;
    call(STOP)
end;

proc _agetval(var value:integer;
        var default:boolean);
{ get integer argument }
{ does not change value, if no argument }
begin
  case ARGTYPE[_carg] of
    'i': begin value:=ARGLIST[_carg];
           _carg:=succ(_carg); default:=false;
         end;
    'd': begin
           _carg:=succ(_carg); default:=true;
         end;
    chr(0):
         begin
           default:=true;
         end
    else _argerror(102)
  end {case}
end;

proc _agetstring(var string: array[15] of char;
        var default: boolean;
        var cyclus, drive: integer);
{ get string argument }
{ set string to blank if no argument }
var i: integer;
    dummy: boolean;
begin
  case ARGTYPE[_carg] of
    's': begin
           for i:=0 to 15 do
             string[i]:=ARGLISTS[2 *_carg + i];
           _carg:=_carg + 8;
           default:=false;
         end;
    'd': begin
           string:='                ';
           default:=true; _carg:= succ(_carg);
         end;
    chr(0):
         begin
           string:='                ';
           default:=true;
         end
    else _argerror(101)
  end {case}
  _agetval(cyclus,dummy);
  _agetval(drive,dummy);
end;

begin
  _carg:=0;
end.



