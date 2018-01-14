# Sincronizzazione Tracce Audio

Il seguente progetto è stato realizzato per il corso di Elaborazione dell'Audio Digitale del [Politecnico di Torino](https://www.polito.it) tenuto dal professor Antonio Servetti.

## Descrizione
Il progetto caricato è stato implementato su Matlab (2017b). La funzione ha lo scopo di sincronizzare due tracce audio provenienti da sorgenti diverse. Di base, l'idea è quella di avere una traccia video sorgente ed una traccia audio secondaria (ad esempio, un video con una persona che parla e audio della telecamera e, nella traccia audio secondaria, la registazione di un microfono).

L'obiettivo è quello di sincronizzare la traccia secondaria con il video. Oltre a sincronizzare le tracce, la funzione corregge la deriva della traccia secondaria (provocata, ad esempio, da differenti clock dei recorder) e rileva e corregge eventuali "pezzi estranei" presenti nella traccia audio aggiuntiva (come brevi silenzi).

Il codice automaticamente esporta la traccia audio secondaria tagliata e corretta da errori e ritorna il numero di samples di differenza iniziale.


## Installazione

* Scaricare il file .m
* Aprire Matlab e posizionarsi nella Directory dove è presente il file appena scaricato.
* Da codice, digitare la seguente sintassi:
 
        s = audioSync(videoIN, audioIN, Fs, fileOutput, toll) 
        
 dove:  `audioIN`    = directory traccia audio secondaria
        
        `videoIN`    = directory traccia video principale
        
        `Fs`         = frequenza di campionamento delle tracce audio e video
        
        `fileOutput` = directory nuova traccia audio sincronizzata
        
        `toll`       = tolleranza secondi di deriva
       
        

