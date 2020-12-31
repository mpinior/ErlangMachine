-module(test).
-compile([export_all]).

start() ->
   Tab = [1,1,1,1,1],
   case Tab == [1,1,1,1,1] of
                    false -> ("fałsz");
                    true -> io:format("Prawda")
   end.