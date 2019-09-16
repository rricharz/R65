
{  ***************************************  }
{  *                                     *  }
{  *  R65 Computer System                *  }
{  *  Pascal Library TIMELIB             *  }
{  *                                     *  }
{  ***************************************  }

library timelib;

var seconds,minutes,hours: integer;

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

func timediff: integer;
{ time in seconds since last call to gettime, }
{ prttime, timediff or start of program       }
{ returns -1 if time difference is too large  }
var lastsec,lastmin,lasthrs,value: integer;
begin
  lastsec:=seconds;
  lastmin:=minutes;
  lasthrs:=hours;
  gettime;
  value:=hours-lasthrs;
  if value<0 then value:=value+24;
  value:=60*value+minutes-lastmin;
  if (value>546) then { overflow }
    value:=-1
  else
    value:=60*value+seconds-lastsec;
  timediff:=value;
end;

begin
  gettime;
end.