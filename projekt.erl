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
    { 0, 0, 5, 0} 
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
            * mleko            - 5. *
            *************************
Zakoncz dzialanie, wcisnij: k
Wybierz numer napoju: ").

%rozpoczecie 
start() ->
    Wejscie = spawn(projekt, wejscie, []),
    Magazyn = spawn(projekt, magazyn, [initStanMagazynu()]),
    Czajnik = spawn(projekt, czajnik,[]),
    Mlynek = spawn(projekt, mlynek,[]),
    Gotowe = spawn(projekt, zakonczProcesy,[procesySkonczone()]),
    Podgrzewacz = spawn(projekt, podgrzewacz,[]),
    Kubek = spawn(projekt, kubek, []),
    DanieCukru = spawn(projekt, daCukier, []),
    Procesor = spawn(projekt, procesor, [Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru]),
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
            CzyCukier = io:get_line("Ilosc cukru (0/1/2):"),
            Id!{wybranieNapoju, Napoj, CzyCukier},
            wejscie();
        {przetwarzanie} ->
            io:format("Prosze czekac, trwa przygotowywanie napoju ~n"),
            wejscie();
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
        {brakCytryny} ->
            io:format("Brak cytryny.  ~n"),
            wejscie();
        {brakKubkow} ->
            io:format("Brak kubkow. Nie mozna przygotowac zadnego napoju. Przepraszamy za utrudnienia. ~n"),
            erlang:error("Zakonczenie dzialania. Przypadek krytyczny - brak kubkow"),
            wejscie()
    end.

procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru) ->
    receive
        {init} ->
            Wejscie!{self(), init},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz,Kubek, DanieCukru);
        {wejscieOk} ->
            Magazyn!{self(), init},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {magazynOk} ->
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {wybranieNapoju, Napoj, CzyCukier} ->
            Wejscie!{przetwarzanie},
            %zamiana pobranego stringa na int
            %dlaczego tak: to_string zwraca krotkę, pierwszy element to zamieniona liczba, a drugi to reszta. 
            {NapojInt, _} = string:to_integer(Napoj),
            {CukierInt, _} = string:to_integer(CzyCukier),
            %wyslanie info do magazynu
            Magazyn!{self(), napoj, NapojInt, CukierInt},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        %Magazyn ma zasoby na dany napoj 
        {gotowyDoPracy, UsedCukier} ->
            Czajnik!{self(),gotujWode},
            Mlynek!{self(),mielKawe},
            Podgrzewacz!{self(),podgrzejMleko},
            Kubek!{self(),dajKubek},
            if UsedCukier == 0 -> Gotowe!{bezcukru};
                true -> DanieCukru!{self(), dajCukier}
            end,
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {woda, zagotowana} ->
            io:format("Nalewam wode...  ~n"),
            Gotowe!{self(), woda},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {kawa, zmielona} ->
            io:format("Zmielono kawe...  ~n"),
            Gotowe!{self(), kawa},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {mleko, podgrzane} ->
            io:format("Podgrzano mleko...  ~n"),
            Gotowe!{self(), mleko},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {kubek, wystawiony} ->
            io:format("Wystawiono kubek...  ~n"),
            Gotowe!{self(), kubek},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {cukier, wsypany} ->
            io:format("Wsypano cukier...  ~n"),
            Gotowe!{self(), cukier},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {gotowe} ->
            Gotowe!{inicjalizacjaTab},
            Wejscie!{zakonczenie},
            timer:sleep(4000),
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {"k"} -> 
            exit(self(), "Koniec")
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

daCukier() ->
    receive
        {Id, dajCukier} ->
            timer:sleep(2000),
            Id!{cukier, wsypany},
            daCukier()
    end.

zakonczProcesy(Tab) ->
    receive
        {inicjalizacjaTab} ->
            zakonczProcesy(procesySkonczone());
        {bezcukru} ->
            Tab1 = [1|Tab],
            zakonczProcesy(Tab1);
        {Id, woda} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            zakonczProcesy(Tab1);
        {Id, kawa} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            zakonczProcesy(Tab1);
        {Id, mleko} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            zakonczProcesy(Tab1);
        {Id, cukier} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            zakonczProcesy(Tab1);
        {Id, kubek} ->
            Tab1 = [1|Tab],
            case Tab1 == [1,1,1,1,1] of
                    false -> null;
                    true -> Id!{gotowe}
            end,
            zakonczProcesy(Tab1)
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
        {Id, napoj, NumerNapoju, IloscCukru} ->
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
                    true -> Id!{brakWody},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case KawaLeft<0 of
                    false -> null;
                    true -> Id!{brakKawy},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case MlekoLeft<0 of
                    false -> null;
                    true -> Id!{brakMleka},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier,  Kubek})
                end,

                case HerbataLeft<0 of
                    false -> null;
                    true -> Id!{brakHerbaty},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                case CukierLeft<0 of
                    false -> null;
                    true -> Id!{brakCukru},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                case KubekLeft<0 of
                    false -> null;
                    true -> Id!{brakKubkow},
                        timer:sleep(3000),
                        Id!{gotowe},
                        magazyn({Woda, Kawa, Mleko, Herbata, Cukier, Kubek})
                end,

                %info do procesora, że mamy zasoby 
                Id!{gotowyDoPracy, UsedCukier},
                %aktualizacja magazynu
                magazyn({WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, CukierLeft, KubekLeft})
    end.