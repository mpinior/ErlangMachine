-module(projekt).
-compile([export_all]).

%potrzebne do magazynu, przechowywane w krotce
%woda, kawa, mleko, herbata, cukier, cytryna 
initStanMagazynu() -> {1500, 500, 700, 500, 600, 30}.

%dla kazdego numeru wybiera się krotkę z składnikami jakich potrzebuje
%kawa czarna, kawa z mlekiem, cappuccino, herbata, mleko
%woda, kawa, mleko, herbata, cytryna
%cukier będzie dodane w trakcie ?
skladniki(Num) -> 
    element(Num,{
    { 5, 3, 0, 0, 0},
    { 4, 3, 1, 0, 0},
    { 3, 2, 2, 0, 0},
    { 5, 0, 0, 3, 1},
    { 0, 0, 5, 0, 0} 
    }).

%Wyświetlanie menu
menu() ->
    io:format("
            >--------(MENU)--------<
            _________________________
            | kawa czarna      - 1. |
            | kawa z mlekiem   - 2. |
            | cappuccino       - 3. |
            | herbata          - 4. |
            | mleko            - 5. |
            _________________________
Wybierz numer napoju: ").

%obsługa wejścia/wyjścia 
wejscie() ->
    receive
        {Id, init} ->
            timer:sleep(20),
            Id!{wejscieOk},
            wejscie();
        {Id, start} -> 
            menu(),
            Napoj = io:get_chars("", 1),
            Id!{Napoj},
            wejscie();
        {koniec} ->
            io:format("Napoj gotowy! Uwaga gorace. ~n");
        %tutaj trzeba chyba jeszcze rozważyć oddanie błędów? Czy coś takiego 
        {brakWody} ->
            io:format("Brak wody.  ~n"),
            wejscie();
        {brakKawy} ->
            io:format("Brak kawy.  ~n"),
            wejscie();
        {brakMleka} ->
            io:format("Brak mleka.  ~n"),
            wejscie();
        {brakHerbaty} ->
            io:format("Brak herbaty.  ~n"),
            wejscie();
        {brakCukru} ->
            io:format("Brak cukru.  ~n"),
            wejscie();
        {brakCytryny} ->
            io:format("Brak cytryny.  ~n"),
            wejscie()
    end.

procesor(WejscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId, KubekId) ->
    receive
        {init} ->
            WejscieId!{self(), init},
            procesor(WejscieId, MagazynId, CzajnikId,  BaristaId, PodgrzewaczId, DodatkiId, KubekId);
        {monitorOk} ->
            MagazynId!{self(), init},
            procesor(WejscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId, KubekId);
        {magazynOk} ->
            WejscieId!{self(), start},
            procesor(WejscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId, KubekId);
        %Magazyn ma zasoby na dany napoj 
        {magazynMaZasoby,Skladniki} ->
            UsedWoda = element(1,Skladniki),
            UsedKawa = element(2,Skladniki),
            UsedMleko = element(3,Skladniki),


            CzajnikId!{self(),gotujWode,UsedWoda},
            MlynekId!{self(),mielKawe,UsedKawa},
            PodgrzewaczId!{self(),grzejMleko,UsedMleko}

    end.




magazyn(Stan) ->
    %pobranie aktualnych zasobow produktow
    Woda = element(1, Stan),
    Kawa = element(2, Stan),
    Mleko = element(3, Stan),
    Herbata = element(4, Stan),
    Cukier = element(5, Stan),
    Cytryna = element(6, Stan),
    receive
        {Id, init} ->
            timer:sleep(20),
            Stan1 = initStanMagazynu(),
            Id!{magazynOk},
            magazyn(Stan1);
        {Id, stan} ->
            Id!{gotowe},
            magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna});
        {Id, napoj, NumerNapoju} ->
                %wyciaganie skladnikow danego napoju
                Skladniki = skladniki(NumerNapoju),
                UsedWoda = element(1,Skladniki),
                UsedKawa = element(2,Skladniki),
                UsedMleko = element(3,Skladniki),
                UsedHerbata = element(4,Skladniki),
                UsedCukier = element(5,Skladniki),
                UsedCytryna = element(6, Skladniki),
                
                %obliczanie ile zostanie po produkcji
                WodaLeft = Woda - UsedWoda,
                KawaLeft = Kawa - UsedKawa,
                MlekoLeft = Mleko - UsedMleko,
                HerbataLeft = Herbata - UsedHerbata,
                CukierLeft = Cukier - UsedCukier,
                CytrynaLeft = Cytryna - UsedCytryna,

                %jezeli jakiegos zasobu jest za malo do produkcji bedzie stosowny komunikat
                case WodaLeft<0 of
                    false -> null;
                    true -> Id!{brakWody},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                case KawaLeft<0 of
                    false -> null;
                    true -> Id!{brakKawy},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                case MlekoLeft<0 of
                    false -> null;
                    true -> Id!{brakMleka},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                case HerbataLeft<0 of
                    false -> null;
                    true -> Id!{brakHerbaty},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                case CukierLeft<0 of
                    false -> null;
                    true -> Id!{brakCukru},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                case CytrynaLeft<0 of
                    false -> null;
                    true -> Id!{brakCytryny},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Cytryna})
                end,

                %info do procesora, że mamy zasoby 
                Id!{magazynMaZasoby,{UsedWoda,UsedKawa,UsedMleko,UsedHerbata,UsedCukier, UsedCytryna}},
                %aktualizacja magazynu 
                magazyn({WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, CukierLeft, CytrynaLeft})
    end.