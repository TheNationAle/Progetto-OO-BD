# Commenti e spiegazioni sull'SQL

Nella tabella Compagnia l'attributo telefono è UNIQUE perché non possono esistere due numeri di telefono uguali; lo stesso vale per email e sitoweb.
Email e Sitoweb non possono essere nulli perché la prima serve per 
accedere all'applicativo e il secondo è l'applicativo stesso.

Nella tabella Natante, Abbiamo reso Not Null:
Compagnia perché ogni Natante è posseduto da una compagnia;
Nome perché ogni Natante ha un proprio nome;
Tipo perché ogni Natante è sicuramente o motoscafo o aliscafo o traghetto;
CapienaP perché indifferentemente da il tipo del Natante può trasportare almeno una persona;
CapienzaA può essere Null perché gli autoveicoli possono essere traspostati solo dai traghetti.

Nella tabella, Porto Abbiamo reso Not Null:
Comune perché ogni porto ha un comune di residenza;
Coordinate perché ogni porto ha delle proprie coordinate.

Nella tabella Cadenza, Periodo_I e Periodo_F sono not null perché ogni cadenza ha una data di inizio e una di fine;
Giorno è Not Null perché i giorni in cui opera Cadenza non possono non esistere.

Nella tabella Corsa abbiamo reso not null gli attributi:
ID_Natante perché ogni corsa deve essere effettuata obbligatoriamente da un Natante;
OrarioP e OrarioA perché ogni corsa deve avere un orario di corsa e un orario di arrivo;
PrezzoI e PrezzR perché ogni corsa deve avere un prezzo intero e uno ridotto;
ID_Cadenza perché ad ogni appartiene una cadenza.

Nella tabella Autoveicolo sovraprezzoA e dimensione sono not null perché ogni autoveicolo ha un suo sovraprezzo e una sua dimensione.

Nell tabella Cliente sono not null:
La password perché è obbligatoria per l'accesso;
Il Nome e il Cognome perché ogni persona li possiede;
Data_N perché ogni Cliente ha una data di nascità.
