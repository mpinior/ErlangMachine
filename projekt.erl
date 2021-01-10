-module(projekt).
-compile([export_all]).

%potrzebne do magazynu, przechowywane w krotce
%woda, kawa, mleko, herbata, cukier, kubek  
initStanMagazynu() -> {1500, 500, 700, 500, 600, 400}.

%woda, kawa, mleko, cukier, kubek
procesySkonczone() -> [].

%dla kazdego numeru wybiera się krotkę z składnikami jakich potrzebuje
%kawa czarna, kawa z mlekiem, cappuccino, herbata, mleko
%woda, kawa, mleko, herbata
%cukru i kubka nie trzeba dodawać, kubek używa się za każdym razem, cukier tylko na życzenie 
skladniki(Num) -> 
    element(Num,{
    { 5, 3, 0, 0},
    { 4, 3, 1, 0},
    { 3, 2, 2, 0},
    { 5, 0, 0, 3},
    { 1, 2, 4, 0} 
    }).

%Wyświetlanie menu
menu() ->
    io:format("
            >*********(MENU)********<
            *************************
            * kawa czarna      - 1. *
            * kawa z mlekiem   - 2. *
            * cappuccino       - 3. *
            * herbata          - 4. *
            * latte            - 5. *
            *************************
-- Zakoncz dzialanie, wcisnij: k
-- Wyswietl aktualny stan magazynu, wcisnij: m
Wybierz numer napoju: ").
% Gotowe -> Kawiarka
% zakonczProcesy -> kawiarka
% DanieCukru -> Cukiernica
% daCukier -> cukiernica


%rozpoczecie 
start() ->
    Wejscie = spawn(projekt, wejscie, []),
    Magazyn = spawn(projekt, magazyn, [initStanMagazynu()]),
    % 5 procesów współbieżnych
    Czajnik = spawn(projekt, czajnik,[]),
    Mlynek = spawn(projekt, mlynek,[]),
    Podgrzewacz = spawn(projekt, podgrzewacz,[]),
    Kubek = spawn(projekt, kubek, []),
    Cukiernica = spawn(projekt, cukiernica, []),
    Herbaciarka = spawn(projekt, herbatka, []),

    Kawiarka = spawn(projekt, kawiarka,[procesySkonczone()]),
    Procesor = spawn(projekt, procesor, [Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka]),
    Procesor!{init}.

%obsługa wejścia/wyjścia 
wejscie() ->
    receive
        {Id, init} ->
            timer:sleep(20),
            Id!{wejscieOk},
            wejscie();
        {Id, start} -> 
            menu(),
            Napoj = io:get_line(""),
            case Napoj == "k\n" of
                false -> 
                    case Napoj == "m\n" of
                        false ->
                            CzyCukier = io:get_line("Ilosc cukru (0/1/2):"),
                            Id!{wybranieNapoju, Napoj, CzyCukier},
                            wejscie();
                        true ->
                            Id!{stanMagazynu},
                            wejscie()
                    end;
                true -> Id!{koniec}
            end;

        {przetwarzanie} ->
            io:format("Prosze czekac, trwa przetwarzanie zapytania ~n"),
            wejscie();
        {przygotowywyanie} ->
            io:format("Prosze czekac, trwa przygotowywanie napoju");
        {zakonczenie} ->
            io:format("Napoj gotowy! Uwaga gorace. ~n"),
            wejscie();
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
        {brakKubkow} ->
            io:format("Brak kubkow. Nie mozna przygotowac zadnego napoju. Przepraszamy za utrudnienia. ~n"),
            erlang:error("Zakonczenie dzialania. Przypadek krytyczny - brak kubkow")
    end.

procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka) ->
    receive
        {init} ->
            Wejscie!{self(), init},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz,Kubek, Cukiernica, Herbaciarka);
        {wejscieOk} ->
            Magazyn!{self(), init},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka);
        {magazynOk} ->
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka);
        {wybranieNapoju, Napoj, CzyCukier} ->
            %zamiana pobranego stringa na int
            %dlaczego tak: to_string zwraca krotkę, pierwszy element to zamieniona liczba, a drugi to reszta. 
            {NapojInt, _} = string:to_integer(Napoj),
            {CukierInt, _} = string:to_integer(CzyCukier),

            if is_integer(CukierInt) and is_integer(NapojInt) and (1 =< NapojInt andalso NapojInt =< 5) and (0 =< CukierInt andalso CukierInt =< 2) ->
                    %wyslanie info do magazynu
                    Magazyn!{self(), napoj, NapojInt, CukierInt, Wejscie},
                    Wejscie!{przetwarzanie},
                    procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka);
                true ->
                    io:format("~n UWAGA! ~n Podano bledne wartosci, zacznijmy od poczatku :) ~n Numery napojow: 1-5 ~n Ilosc kostek cukru: 0-2 ~n"),
                    Wejscie!{self(), start},
                    procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica, Herbaciarka)
            end;

        %Magazyn ma zasoby na dany napoj 
        {gotowyDoPracy, UsedCukier, UsedHerbata} ->
            Wejscie!{przygotowywanie},
            Czajnik!{self(),gotujWode},
            Kubek!{self(),dajKubek},
            if UsedHerbata == 3 -> Herbaciarka!{self(),wsypHerbate};
                true -> Mlynek!{self(),mielKawe},
                        Podgrzewacz!{self(),podgrzejMleko}
            end,
            if UsedCukier == 0 -> Kawiarka!{bezcukru};
                true -> Cukiernica!{self(), dajCukier}
            end,
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {woda, zagotowana} ->
            io:format("Nalewam wode...  ~n"),
            Kawiarka!{self(), woda},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {kawa, zmielona} ->
            io:format("Zmielono kawe...  ~n"),
            Kawiarka!{self(), kawa},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {mleko, podgrzane} ->
            io:format("Podgrzano mleko...  ~n"),
            Kawiarka!{self(), mleko},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {kubek, wystawiony} ->
            io:format("Wystawiono kubek...  ~n"),
            Kawiarka!{self(), kubek},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {cukier, wsypany} ->
            io:format("Wsypano cukier...  ~n"),
            Kawiarka!{self(), cukier},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {herbata, wsypana} ->
            io:format("Wsypano herbate...  ~n"),
            Kawiarka!{self(), herbata},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {gotowe} ->
            Kawiarka!{inicjalizacjaTab},
            Wejscie!{zakonczenie},
            timer:sleep(4000),
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {brakCzegos} ->
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {koniec} -> 
            exit(self(), "Koniec");
        {stanMagazynu} ->
            Magazyn!{self(), aktualnyStan},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka);
        {wyswietlonoAktualnyStan} ->
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Kawiarka, Podgrzewacz, Kubek, Cukiernica,Herbaciarka)
    end.

%opóźniamy proces działania czajnika, ponieważ woda się długo gotuje 
%ten etap w kazdym procesie jest inny, bo kazda rzecz trwa inaczej czasowo, np. kubek dostaje sie szybko, najdluzej gotuje sie woda
%przez to wydaje sie, ze procesy wykonuja sie synchronicznie, ale one dzialaja wspolnie, a dopiero przy "wydawaniu" kubka sa laczone, co daje zludzenie synchronicznosci
czajnik() ->
    receive
        {Id, gotujWode} ->
            timer:sleep(8000),
            Id!{woda,zagotowana},
            czajnik()
    end.

mlynek() ->
    receive
        {Id, mielKawe} ->
            timer:sleep(3000),
            Id!{kawa, zmielona},
            mlynek()
    end.

podgrzewacz() ->
    receive
        {Id, podgrzejMleko} ->
            timer:sleep(5000),
            Id!{mleko, podgrzane},
            podgrzewacz()
    end.

kubek()->
    receive
        {Id, dajKubek} ->
            timer:sleep(1000),
            Id!{kubek, wystawiony},
            kubek()
    end.

cukiernica() ->
    receive
        {Id, dajCukier} ->
            timer:sleep(2000),
            Id!{cukier, wsypany},
            cukiernica()
    end.

herbatka() ->
    receive
        {Id, wsypHerbate} ->
            timer:sleep(3000),
            Id!{herbata, wsypana},
            herbatka()
    end.

kawiarka(Tab) ->
    receive
        {inicjalizacjaTab} ->
            kawiarka(procesySkonczone());
        %herbata dodaje dwa, poniewaz nie uzywa mleka i kawy, a w innych procesach nie uzywa sie herbaty, dlatego moze zostac 5 procesow
        {Id, herbata} ->
            Tab1 = [1,1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1);
        {bezcukru} ->
            Tab1 = [1|Tab],
            kawiarka(Tab1);
        {Id, woda} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1);
        {Id, kawa} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1);
        {Id, mleko} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1);
        {Id, cukier} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1);
        {Id, kubek} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            kawiarka(Tab1)
    end.

magazyn(Stan) ->
    %pobranie aktualnych zasobow produktow
    Woda = element(1, Stan),
    Kawa = element(2, Stan),
    Mleko = element(3, Stan),
    Herbata = element(4, Stan),
    Cukier = element(5, Stan),
    Kubek = element(6, Stan),
    receive
        {Id, init} ->
            timer:sleep(20),
            Stan1 = initStanMagazynu(),
            Id!{magazynOk},
            magazyn(Stan1);
        {Id, stan} ->
            Id!{gotowe},
            magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek});
        {Id, aktualnyStan} ->
            io:format("Woda: ~p~n Kawa: ~p~n Mleko: ~p~n Herbata: ~p~n Cukier: ~p~n Kubek: ~p~n ~n", [Woda, Kawa, Mleko, Herbata, Cukier, Kubek]),
            Id!{wyswietlonoAktualnyStan},
            magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek});
        {Id, napoj, NumerNapoju, IloscCukru, Wejscie} ->
                %wyciaganie skladnikow danego napoju
                Skladniki = skladniki(NumerNapoju),
                UsedWoda = element(1,Skladniki),
                UsedKawa = element(2,Skladniki),
                UsedMleko = element(3,Skladniki),
                UsedHerbata = element(4,Skladniki),
                UsedCukier = IloscCukru, 
                UsedKubek = 1,
                
                %obliczanie ile zostanie po produkcji
                WodaLeft = Woda - UsedWoda,
                KawaLeft = Kawa - UsedKawa,
                MlekoLeft = Mleko - UsedMleko,
                HerbataLeft = Herbata - UsedHerbata,
                CukierLeft = Cukier - UsedCukier,
                KubekLeft = Kubek - UsedKubek,

                case WodaLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakWody},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case KawaLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakKawy},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case MlekoLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakMleka},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case HerbataLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakHerbaty},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                case CukierLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakCukru},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                case KubekLeft<0 of
                    false -> null;
                    true -> Wejscie!{brakKubkow},
                        timer:sleep(3000),
                        Id!{brakCzegos},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                %info do procesora, że mamy zasoby 
                Id!{gotowyDoPracy, UsedCukier, UsedHerbata},
                %aktualizacja magazynu
                magazyn({WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, CukierLeft, KubekLeft})
    end.

