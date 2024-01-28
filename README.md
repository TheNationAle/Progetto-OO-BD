# Commenti e spiegazioni sull'SQL

Nella tabela Natnate, Abbiamo reso Not Null:
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

...
