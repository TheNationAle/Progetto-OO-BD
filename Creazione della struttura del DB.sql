-- Creazione delle tabelle principali
CREATE TABLE Compagnia(
    Nome VARCHAR(255)    PRIMARY KEY,
    Telefono VARCHAR(15) UNIQUE,
    Email VARCHAR(255)   NOT NULL UNIQUE,
    SitoWeb VARCHAR(255) NOT NULL UNIQUE,
    Social VARCHAR(255),
    PasswordComp VARCHAR(255),
    Sovraprezzo_P DECIMAL(5,2),
    Sovraprezzo_B DECIMAL(5,2)
);

CREATE TABLE Natante (
    ID_Natante SERIAL PRIMARY KEY,
    Compagnia VARCHAR(255) NOT NULL,
    Nome VARCHAR(255) NOT NULL,
    Tipo VARCHAR(20) CHECK (Tipo IN ('Traghetto', 'Aliscafo', 'Motonave')) NOT NULL,
    CapienzaP INT NOT NULL,
    CapienzaA INT,
    FOREIGN KEY (Compagnia) REFERENCES Compagnia(Nome)
    ON DELETE CASCADE
);

CREATE TABLE Porto (
    Nome VARCHAR(255) PRIMARY KEY,
    Comune VARCHAR(255) NOT NULL,
    Coordinate VARCHAR(255) NOT NULL
);

CREATE TABLE Cadenza(
	Id_Cadenza SERIAL PRIMARY KEY,
	Giorno VARCHAR(255) NOT NULL,
	Periodo_I DATE  NOT NULL,
	Periodo_F DATE  NOT NULL
);

CREATE TABLE Corsa (
	ID_Corsa SERIAL PRIMARY KEY,
	ID_Natante INT NOT NULL,
	data Date,
    	orariop time without time zone NOT NULL,
        orarioa time without time zone NOT NULL,
	Cancellazione BOOL DEFAULT FALSE,
	Ritardo INT DEFAULT 0,
	PostiRimasti_P INT,
	PostiRimasti_A INT,
	Prezzo_I DECIMAL(5,2) NOT NULL,
    	Prezzo_R DECIMAL(5,2) NOT NULL,
    	Partenza VARCHAR(255),
	Arrivo VARCHAR(255),
	ID_cadenza INT NOT NULL,
	
	FOREIGN KEY (ID_cadenza) REFERENCES Cadenza(Id_Cadenza)
	ON DELETE SET NULL,
	FOREIGN KEY (ID_Natante) REFERENCES Natante(ID_Natante)
	ON DELETE SET NULL,
	FOREIGN KEY (Partenza) REFERENCES Porto(Nome)
	ON DELETE SET NULL,
	FOREIGN KEY (Arrivo) REFERENCES Porto(Nome)
	ON DELETE SET NULL
);

CREATE TABLE AutoVeicolo(
    Tipo VARCHAR(255),
    Sovraprezzo_A DECIMAL(5,2) NOT NULL,
    dimensione INT NOT NULL,
    nome_compagnia VARCHAR(255),

    PRIMARY KEY (Tipo, nome_compagnia),
    FOREIGN KEY (nome_compagnia) REFERENCES Compagnia(Nome)
    ON DELETE CASCADE
);

CREATE TABLE Cliente (
	Email VARCHAR(255) PRIMARY KEY,
	PasswordCli VARCHAR(15) NOT NULL,
	Nome VARCHAR(255) NOT NULL,
	Cognome VARCHAR(255) NOT NULL,
	Sex VARCHAR(15),
	Data_N DATE NOT NULL
);

CREATE TABLE Trasporta(
	ID_Corsa INT ,
	Tipo VARCHAR(255),
	nome_compagnia VARCHAR(255),
	
	PRIMARY KEY (ID_Corsa,Tipo),
	FOREIGN KEY (ID_Corsa) REFERENCES Corsa(ID_Corsa),
	FOREIGN KEY (Tipo, nome_compagnia) REFERENCES AutoVeicolo(Tipo, nome_compagnia)
	ON DELETE CASCADE
	
);

CREATE TABLE Biglietto (
	ID_Biglietto SERIAL PRIMARY KEY,
	Email VARCHAR(255),
	ID_Corsa INT,
	Prenotazione BOOL DEFAULT FALSE,
	Disbilita BOOL DEFAULT FALSE,
	Bagagli INT DEFAULT 0,
	TipoAutoveicolo VARCHAR(255),
	FOREIGN KEY (Email) REFERENCES Cliente(Email)
	ON DELETE CASCADE,
    	FOREIGN KEY (ID_Corsa) REFERENCES Corsa(ID_Corsa)
);


--CONSTRAINT


ALTER TABLE autoveicolo
ADD CONSTRAINT SovrapprezzoValidoA CHECK(autoveicolo.sovraprezzo_a >= 0);

ALTER TABLE autoveicolo
ADD CONSTRAINT dimensionevalida CHECK (dimensione > 0);

ALTER TABLE compagnia
ADD CONSTRAINT SovrapprezzoValidoP CHECK(compagnia.sovraprezzo_p >= 0);

ALTER TABLE compagnia
ADD CONSTRAINT SovrapprezzoValidoB CHECK(compagnia.sovraprezzo_b >= 0);

ALTER TABLE cadenza
ADD CONSTRAINT PeriodoValido CHECK(cadenza.periodo_i < cadenza.periodo_f AND periodo_i >= CURRENT_DATE);

ALTER TABLE compagnia
ADD CONSTRAINT EmailValida CHECK(compagnia.email LIKE '_%@%.__%');

ALTER TABLE compagnia
ADD CONSTRAINT SitoValido CHECK(compagnia.sitoweb LIKE '_%.__%');

ALTER TABLE natante
ADD CONSTRAINT PostiValidiP CHECK(natante.capienzap>0);

ALTER TABLE natante
ADD CONSTRAINT PostiValidiA CHECK((natante.tipo = 'Traghetto' AND natante.capienzaa>0) OR (natante.tipo <> 'Traghetto' AND natante.capienzaa=0));

ALTER TABLE corsa
ADD CONSTRAINT PortiDistiniti CHECK(corsa.arrivo<>corsa.partenza);

ALTER TABLE biglietto
ADD CONSTRAINT bagagliReali CHECK(biglietto.bagagli >=0);

ALTER TABLE cliente
ADD CONSTRAINT EmailValida CHECK(cliente.email LIKE '_%@%.__%');

ALTER TABLE corsa
ADD CONSTRAINT portiValidi CHECK ( (partenza is not null AND arrivo is not null)
			   OR ( (partenza is null or arrivo is null) AND (cancellazione = true) ));

ALTER TABLE cliente
ADD CONSTRAINT NascitaValida
CHECK((EXTRACT(YEAR FROM cliente.data_n)+18 < EXTRACT(YEAR FROM current_date)
OR EXTRACT(YEAR FROM cliente.data_n)+18 = EXTRACT(YEAR FROM current_date) AND EXTRACT(MONTH FROM cliente.data_n) < EXTRACT(MONTH FROM current_date)
OR EXTRACT(YEAR FROM cliente.data_n)+18 = EXTRACT(YEAR FROM current_date) AND EXTRACT(MONTH FROM cliente.data_n) = EXTRACT(MONTH FROM current_date) AND EXTRACT(DAY FROM cliente.data_n) <= EXTRACT(DAY FROM current_date))
AND EXTRACT(YEAR FROM cliente.data_n) >= 1900);


--TRIGGER


CREATE OR REPLACE FUNCTION AnnullaCorsaF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	mail CURSOR FOR SELECT email FROM biglietto WHERE id_corsa = NEW.id_corsa;
BEGIN
	FOR ma in mail LOOP
		RAISE NOTICE 'Email e rimborso inviati a utente %', ma;
	END LOOP;
	DELETE FROM Biglietto B
	WHERE NEW.id_corsa = B.id_corsa;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER AnnullaCorsa
AFTER UPDATE OF cancellazione ON corsa
FOR EACH ROW EXECUTE FUNCTION public.AnnullaCorsaF();

--

CREATE OR REPLACE FUNCTION AggiornaPostCli() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	posti INTEGER :=(SELECT postirimasti_p FROM corsa WHERE id_corsa = NEW.id_corsa);
BEGIN
IF posti>0 THEN

	UPDATE corsa
	SET postirimasti_p = postirimasti_p-1
	WHERE id_corsa=NEW.id_corsa;
	
ELSIF posti <=0 THEN
	RAISE EXCEPTION USING MESSAGE = 'Posti non disponibili';
END IF;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER AggiornaPostoCli
BEFORE INSERT ON biglietto
FOR EACH ROW EXECUTE FUNCTION public.AggiornaPostCli();

--

CREATE OR REPLACE FUNCTION AggiornaPostA() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
Auto INTEGER :=(SELECT dimensione
		FROM autoveicolo 
		WHERE tipo = NEW.tipoautoveicolo AND nome_compagnia = (
		SELECT compagnia FROM natante WHERE id_natante = (
		SELECT id_natante FROM corsa WHERE id_corsa = NEW.id_corsa)));
postiA INTEGER :=(SELECT postirimasti_a FROM corsa WHERE id_corsa = NEW.id_corsa);
BEGIN
IF NEW.tipoautoveicolo is NULL THEN
	RETURN NEW;
END IF;
IF postiA>=Auto THEN

	UPDATE corsa
	SET postirimasti_a=postirimasti_a-Auto
	WHERE id_corsa=NEW.id_corsa;
	
ELSIF postiA< Auto THEN
	RAISE EXCEPTION USING MESSAGE = 'Posti Auto non disponibili';
END IF;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER AggiornaPostoA
BEFORE INSERT ON biglietto
FOR EACH ROW EXECUTE FUNCTION public.AggiornaPostA();

--

CREATE OR REPLACE FUNCTION NatanteVendutoF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	corse CURSOR FOR SELECT * FROM corsa WHERE id_natante = OLD.id_natante;
BEGIN
	FOR cor IN corse LOOP
		UPDATE corsa SET cancellazione = TRUE WHERE id_corsa = cor.id_corsa;
	END LOOP;
RETURN OLD;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER NatanteVenduto
BEFORE DELETE ON natante
FOR EACH ROW EXECUTE FUNCTION public.NatanteVendutoF();

--

CREATE OR REPLACE FUNCTION modificaPeriodoIF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	inizio DATE := NEW.periodo_i;
	modello corsa%ROWTYPE;
	nat natante%ROWTYPE;
	week VARCHAR(100);
	num INTEGER;
BEGIN
	SELECT * INTO modello FROM corsa WHERE id_cadenza = NEW.id_cadenza LIMIT 1;
	SELECT * INTO nat FROM natante WHERE id_natante = modello.id_natante;

	IF NEW.periodo_i > OLD.periodo_i THEN 
		UPDATE corsa SET cancellazione = TRUE WHERE id_cadenza = NEW.id_cadenza 
		AND data BETWEEN OLD.periodo_i AND NEW.periodo_i;
	ELSIF NEW.periodo_i < OLD.periodo_i THEN

		WHILE inizio < OLD.periodo_i LOOP
			SELECT TRIM (TO_CHAR(inizio, 'Day')) INTO week;
			SELECT POSITION(week IN NEW.giorno) into num;
			IF num > 0 THEN
				INSERT INTO corsa(
				id_natante, data, orariop, orarioa, cancellazione, ritardo, postirimasti_p, postirimasti_a, prezzo_i, prezzo_r, partenza, arrivo, id_cadenza)
				VALUES (modello.id_natante, inizio, modello.orariop, modello.orarioa, FALSE, 0, nat.capienzap, nat.capienzaa, modello.prezzo_i, modello.prezzo_r, modello.partenza, modello.arrivo, modello.id_cadenza);
			END IF;
			inizio := (SELECT inizio + INTERVAL '1 day');

		END LOOP;
	END IF;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER modificaperiodoi
BEFORE UPDATE OF periodo_i ON cadenza
FOR EACH ROW EXECUTE FUNCTION public.modificaPeriodoIF();

--

CREATE OR REPLACE FUNCTION annullabigliettof() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	Auto INTEGER;
	NUM INTEGER;
BEGIN
	
	UPDATE corsa
	SET postirimasti_p=postirimasti_p+1
	WHERE id_corsa=OLD.id_corsa;
	
	IF OLD.tipoautoveicolo IS NOT NULL THEN
		SELECT dimensione INTO Auto
		FROM autoveicolo
		WHERE tipo = OLD.tipoautoveicolo AND nome_compagnia = (
		SELECT compagnia FROM natante WHERE id_natante = (
		SELECT id_natante FROM corsa WHERE id_corsa = OLD.id_corsa));
		
		UPDATE corsa
		SET postirimasti_a=postirimasti_a+Auto
		WHERE id_corsa=OLD.id_corsa;
	END IF;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER annullabiglietto
AFTER DELETE ON biglietto
FOR EACH ROW EXECUTE FUNCTION public.annullabigliettof();

--

CREATE OR REPLACE FUNCTION modificaPeriodoFF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	inizio DATE := OLD.periodo_f;
	modello corsa%ROWTYPE;
	nat natante%ROWTYPE;
	week VARCHAR(100);
	num INTEGER;
BEGIN
	SELECT * INTO modello FROM corsa WHERE id_cadenza = NEW.id_cadenza LIMIT 1;
	SELECT * INTO nat FROM natante WHERE id_natante = modello.id_natante;
	IF NEW.periodo_f <= OLD.periodo_f THEN 
		UPDATE corsa SET cancellazione = TRUE WHERE id_cadenza = NEW.id_cadenza 
		AND data BETWEEN NEW.periodo_f AND OLD.periodo_f;
	ELSIF NEW.periodo_f > OLD.periodo_f THEN
		WHILE inizio < NEW.periodo_f LOOP
		SELECT TRIM (TO_CHAR(inizio, 'Day')) INTO week;
		SELECT POSITION(week IN NEW.giorno) into num;
			IF num > 0 THEN
				INSERT INTO corsa(
				id_natante, data, orariop, orarioa, cancellazione, ritardo, postirimasti_p, postirimasti_a, prezzo_i, prezzo_r, partenza, arrivo, id_cadenza)
				VALUES (modello.id_natante, inizio, modello.orariop, modello.orarioa, FALSE, 0, nat.capienzap, nat.capienzaa, modello.prezzo_i, modello.prezzo_r, modello.partenza, modello.arrivo, modello.id_cadenza);
			END IF;
			inizio := (SELECT inizio + INTERVAL '1 day');
		END LOOP;
	END IF;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER modificaperiodof
BEFORE UPDATE OF periodo_f ON cadenza
FOR EACH ROW EXECUTE FUNCTION public.modificaPeriodoFF();

--

CREATE OR REPLACE FUNCTION modificagiornif() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	inizio DATE := NEW.periodo_i;
	modello corsa%ROWTYPE;
	nat natante%ROWTYPE;
	week VARCHAR(100);
	num INTEGER;
BEGIN
	SELECT * INTO modello FROM corsa WHERE id_cadenza = NEW.id_cadenza LIMIT 1;
	SELECT * INTO nat FROM natante WHERE id_natante = modello.id_natante;
	WHILE inizio <= NEW.periodo_f LOOP
		SELECT TRIM (TO_CHAR(inizio, 'Day')) INTO week;
		SELECT POSITION(week IN NEW.giorno) into num;
		IF num = 0 THEN 
			UPDATE corsa SET cancellazione = TRUE WHERE id_cadenza = NEW.id_cadenza 
			AND data = inizio AND id_natante = modello.id_natante AND orariop = modello.orariop;
		ELSIF num>0 THEN
			SELECT COUNT(*) INTO num FROM corsa WHERE id_cadenza = NEW.id_cadenza
			AND data = inizio AND id_natante = modello.id_natante AND orariop = modello.orariop;
			IF num = 0 THEN
				INSERT INTO corsa(
				id_natante, data, orariop, orarioa, cancellazione, ritardo, postirimasti_p, postirimasti_a, prezzo_i, prezzo_r, partenza, arrivo, id_cadenza)
				VALUES (modello.id_natante, inizio, modello.orariop, modello.orarioa, FALSE, 0, nat.capienzap, nat.capienzaa, modello.prezzo_i, modello.prezzo_r, modello.partenza, modello.arrivo, modello.id_cadenza);
			END IF;
		END IF;
			inizio := (SELECT inizio + INTERVAL '1 day');
	END LOOP;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER modificagiorni
BEFORE UPDATE OF giorno ON cadenza
FOR EACH ROW EXECUTE FUNCTION public.modificagiornif();

--

CREATE OR REPLACE FUNCTION inserimentoCorsef() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	cad cadenza%ROWTYPE;
	nat natante%ROWTYPE;
	week VARCHAR(100);
	inizio DATE := (SELECT periodo_i FROM cadenza WHERE id_cadenza = NEW.id_cadenza);
	cont INTEGER := 0;
	num INTEGER;
BEGIN
	IF NEW.data is not NULL THEN
		RETURN NEW;
	END IF;
	SELECT * INTO cad FROM cadenza WHERE id_cadenza = NEW.id_cadenza;
	SELECT * INTO nat FROM natante WHERE id_natante = NEW.id_natante;
	WHILE inizio <= cad.periodo_f LOOP
		SELECT TRIM (TO_CHAR(inizio, 'Day')) INTO week;
		SELECT POSITION(week IN cad.giorno) into num;
		IF num>0 THEN
			SELECT COUNT(*) INTO num FROM corsa WHERE id_cadenza = NEW.id_cadenza
			AND data = inizio AND id_natante = NEW.id_natante AND orariop = NEW.orariop;
			IF num = 0 THEN
				INSERT INTO corsa(
				id_natante, data, orariop, orarioa, cancellazione, ritardo, postirimasti_p, postirimasti_a, prezzo_i, prezzo_r, partenza, arrivo, id_cadenza)
				VALUES (NEW.id_natante, inizio, NEW.orariop, NEW.orarioa, FALSE, 0, nat.capienzap, nat.capienzaa, NEW.prezzo_i, NEW.prezzo_r, NEW.partenza, NEW.arrivo, cad.id_cadenza);
			END IF;
		END IF;
			inizio := (SELECT inizio + INTERVAL '1 day');
	END LOOP;
	DELETE FROM corsa WHERE data IS NULL;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER inserimentoCorse
AFTER INSERT ON corsa
FOR EACH ROW EXECUTE FUNCTION public.inserimentoCorsef();

--

CREATE OR REPLACE FUNCTION riempiTrasportaF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
    ncompagnia VARCHAR(255)= (SELECT DISTINCT compagnia 
							  FROM natante
							  WHERE id_natante = NEW.id_natante);
	veicoli CURSOR FOR SELECT * FROM autoveicolo WHERE nome_compagnia = ncompagnia;
BEGIN
if NEW.data is not null then
	FOR veicolo in veicoli LOOP
		INSERT INTO trasporta VALUES(NEW.id_corsa, veicolo.tipo, ncompagnia);
	END LOOP;
end if;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER riempiTrasporta
AFTER INSERT ON corsa
FOR EACH ROW EXECUTE FUNCTION public.riempiTrasportaF();

-- 

CREATE OR REPLACE FUNCTION riempiTrasporta2F() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	corse CURSOR FOR SELECT * FROM corsa WHERE id_natante IN (SELECT id_natante FROM natante WHERE compagnia = NEW.nome_compagnia);
BEGIN
	FOR co in corse LOOP
		INSERT INTO trasporta VALUES(co.id_corsa, NEW.tipo, NEW.nome_compagnia);
	END LOOP;
RETURN NEW;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER riempiTrasporta2
AFTER INSERT ON autoveicolo
FOR EACH ROW EXECUTE FUNCTION public.riempiTrasporta2F();

--

CREATE OR REPLACE FUNCTION EliminaPortoF() RETURNS TRIGGER AS $destinazioneTrigger$
DECLARE
	corse CURSOR FOR SELECT * FROM corsa WHERE partenza = OLD.nome OR arrivo = OLD.nome;
BEGIN
	FOR cor IN corse LOOP
		UPDATE corsa SET cancellazione = TRUE WHERE id_corsa = cor.id_corsa;
	END LOOP;
RETURN OLD;
END;
$destinazioneTrigger$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER EliminaPorto
BEFORE DELETE ON porto
FOR EACH ROW EXECUTE FUNCTION public.EliminaPortoF();