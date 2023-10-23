library heaplib;
 
{ heap library for Pascal editor
  original 1980 RR
  rewritten 2023 RR for R65 system
 
  Very simple heap handling for R65 Pascal.
  All elements of the heap have the same size,
  as passed in startheap. The maximal number
  of entries is hard coded (maxlines)         }
 
const maxlines = 503;
 
var   linepnt: array[maxlines] of integer;
      relpnt,xmax:  integer;
 
func new:integer;
const stopcode = $2010;
mem   endstk = $000e: integer;
      runerr = $000c: integer&;
      sp     = $0008: integer;
begin
  if relpnt<maxlines-1 then begin
    relpnt:=relpnt+1; new:=linepnt[relpnt];
  end else begin
    endstk:=endstk-xmax;
    new:=endstk+144;
  end;
end;
 
proc release(p:integer);
begin
  linepnt[relpnt]:=p; relpnt:=relpnt-1;
end;
 
proc startheap(esize: integer);
begin
  relpnt:=maxlines-1;
  xmax:=esize;
end;
 
proc endheap;
const topmem = $c780;   {top of user memory}
mem   endstk =$000e: integer;
begin
  endstk := topmem - 144;
end;
 
begin
end.
 