function [c] = syncAudio(videoIN, audioIN, FsIN, fileOutput, toll)

%syncAudio Questa funzione salva un file audio sicronizzato con un'altra traccia 
%                 audio proveniente da un file video.
%
%   [c] = syncAudio(video, audio, FsIN, fileOutput)
%
%   video       =   video master input
%   audio       =   audio slave from secondary audio track
%   FsIN        =   frequency
%   fileOutput  =   destination of final audio track  
%   toll        =   tollerance (in seconds)
%
%   IMPORTANTE: i file di input devono avere la stessa frequenza di campionamento FsIN!
%
%   Copyright 2017 Giuseppe Gullotta e Liliana Scaffidi.
%   Questo codice è stato realizzato per il corso di Elaborazione dell'audio digitale
%   presso il Politecnico di Torino.
%
%   Non sappiamo se questo codice funiona con tutti i tipi di file audio e video 
%   però proveremo a correggere qualsiasi problema riscontrato in futuro.
%
%   Abbiamo qui preferito utilizzare direttamente un'unica funzione per l'intero processo 
%   (anzichè più funzioni richiamate esternamente) per ottimizzare il codice a livello computazionale.
%
%   LIMITI:   --> DRIFT: funziona solamente se la traccia audio è il ritardo rispetto a quella video
%             --> GAP: riesce a rilevare soltanto i vuoti dovuti al silenzio
%         


% START 
fprintf('--------------\n');
fprintf('START\n')
fprintf('--------------\n');

% Ricerca della dimensione della finestra di osservazone dei file in input 
fprintf('Read audio file\n')
audio = audioread(audioIN);
infoAudio = audioinfo(audioIN);

fprintf('Read video file\n')
infoVideo = audioinfo(videoIN);
video = audioread(videoIN);

fprintf('--------------\n')

minSamples = min(infoAudio.TotalSamples, infoVideo.TotalSamples);

% Ricerca se i file audio hanno durata maggiore di un'ora
% window_length è per la parte relativa alla sincronizzazione
% window_second viene utilizzata per la deriva
if minSamples < 3600 * FsIN         % 60 minuti
    window_length = 30;             % 30 secondi
    window_second = 5;              % 5 secondi
else
    window_length = 60;             % 60 secondi
    window_second = 10;             % 10 secondi
end

% Ricerca della finestra di sincronizzazione
flag = 0;                   
n = 0;                      % contatore
toll = FsIN * toll;         % tolleranza (in samples)
tAV_old = 0;                % variabile temporanea
window_start = 1;           % valore di inizio intervallo di analisi

% Inizo ricerca
fprintf('ANALISYS FILES\n')

while flag == 0

    window_end = FsIN * window_length * (n+1);
    
    
    % Cross-Correlazione 
    [AV, lagAV] = xcorr(audio(window_start:window_end), video(window_start:window_end));
    AV = AV/max(AV);

    [~, IAV] = max(AV);

    % Differenza, in campioni, tra le tracce 
    tAV = lagAV(IAV);
    
    % Stampa a video i risultati dell'analisi
    fprintf('Segment %d  |  IN: %d  |  OUT: %d  -->  %d\n', n, window_start, window_end, tAV);
    
    % Controlla se il segmento trovato è minore della tolleranza
    % Se è minore, il delay è stato trovato
    if abs(tAV - tAV_old) <= toll
        flag = 1;
        % Preferiamo utilizzare la successiva window_end (quindi maggiorata di 1) per un migliore risultato
        % Da implementare: se tAV_old = 0 il sincronismo è già nel primo segmento
        segment = [window_start, FsIN * window_length * (n+2)];    
    end
    
    tAV_old = tAV; 
    n = n + 1;
    
    % Controlla se la successiva finestra di osservazione è più grande della lunghezza del minore tra i file audio o video 
    if FsIN * window_length * (n+2) > infoAudio.TotalSamples || FsIN * window_length * (n+2) > infoVideo.TotalSamples
        error('Sync not found!');
    end

end

% Stampa la finestra di analisi
fprintf('--------------\n');
fprintf('Sync founded between %d and %d samples\n', segment(1), segment(2));
fprintf('--------------\n');

% Inizio ricerca finestra di sincronizzazione
fprintf('SYNC FILES\n')


% Cross-Correlazione 
[AV, lagAV] = xcorr(audio(segment(1):segment(2)), video(segment(1):segment(2)));
AV = AV/max(AV);

[~, IAV] = max(AV);

% Differenza, in campioni, tra le tracce 
tAV = lagAV(IAV);

% Stampa il ritardo sia in campioni che in secondi
fprintf('Delay: %d samples\n', tAV);
fprintf('Delay: %d seconds\n',tAV/FsIN);

% Ritorna tAV
c = tAV;


% Inizio sincronizzazione
y = audio;

% Se tAV > 0 taglia la prima parte dell'audio
% altrimenti aggiunge silenzio all'inizio dell'audio
if tAV >= 0
    audioCut = y(tAV:end);
else
    h = zeros(-tAV, 1);
    audioCut = vertcat(h, y);
end


fprintf('--------------\n');

% Inizio analisi deriva 
fprintf('DRIFT ANALISYS\n')

% Creazione nuovo array per la deriva
minSamples = min(length(audioCut), infoVideo.TotalSamples);
sizeDrift = round(minSamples/(FsIN * window_second)) - 1;
drift = zeros(sizeDrift, 1);

% Prima finestra 
window_start = 1;
window_end = FsIN * window_second;

n = 1;  % contatore

h = waitbar(0, 'Drift Analisys...');

while window_end < minSamples
    
    % Cross-Correlazione
    [AV, lagAV] = xcorr(audioCut(window_start:window_end), video(window_start:window_end));
    AV = AV/max(AV);

    [~, IAV] = max(AV);

    % Differenza, in campioni, tra le tracce 
    drift(n) = lagAV(IAV);
    
    % Valori deriva
    % fprintf('%d |  IN: %d OUT: %d  \t | \t Drift(%d) = %d \t|\n', n, window_start, window_end, n, drift(n));

    % Aggiornamento finestra 
    window_start = window_end + 1;
    window_end = (window_start - 1) + FsIN * window_second;
    n = n + 1;
    
    waitbar(n / sizeDrift);
    
end

close(h);

% Plot deriva
fprintf('--------------\n')
fprintf('PLOTTING DRIFT\n')

t_drift = (0 : FsIN * window_second : FsIN * (n-2) * window_second) / FsIN;

plot(t_drift, drift)
ylabel('video (s)');
xlabel('audio (s)');
title('DRIFT')

fprintf('--------------\n')

% Correzione dei gap
fprintf('CORRECTION AUDIO GAPS\n')

tollSamp = 0.02;                % 20 ms tolleranza
tollGap = tollSamp * FsIN;      % Tolleranza in campioni

offset = 0;
flag = true;

for n = 2 : length(drift)
    
    % Ricerca differenza tra derive
    if abs(drift(n) - drift(n-1)) > tollGap
        flag = false;
        window_start = ((n-1) * FsIN * window_second) + 1;
        window_end = n * FsIN * window_second;
        
        % se xcorr > 0   audio in anticipo  -->   aggiungere silenzio
        % se xcorr < 0   audio in ritardo   -->   rimuovere campioni
        
        % Cross-Correlazione 
        [AV, lagAV] = xcorr(audioCut(window_start:window_end), video(window_start:window_end));
        AV = AV/max(AV);

        [~, IAV] = max(AV);

        % Differenza, in campioni, tra le tracce 
        tAV = lagAV(IAV);
        
        % Stampa gap trovato
        fprintf('GAP @ %d\n', window_start+tAV);
        
        % Correzione gap
        if tAV > 0
           % Rimozione campioni
           audioCut = vertcat(audioCut(1:window_start-offset), audioCut(window_start-offset+tAV:end));
        else
           % da implementare
        end
        
    end
    
end

if flag
    fprintf('No gap founded')
end
fprintf('--------------\n')

% Allineamento Audio e Video
fprintf('ALIGN AUDIO AND VIDEO\n')

% Ciò è utile sia per la correzione della deriva che per l'export finale
% Il video rimane il master e non deve essere toccato

if length(audioCut) < infoVideo.TotalSamples
    % Se il video è più lungo dell'audio
    % aggiunge silenzio alla fine dell'audio
    d = infoVideo.TotalSample - length(audioCut);
    h = zero(d, 1);
    audioCut = vertcat(audioCut, d);
else
    % Se l'audio è più lungo del video 
    % taglia l'audio alla fine
    d = length(audioCut) - infoVideo.TotalSamples;
    audioCut = audioCut(1:end-d);
end

fprintf('--------------\n')

% Correzione deriva
fprintf('DRIFT CORRECTION\n')

% Calcola la cross-correlazione alla fine dei files e rimuove un singolo campione
% ad ogni round(TotalSamples/tAV)

% Cross-Correlazione 
[AV, lagAV] = xcorr(audioCut(end - FsIN * window_length : end), video(end - FsIN * window_length : end));
AV = AV/max(AV);

[~, IAV] = max(AV);

% Differenza, in campioni, tra le tracce
tAV = lagAV(IAV);

% Stampa il risultato
fprintf('Final drift: %d samples\n', tAV);
fprintf('--------------\n')

% Allineamento deriva
m = round(length(audioCut)/tAV);
sampleToBeDelete = zeros(m, 1);

t = length(audioCut);

fprintf('Calculate samples to be removed\n')

count = 1;
for n = 1:m:t
    sampleToBeDelete(count) = n;
    count = count + 1;
end

fprintf('Final Correction\n')

count = 1;
audioFinal = zeros(t,1);

for n = 1:length(audioCut)
    
    if n == sampleToBeDelete(count)
        count = count + 1;
    else
        audioFinal(n) = audioCut(n);
    end 
end


% Export finale
fprintf('--------------\n')
fprintf('Final Export\n')
audiowrite(fileOutput, audioFinal, FsIN);

% Ci sono problemi con ffmpeg  
% ffmpeg('-i', videoIN, '-i', 'audioSincronizzato.wav', fileOutput);

% Fine
fprintf('--------------\n')
fprintf('END\n')
fprintf('--------------\n')

end

