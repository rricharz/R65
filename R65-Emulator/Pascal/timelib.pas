
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal Library TIMELIB             *  }
{  *                                     *  }
{  ***************************************  }

{ 15/02/23 rricharz:                        }
{      returns time difference as real      }

library timelib;

var tenmillis,seconds,minutes,hours,
    difftenmillis: integer;

proc gettime;
{ get time from host system }
var dummy: integer;

  func getbcd0(address: integer): integer;
  { This function is available in syslib     }
  { But libraries cannot use other libraries }
  var data: integer;
  begin
    data:=mem[address];
    getbcd0:=data- 6*(data div 16);
  end;

begin
  { required to get date and time from host  }
  dummy:=getbcd0($17b9);
  { now get the data }
  tenmillis:=getbcd0($17b5);
  seconds:=getbcd0($17b6);
  minutes:=getbcd0($17b7);
  hours:=getbcd0($17b8);
end;

proc prttime(device: file);
{ print current time }

  proc write2digs(device: file; i:integer);
  begin
    if i<10 then write(@device,'0');
    write(@device,i);
  end;

begin
  gettime;
  write2digs(device,hours);
  write(@device,':');
  write2digs(device,minutes);
  write(@device,':');
  write2digs(device,seconds);
end;

func timediff: real;
{ time in seconds since last call to gettime, }
{ prttime, timediff or start of program       }
var lasttmillis,lastsec,lastmin,lasthrs: integer;
    value: real;
begin
  lasttmillis:=tenmillis;
  lastsec:=seconds;
  lastmin:=minutes;
  lasthrs:=hours;
  gettime;
  value:=conv(hours-lasthrs);
  if value<0.0 then value:=value+24.0;
  value:=60.0*value+conv(minutes-lastmin);
  value:=60.0*value+conv(seconds-lastsec);
  value:=value+conv(tenmillis-lasttmillis)/100.0
  timediff:=value;
end;

begin
  gettime;
end.