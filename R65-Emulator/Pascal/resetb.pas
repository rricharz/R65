{ ############################
  # resetb: clear breakpoint #
  ############################

  18.11.2023 rricharz                  }

program resetb;

mem brkpnt=$00c2: integer;

begin
  brkpnt:=0; { clear break point }
end. 