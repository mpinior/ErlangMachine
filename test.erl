-module(test).
-compile([export_all]).

start() ->
   io:format("Wybierz napoj: "),
   Napoj = io:get_line(""),
   io:format("Ilosc cukru (0/1/2): "),
   CzyCukier = io:get_line(""),
   {NapojInt, _} = string:to_integer(Napoj),
   io:format("czy wypisuje ~n"),
   io:format("~w", [NapojInt]),
   {CukierInt, _} = string:to_integer(CzyCukier),
   io:format("~w", [CukierInt]).