

function Resultados = BlinkAlgorithm ( data , inicio , timethreshold)

   

    persistent centroides;
    persistent primero; 

   
    %Data is the signal to be processed. Anytime inicio is set to 1, the
    %centroides are reset. The third parameter sets the time threshold to
    %distiguish between short- long- blinks.
    
    
    Resultados.signal = data;
    if nargin>1
        if inicio==1
            primero=[];
        end
        
        timethreshold=[];
    end
    Fs=512;
    
    
    if isempty(primero)
     	[Resultados.Centroides Resultados.Clas] = Clasificador(Resultados.signal);
        primero=1;
    else
     	[Resultados.Centroides Resultados.Clas] = Clasificador(Resultados.signal,centroides);
    end
    centroides = Resultados.Centroides(end,:);
    [Resultados.pulses Resultados.longitud Resultados.posmax]  = Pulsos(Resultados.Clas,Resultados.signal);
    [Resultados.events Resultados.tiempo ] = Eventos(Resultados.pulses,Fs);


end


%Filtro paso de baja
%Devuelve dos  salidas, la primera utiliza coeficientes redondeados. Apropiada
%para programar en Arduino. La segunda los coeficientes sin redondear. 
%nume representa los coeficientes del filtro.

% function [salida] = filtropb(entrada)
% 
% 
% Fs = 250; %Frecuencia de muestreo
% F = 100 ; %Frecuencia a eliminar
% 
% 
% f = F/Fs;
% 
% %Creamos ceros y polos
% %Número de polos y ceros
% 
% z = exp(2*pi*f*i); 
% p = 0*z;
% 
% num=3;den=1;
% %Multiplicamos
% Npz=	2;
% for n=1:Npz
% 	temp = conv([1 -z],[1 -z']);
% 	num=conv(num,temp);
% 	temp=conv([1 -p], [1 -p']);
% 	den=conv(den, temp);
% end
% 
% 
% salida = filter(num/sum(num),den,entrada);
% 
% 
% end

function [Centroide Clasificador]=Clasificador(datos,centroides);

	if nargin < 2
		centroides =[ -400 0 400];
	end

	N = length(datos);

	%centroides= [2 0 4];
	for n=1:N;
		distancia = abs(centroides-datos(n));
		[valor pos]= min(distancia);
	
		%Modo normal
		if valor > 0
				centroides(pos) = centroides(pos)*127 + datos(n);
				centroides(pos)=centroides(pos)/128;
        end
		Centroide(n,1:3) = centroides;
		Clasificador(n) = pos;
	 end
end



function [out longitud posicionmaximo] = Pulsos(in,signal)
    N=-1;
    P=1;
    contador=0;
    waves=1;
	estado=0;
	L=length(in);
    longitud(waves)=0;
    LonWaves=14;
    posicionmaximo=[];
    maximo=0;
	for n=1:L
		out(n)=0;
 		switch(estado)
		case 0
			if( in(n) ~= 2)
				contador = contador +in(n)-2;
				estado = 1; 
                longitud(waves)=longitud(waves)+1;  %Para determinar la longitud de los pulsos
                if abs(signal(n)  ) > maximo
                        maximo =abs(signal(n) );
                    posmax = n;
                end
            end
		case 1
			if (in(n) ~= 2)
				contador = contador + in(n) -2;
                longitud(waves)=longitud(waves)+1;  %Para determinar la longitud de los pulsos
                if abs(signal(n)  ) > maximo
                    maximo =abs(signal(n) );
                    posmax = n;
                end
            else
                if (contador <= 0)
                    if longitud(waves)>=LonWaves
                        longitud(waves) = -longitud(waves);
                        posicionmaximo(waves) = posmax;
                        out(posmax)=N;
                        waves=waves+1;
                    end
                else
                    if longitud(waves)>=LonWaves
                        out(posmax)=P;
                        posicionmaximo(waves) = posmax;
                        waves=waves+1;
                    end
                end
                contador=0;
                estado=0;
                maximo=0;
                longitud(waves)=0;
			end
		end
	end
end


function [out tiem1] = Eventos(in, Fs, umbral)
    Blink=1;
    Wink = 2;
   
    P=1;
    N=-1;
%   Tparpadeo = 0.4*Fs;
    if nargin==3
        Tparpadeo = umbral
    else
        Tparpadeo = 120;
    end
    
    Timeout = Fs/2;
    
	estado = 0;
	L=length(in);
    tiempo=0;
    tiempo2=0;
    tiem1=[];

    
 
    Neventos=0;
  
    
   %Results based on the method of looking for the maximum position
	for n=1:L
		out(n)=0;
 		switch(estado)
		case 0 
			if(in(n) == P)
				estado =1;
				tiempo = 0;
			end
		case 1
			tiempo=tiempo+1;
			if in(n) == P
				tiempo=0;
			end
			if in(n) == N
				estado=2;
                tiempo2=0;
            end
         case 2
             tiempo2=tiempo2+1;
             if in(n) == N
                 tiempo = tiempo+tiempo2;
                 tiempo2=0;
             end
             
             if in(n) == P
                 estado=1;
                 tiempo=0;
                 out(n) = Blink;
                 Neventos=Neventos+1;
                 tiem1(Neventos,1) = tiempo;
                 tiem1(Neventos,2) = n-tiempo2;
             end
             
             if tiempo2>Timeout
                 if tiempo < Tparpadeo
                     out(n) = Blink;
                 else
                     out(n) = Wink;
                 end
                estado=0;
                    Neventos=Neventos+1;
                    tiem1(Neventos,1) = tiempo;
                    tiem1(Neventos,2) = n-tiempo2;
            end
             
        end

    end
    

%     for n=1:L
%         switch estado
%             case 0
%                 if in(n) == P
%                     tiempo=0;
%                     estado=1;
%                 end
%                 
%             case 1
%                 tiempo=tiempo+1;
%                 if(in(n) == P)
%                     tiempo=0;
%                 end
%                 if(in(n) == P)
%                     Neventos=Neventos+1;
%                     tiem1(Neventos,1) = tiempo;
%                     tiem1(Neventos,2) = n;
%                     tiempo=0;
%                 end
% 
%         end
%         
%     end
    
    
end
