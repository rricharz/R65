
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal LIBRARY ARGLIB              *  }
{  *                                     *  }
{  ***************************************  }

{      Version 07 01/08/82 rricharz         }
{      Recovered 2018 by rricharz           }

{ Allows to get arguments given by system   }
{ when a program is run.                    }

library arglib;

mem numarg=$5f:   integer&;
    arglist=$60:  array[3] of integer;
    arglists=$60: array[63] of char&;
    argtype=$a0:  array[31] of char&;

    filflg=$00da: integer&;
    fildrv=$00dc: integer&;
    filcyc=$0311: integer&;
    filcy1=$0330: integer&;
    filnam=$0301: array[15] of char&;
    filnm1=$0320: array[15] of char&;
    filstp=$0312: char&;

var carg: integer;

{       * argerror *        }

proc argerror(e: integer);

const stop=$2010;
mem runerr=$000c: integer&;
begin
    writeln;
    writeln('Argument error ',e);
    runerr:=255;
    call(stop)
end;

{       * agetval *          }

proc agetval(var value: integer;
  var default: boolean);
{ does not change value, if no argument }
begin
  case argtype[carg] of
    'i': begin value:=arglist[carg];
           carg:=succ(carg); default:=false;
         end;
    'd': begin
           carg:=succ(carg); default:=true;
         end;
    chr(0):
         begin
           default:=true;
         end
    else argerror(102)
  end {case}
end;

{       * agetstring *       }

proc agetstring(var string: array[15] of char;
  var default: boolean;
  var cyclus, drive: integer);
{ set string to blank if no argument }
var i: integer;
    dummy: boolean;

begin
  case argtype[carg] of
    's': begin
           for i:=0 to 15 do
             string[i]:=arglists[2*carg+i];
           carg:=carg+8;
           default:=false;
         end;
    'd': begin
           string:='                ';
           default:=true; carg:= succ(carg);
         end;
    chr(0):
         begin
           string:='                ';
           default:=true;
         end
    else argerror(101)
  end {case}
  agetval(cyclus,dummy);
  agetval(drive,dummy);
end;

{ * uppercase * }

func uppercase(ch1: char): char;

begin
  if (ch1 >= 'a') and (ch1 <= 'z') then
    uppercase := chr(ord(ch1) - 32)
  else
    uppercase := ch1;
end;

{       * asetfile *    }

proc asetfile(name: array[15] of char;
  cyclus,device: integer; subtype: char);

var i,e: integer;

begin
  e:=0;
  for i:=0 to 15 do begin
    filnam[i]:=uppercase(name[i]);
    filnm1[i]:=uppercase(name[i]);
    if (e=0) and ((name[i]=':')
        or (name[i]=' ')) then
      e:=i;
  end;
  if (subtype<>' ') and (e<>0)
      and (e<15) then begin
    filstp :=subtype;
    filnam[e]:=':'; filnm1[e]:=':';
    filnam[e+1]:=subtype; filnm1[e+1]:=subtype
  end;
  filcyc:=cyclus; filcy1:=cyclus;
  fildrv:=device;
  filflg:=$40; { Do not show file entry }
end;

{       * initialization *  }

begin
  carg:=0;
end.



