{ maketable -                        }
{ make a table of real numbers for   }
{ display with graph                 }
{   fsize: number of real elements   }
{   fu: function used to make table  }
{                                    }
{   rricharz 2019 to test ralib      }

{ the example makes a fading   sine  }

program maketable;
uses syslib,ralib,mathlib;

const fsize=256;

var f:file;
    i,bsize:integer;
    fading:real;

func fu(i:integer):real;
var x:real;
begin
  x:=8.0*360.0*conv(i)/conv(fsize);
  fu:=sin(x)*fading;
  fading:=0.99*fading;
end;

begin

  fading:=1.0;

  f:=attach('TABLE:X         ',0,1,fnew,
    4*fsize,0,'X');
  bsize:=getsize;
  writeln('Table opened, bsize=',
    bsize,' bytes');

  for i:=0 to fsize-1 do begin
    write('.');
    putreal(f,i,fu(i));
  end;

  close(f);
  writeln;
  writeln('Table written');

end. 