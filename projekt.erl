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
            io:format("Brak wody.  ~n");
        {brakKawy} ->
            io:format("Brak kawy.  ~n");
        {brakMleka} ->
            io:format("Brak mleka.  ~n");
        {brakHerbaty} ->
            io:format("Brak herbaty.  ~n");
        {brakCukru} ->
            io:format("Brak cukru.  ~n");
        {brakCytryny} ->
            io:format("Brak cytryny.  ~n")
    end.

procesor(WejscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId) ->
    receive
        {init} ->
            WyjscieId!{self(), init},
            procesor(WyjscieId, MagazynId, CzajnikId,  BaristaId, PodgrzewaczId, DodatkiId);
        {monitorOk} ->
            MagazynId!{self(), init},
            procesor(WyjscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId);
        {magazynOk} ->
            WyjscieId!{self(), start},
            procesor(WyjscieId, MagazynId, CzajnikId, BaristaId, PodgrzewaczId, DodatkiId).
        %Magazyn ma zasoby na dany napoj 



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
            Id!{[Stan], komunikat,komunikatLine()},
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

                %Wyswietlamy stan produktow
                % bardziej zeby pokazac ze magayn dziala- klient nie ma potrzeby wiedziec ile surowcow zostalo w magazynie
                % w klienckiej wersji mozna 2ponizsze linie zakomentowac
                Id!{etykieta,stanProduktowLine(),"Stan: "},
                Id!{zmienna,stanProduktowLine(),{WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, KakaoLeft}},
                %raportujemy JednostceCentralnej ze mamy potrzebne zasoby
                Id!{magazynMaZasoby,{UsedWoda,UsedKawa,UsedMleko,UsedHerbata,UsedKakao}},
                %aktualizacja stanu magazynu
                magazyn({WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, KakaoLeft})
    end.