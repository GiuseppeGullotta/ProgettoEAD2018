# Sincronizzazione Tracce Audio

Il seguente progetto è stato realizzato per il corso di Elaborazione dell'Audio Digitale presso il [Politecnico di Torino](https://www.polito.it) tenuto dal professore Antonio Servetti.

## Descrizione
Il progetto caricato è stato implementato su Matlab (2017b). La funzione ha lo scopo di sincronizzare due tracce audio provenienti da sorgenti diverse. Di base, in ingresso si inseriscono una traccia video sorgente e una traccia audio secondaria (ad esempio, un video con una persona che parla e audio della telecamera e, nella traccia audio secondaria, la registazione di un microfono).

L'obiettivo è quello di sincronizzare la traccia secondaria con il video. Oltre a sincronizzare le tracce, la funzione corregge la deriva della traccia secondaria (provocata, ad esempio, da differenti clock dei recorder) e rileva e corregge eventuali "pezzi estranei" presenti nella traccia audio aggiuntiva (come brevi silenzi).

Il codice automaticamente esporta la traccia audio secondaria tagliata e corretta da errori e restituisce il numero di samples di differenza iniziale. Inoltre, il codice fornisce all'utente un grafico che rappresenta la deriva tra le due tracce e una serie di dati relativi alle operazioni svolte dalla funzione.


## Installazione

* Scaricare il file .m
* Aprire Matlab e posizionarsi nella Directory dove è presente il file appena scaricato.
* Da codice, digitare la seguente sintassi:
 
        s = audioSync(videoIN, audioIN, Fs, fileOutput, toll) 
        
 dove:  
 
        `audioIN`    = directory traccia audio secondaria
        
        `videoIN`    = directory traccia video principale
        
        `Fs`         = frequenza di campionamento delle tracce audio e video
        
        `fileOutput` = directory nuova traccia audio sincronizzata
        
        `toll`       = tolleranza secondi di dissincronismo (se non si sa che paramentro inserire, digitare 0.1)
     
     
* Eseguire la funzione

## Limiti del codice 
* Attualmente, non è possibile inserire tracce con frequenza di campionamento differente. Questo problema sarà risolto successivamente, implementando una funzione che permetta di ricampionare la traccia audio con frequenza di campionamento maggiore e riportandola a quella minore. 
* Il codice è stato prototipato per uno specifico task e potrebbe non essere adatto per altre esigenze.
* La deriva funziona bene se l'audio secodario è in ritardo rispetto a quello del video e può creare problemi se viceversa.

### Esempio di utilizzo
Scaricare i file di esempio cliccando [qui](https://drive.google.com/drive/folders/1y2ze7OLnI-feHuuXNQVXRHRoOBnEKxfX?usp=sharing)

> audioIN = 'video.mp4';

> audioIN = 'audio.3gpp';

> FsIN = 44100;

> fileOutput = 'audioSincronizzato.mp4';

> toll = 0.1;

> s = audioSync(videoIN, audioIN, FsIN, fileOutput, toll);



## Sviluppatori

[Giuseppe Gullotta](https://github.com/GiuseppeGullotta)

[Liliana Scaffidi](https://github.com/LilianaScaffidi)




        

