-module(nodo).
-export([start/0, start/2]). %%constructores
-export([setDatos/2, setHoja/1]). %%setters
-export([getDatos/1, getHoja/1]). %%getters
-export([nodoClase/4]). %%clase
-export([analizar/1, imprimir/1, descodificar/1]). %%metodos de clase

start() -> %%Constructor vacio
    Pid = spawn(fun init/0),
    Pid.

start(Datos, Dim) -> %%Constructor con datos y dimension
    Pid = spawn(?MODULE, nodoClase, [Datos, true, [], Dim]),
    Pid.

init() -> nodoClase([], true, [], nil).


setDatos(Nodo, Datos) ->
    Nodo ! {setDatos, Datos}.

setHoja(Nodo) ->
    Nodo ! setHoja.

getHoja(Nodo) ->
    Nodo ! {getHoja, self()},
    receive
        Valor -> Valor
    end.

getDatos(Nodo) ->
    Nodo ! {getDatos,self()},
    receive
        {ok, Datos} -> Datos
    end.

analizar(Nodo) ->
    Nodo ! {analizar,self()},
    receive
        {ok,ListaHijos} -> 
            ListaHijos;
        {error, fin_de_arbol} -> []
    end.

imprimir(Nodo) ->
    Nodo ! {imprimir,self()},
    receive
        Res -> Res
    end.

descodificar(Nodo) ->
    Nodo ! {descodificar, self()},
    receive
        Res -> Res
    end.

nodoClase(Datos, Hoja, Hijos, Dim) ->
    receive
        {setDatos, Datos} -> 
            nodoClase(Datos, Hoja, Hijos, Dim);
        setHoja ->
            Aux = array:to_list(Datos),
            Valor = sethoja(lists:map(fun(X) -> array:to_list(X) end, Aux)),
            nodoClase(Datos, Valor, Hijos, Dim);
        {getDatos, From} -> 
            From ! {ok, Datos},
            nodoClase(Datos, Hoja, Hijos, Dim);
        {getHoja, From} ->
            From ! Hoja,
            nodoClase(Datos, Hoja, Hijos, Dim);
        {analizar, From} ->
            if
                Hoja == false ->
                    Sep = trunc(Dim/2),
                    ArrayHijos = forji(0,0, Dim, Sep, Datos, lists:map(fun(_) -> array:new(Sep) end,[[],[],[],[]]), lists:map(fun(_) -> array:new(Sep) end, [[],[],[],[]])),
                    Cuad1 = spawn(?MODULE, nodoClase, [array:get(0,ArrayHijos), true, [], Sep]),
                    setHoja(Cuad1),
                    Cuad2 = spawn(?MODULE, nodoClase, [array:get(1,ArrayHijos), true, [], Sep]),
                    setHoja(Cuad2),
                    Cuad3 = spawn(?MODULE, nodoClase, [array:get(2,ArrayHijos), true, [], Sep]),
                    setHoja(Cuad3),
                    Cuad4 = spawn(?MODULE, nodoClase, [array:get(3,ArrayHijos), true, [], Sep]),
                    setHoja(Cuad4),
                    From ! {ok, [Cuad1,Cuad2,Cuad3,Cuad4]},
                    nodoClase(Datos, Hoja, [Cuad1,Cuad2,Cuad3,Cuad4], Dim);
                true ->
                    From ! {error, fin_de_arbol},
                    nodoClase(Datos, Hoja, Hijos, Dim)
            end;
         {imprimir, From} ->
            Res = imprimirArbol(array:get(0,Datos), Hijos, Hoja),
            From ! Res,
            nodoClase(Datos, Hoja, Hijos,Dim);
         {descodificar, From} ->
            Res = forijDesco(0,0,Hoja,Dim,Hijos,Datos,array:new(Dim),array:new(Dim)),
            From ! Res,
            nodoClase(Datos, Hoja, Hijos, Dim)
    end.

%% @doc sethoja/1, comprueba que todos los datos del nodo son iguales mediante list comprehension
sethoja(Datos) ->
    DatosPlanos = lists:flatten(Datos),
    lists:all(fun(X) -> X == 35 end, DatosPlanos) or lists:all(fun(X) -> X == 46 end, DatosPlanos).

imprimirArbol(Datos, Hijos, Hoja) ->
    case Hoja of
        true -> Res = array:get(0,Datos);
        false -> Res = "node"++ (lists:map(fun(X) -> imprimir(X) end, Hijos))
    end,
    lists:concat([[40],[Res],[41]]).

%%Emulamos un for anidado mediante recursividad para que se parezca a la version original en Java
forji(Inti, Intj, Dim, Sep, Datos,[C1,C2,C3,C4],[Ac1,Ac2,Ac3,Ac4]) ->
    case Inti < Dim of
        true ->
            Fila = array:get(Inti,Datos),
            case Intj < Dim of
                true -> 
                    Dato = array:get(Intj,Fila),
                    if 
                        (Inti < Sep) and (Intj < Sep) -> forji(Inti, Intj+1, Dim, Sep, Datos, [array:set(Intj,Dato,C1),C2,C3,C4] ,[Ac1,Ac2,Ac3,Ac4]);
                        (Inti < Sep) and (Intj >= Sep) -> forji(Inti, Intj+1, Dim, Sep, Datos, [C1, array:set(Intj rem Sep,Dato,C2),C3,C4],[Ac1,Ac2,Ac3,Ac4]);
                        (Inti >= Sep) and (Intj < Sep) -> forji(Inti, Intj+1, Dim, Sep, Datos, [C1,C2,array:set(Intj,Dato,C3),C4],[Ac1,Ac2,Ac3,Ac4]);
                        true -> forji(Inti, Intj+1, Dim, Sep, Datos, [C1,C2,C3,array:set(Intj rem Sep,Dato,C4)],[Ac1,Ac2,Ac3,Ac4])
                    end;
                false -> 
                        NuevosC = lists:map(fun(_) -> array:new(Sep) end, [[],[],[],[]]),
                        if
                            Inti < Sep -> forji(Inti+1,0,Dim,Sep,Datos,NuevosC, [array:set(Inti,C1,Ac1),array:set(Inti,C2,Ac2),Ac3,Ac4]);
                            true -> forji(Inti+1,0,Dim,Sep,Datos,NuevosC, [Ac1,Ac2,array:set(Inti rem Sep,C3,Ac3),array:set(Inti rem Sep,C4,Ac4)])
                        end
            end;
        false -> 
            Aux = array:new(4),
            guardarAcc(Aux,[Ac1,Ac2,Ac3,Ac4], 0)
    end.

guardarAcc(Aux,[],_) -> Aux;
guardarAcc(Aux,[H|T], Pos) ->
   guardarAcc(array:set(Pos,H,Aux),T,Pos+1).

forijDesco(Inti, Intj, Hoja, Dim,Hijos, Datos,Deco, DecoAcc)->
    case Hoja of
        true -> 
            case Inti < Dim of
                true ->
                    case Intj < Dim of
                        true ->
                            Fila = array:get(0,Datos),
                            Dato = array:get(0,Fila),
                            forijDesco(Inti, Intj+1,Hoja,Dim,Hijos,Datos,array:set(Intj,Dato,Deco),DecoAcc);
                        false -> forijDesco(Inti+1,0,Hoja,Dim,Hijos,Datos,array:new(Dim),array:set(Inti,Deco,DecoAcc))
                    end;
                false -> DecoAcc
            end;
        false ->
            C1 = nodo:descodificar(lists:nth(1,Hijos)),    
            C2 = nodo:descodificar(lists:nth(2,Hijos)),    
            C3 = nodo:descodificar(lists:nth(3,Hijos)),    
            C4 = nodo:descodificar(lists:nth(4,Hijos)),    
            componer(0,0,Dim,C1,C2,C3,C4,array:new(Dim),array:new(Dim))
    end.

componer(Inti,Intj,Dim,C1,C2,C3,C4,Res,ResAcc) ->
    Sep = trunc(Dim/2),
    case Inti < Dim of
        true ->
            case Intj < Dim of
                true ->
                    if
                        Inti < Sep -> Fila1 = array:get(Inti, C1), Fila2 = array:get(Inti, C2);
                        true -> Fila1 = array:get(Inti rem Sep, C3), Fila2 = array:get(Inti rem Sep, C4)
                    end,
                    if
                        (Inti<Sep) and (Intj<Sep) ->
                               componer(Inti,Intj+1,Dim,C1,C2,C3,C4,array:set(Intj, array:get(Intj,Fila1),Res),ResAcc);
                        (Inti<Sep) and (Intj>=Sep) -> componer(Inti,Intj+1,Dim,C1,C2,C3,C4,array:set(Intj, array:get(Intj rem Sep, Fila2),Res),ResAcc);
                        (Inti>=Sep) and (Intj<Sep) -> componer(Inti,Intj+1,Dim,C1,C2,C3,C4,array:set(Intj, array:get(Intj,Fila1),Res),ResAcc);
                        true -> componer(Inti,Intj+1,Dim,C1,C2,C3,C4,array:set(Intj,array:get(Intj rem Sep, Fila2),Res),ResAcc)
                    end;
                false ->
                    componer(Inti+1,0,Dim,C1,C2,C3,C4,array:new(Dim),array:set(Inti,Res,ResAcc))
            end;
        false ->  ResAcc
    end.
