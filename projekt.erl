-module(projekt).
-compile([export_all]).

%potrzebne do magazynu, przechowywane w krotce
%woda, kawa, mleko, herbata, cukier, kubek  
initStanMagazynu() -> {1500, 500, 700, 500, 600, 400}.

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
            >--------(MENU)--------<
            _________________________
            | kawa czarna      - 1. |
            | kawa z mlekiem   - 2. |
            | cappuccino       - 3. |
            | herbata          - 4. |
            | mleko            - 5. |
            _________________________
Zakoncz dzialanie, wcisnij: k
Wybierz numer napoju: ").

%rozpoczecie 
start() ->
    Wejscie = spawn(projekt, wejscie, []),
    Magazyn = spawn(projekt, magazyn, [initStanMagazynu()]),
    Czajnik = spawn(projekt, czajnik,[]),
    Mlynek = spawn(projekt, mlynek,[]),
    Gotowe = spawn(projekt, zakonczProcesy,[]),
    Podgrzewacz = spawn(projekt, podgrzewacz,[]),
    Kubek = spawn(projekt, kubek, []),
    DanieCukru = spawn(projekt, dajCukier, []),
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
            Id!{Napoj, CzyCukier},
            wejscie();
        {przetwarzanie} ->
            io:format("Prosze czekac, trwa przygotowywanie napoju ~n");
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
            wejscie();
        {brakKubkow} ->
            io:format("Brak kubkow. Nie mozna przygotowac zadnego napoju. Przepraszamy za utrudnienia. ~n"),
            erlang:error("Zakonczenie dzialania. Przypadek krytyczny - brak kubkow")
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
        {Napoj, CzyCukier} ->
            Wejscie!{przetwarzanie},
            %zamiana pobranego stringa na int
            %dlaczego tak: to_string zwraca krotkę, pierwszy element to zamieniona liczba, a drugi to reszta. 
            {NapojInt, _} = string:to_integer(Napoj),
            {CukierInt, _} = string:to_integer(CzyCukier),
            %wyslanie info do magazynu
            Magazyn!{self(), napoj, NapojInt, CukierInt};
        %Magazyn ma zasoby na dany napoj 
        {magazynMaZasoby} ->
            Czajnik!{self(),gotujWode},
            Mlynek!{self(),mielKawe},
            %podgrzewalabym mleko tylko kiedy trzeba uzyc mleka, da sie to zrobic, ale chyba braknie wtedy wspolbieznych?
            Podgrzewacz!{self(),podgrzejMleko},
            Kubek!{self(),dajKubek},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {woda, zagotowana} ->
            Gotowe!{self(), woda},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {kawa, zmielona} ->
            Gotowe!{self(), kawa},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {mleko, podgrzane} ->
            Gotowe!{self(), mleko},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {kubek, wystawiony} ->
            Gotowe!{self(), kubek},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {cukier, wsypany} ->
            Gotowe!{self(), cukier},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru);
        {gotowe} ->
            Wejscie!{koniec},
            timer:sleep(4000),
            Wejscie!{self(), start},
            procesor(Wejscie, Magazyn, Czajnik, Mlynek, Gotowe, Podgrzewacz, Kubek, DanieCukru)
    end.

%opóźniamy proces działania czajnika, ponieważ woda się długo gotuje 
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
            mlynek()
    end.

kubek()->
    receive
        {Id, dajKubek} ->
            timer:sleep(1000),
            Id!{kubek, wystawiony},
            mlynek()
    end.

dajCukier() ->
    receive
        {Id, dajCukier} ->
            timer:sleep(2000),
            Id!{cukier, wsypany},
            dajCukier()
    end.

%łączenie wykonywania wszystkich czynności
zakonczProcesy() ->
    receive
        {Id,kubek} ->
            receive
                {Id, cukier} ->
                    receive
                        {Id, kawa} ->
                            receive
                                {Id, mleko} ->
                                    receive
                                        {Id, woda} ->
                                            Id!{gotowe},
                                            zakonczProcesy()
                                    end
                            end
                    end
            end
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

                %jezeli jakiegos zasobu jest za malo do produkcji bedzie stosowny komunikat
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
                Id!{magazynMaZasoby},
                %aktualizacja magazynu 
                magazyn({WodaLeft, KawaLeft, MlekoLeft, HerbataLeft, CukierLeft, KubekLeft})
    end.