-module(main).
-export([main/6]).
-import(parser, [parser/1]).
-import(nodo, [start/1, analizar/1]).

main("",_,_,_,_,_) -> {error, file_text_not_found};
main(File, P, C, Pa, D, Pd) ->
    {Dim, Imagen} = parser:parser(File),
    Arbol = nodo:start(Imagen, Dim),
    nodo:setHoja(Arbol),
    comprobarP(P, Imagen, Dim),
    comprobarC(C, Arbol),
    comprobarPa(Pa, Arbol),
    Desc = comprobarD(D, Arbol),
    comprobarPd(Pd, Desc,Dim).

comprobarP(false,_,_) -> io:format("No se imprime el arbol ~n");
comprobarP(true, Arbol, Dim) -> for(0,0, Dim, Arbol).

comprobarC(false,_) -> io:format("No se codifica el arbol ~n");
comprobarC(true, Nodo) -> 
    ListaHijos = nodo:analizar(Nodo),
    if
        (length(ListaHijos) =:= 0) -> ok;
        true -> 
            lists:map(fun(X) -> comprobarC(true,X) end, ListaHijos)
    end.

comprobarPa(false,_) -> skipping_print_quad;
comprobarPa(true, Arbol) -> 
    Res = nodo:imprimir(Arbol),
    imprimir(Res), io:format("~n").

imprimir([]) -> io:format("");
imprimir([[]|T]) -> imprimir(T);
imprimir([H|T]) when is_list(H) ->
    imprimir(H), imprimir(T);
imprimir([H|T]) ->
    io:format("~c",[H]), imprimir(T);
imprimir(H) -> io:format("~c",[H]).

comprobarD(false,_) -> skipping_decode;
comprobarD(true, Arbol) -> 
   Res= nodo:descodificar(Arbol),
   Res.

comprobarPd(false,_,_) -> skipping_print_decode;
comprobarPd(true,Arbol,Dim) -> io:format("~nArbol descodificado:~n"),for(0,0,Dim, Arbol).

for(Inti, Intj, Dim, Imagen) ->
    case Inti < Dim of
        true ->
            Fila = array:get(Inti,Imagen),
            case Intj < Dim of
                true ->
                    Dato = array:get(Intj,Fila),
                    io:format("~c", [Dato]),
                    for(Inti,Intj+1,Dim,Imagen);
                false ->     
                    io:format("~n"),
                    for(Inti+1,0,Dim,Imagen)
            end;
        false ->
            io:format("~n")
    end.
