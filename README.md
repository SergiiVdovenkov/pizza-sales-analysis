# 🍕 Umsatzanalyse einer Pizzeria

**817.860 $ Umsatz · 21.350 Bestellungen · Ø 38,31 $ pro Bestellung**

Zwischenprojekt · Deutsche Tech Akademie · Data Analytics & Engineering
Analyse der Kassendaten einer Pizzeria für das Jahr 2015 mit SQL und Tableau.

## 1. Ausgangslage und Kernfragen

Laura Martinez hat Ende des Jahres eine Pizzeria in New Jersey übernommen und den Kassenexport für das ganze Jahr 2015 erhalten. Im Januar muss sie drei Entscheidungen treffen:

1. **Schichtplan** – in ruhigen Stunden nicht zu viel Personal, in Stoßzeiten nicht überlastet.
2. **Speisekarte** – welche Pizzen gestrichen werden können (zu viele Positionen, Zutaten verderben).
3. **Aktion** – wann und mit welcher Aktion schwache Tage und Uhrzeiten gestärkt werden.

Dazu beantwortet die Analyse acht Kernfragen: Kennzahlen des Jahres · Entwicklung nach Monaten · Auslastung nach Wochentagen und Uhrzeiten · Bestseller und Ladenhüter · Kategorien und Größen · Kandidaten für die Streichung · große Bestellungen · Aktion.

## 2. Links

| Was | Link |
| --- | --- |
| Datensatz (Kaggle) | [Pizza Place Sales](https://www.kaggle.com/datasets/mysarahmadbhat/pizza-place-sales) |
| Dashboard (Tableau Public) | [Übersicht](https://public.tableau.com/views/pizza_dashboard_17908653158890/bersicht) |
| Story mit Empfehlungen (Tableau Public) | [Empfehlungen](https://public.tableau.com/views/pizza_dashboard_17908653158890/Empfehlungen) |
| Präsentation (PDF) | [presentation/presentation.pdf](presentation/presentation.pdf) |
| Präsentation (HTML) | [presentation/index.html](presentation/index.html) |
| SQL-Abfragen | [sql/queries.sql](sql/queries.sql) |

## 3. Daten und Werkzeuge

- 4 Tabellen: `orders` (21.350 Zeilen), `order_details` (48.620), `pizzas` (96), `pizza_types` (32)
- Zeitraum: 01.01.2015 – 31.12.2015, keine fehlenden Werte, keine verwaisten Schlüssel
- Auswahl für Tableau: VIEW `sales_lines` über alle 4 Tabellen, 1 Zeile = 1 Bestellposition, 12 Felder. Kontrolle: 48.620 Zeilen = `order_details`
- **SQL**: SQLite Online – JOIN, CTE, Fensterfunktionen (`LAG`, `SUM() OVER`), VIEW
- **Visualisierung**: Tableau Public · **Abgabe**: GitHub

## 4. Antworten auf die 8 Fragen

### Q1: Kennzahlen 2015
- Umsatz **817.860 $**, 21.350 Bestellungen, 49.574 Pizzen
- Ø Bestellwert **38,31 $**, Ø 2,32 Pizzen pro Bestellung

### Q2: Entwicklung nach Monaten
- Stärkster Monat: Juli mit 72.558 $ Umsatz, schwächster: Oktober mit 64.028 $
- Kein klarer Jahrestrend, Abstand 13,3 %

### Q3: Auslastung nach Wochentagen und Uhrzeiten
- Stärkster Tag: Freitag (70,8 Bestellungen/Tag), ruhigster: Sonntag (50,5)
- Spitzen 12–14 und 17–19 Uhr, ruhige Phase 14–16 Uhr (je 4,1 Bestellungen pro Stunde)

### Q4: Bestseller und Ladenhüter
- Umsatzstärkste Sorte: Thai Chicken (43.434 $), meistverkauft: Classic Deluxe (2.453 Stück)
- Schlusslicht in beiden Listen: Brie Carre (11.589 $, 490 Stück)

### Q5: Kategorien und Größen
- Kategorien fast gleich: 23,7 % bis 26,9 % des Umsatzes
- Größe L bringt 45,9 % des Umsatzes, XL und XXL zusammen nur 1,8 %

### Q6: Kandidaten für die Streichung
- 4 Sorten streichen: Brie Carre, Green Garden, Spinach Supreme, Mediterranean
- Betroffen: höchstens 6,87 % des Umsatzes (56.183 $); 6 Zutaten kommen in keiner anderen Sorte vor

### Q7: Große Bestellungen (4+ Pizzen)
- 18,2 % der Bestellungen bringen 39,4 % des Umsatzes; Ø Bestellwert 83,14 $ statt 28,35 $
- Ja, ein eigenes Angebot für Firmen lohnt sich zu prüfen – wer bestellt, zeigen die Daten nicht

### Q8: Aktion
- „Nachmittags-Deal“ täglich 14–16 Uhr: Pizza L zum Preis von M
- Heute 112.194 $ Umsatz in diesem Fenster (13,7 %); +10 % = +11.219 $ pro Jahr

## 5. Drei Empfehlungen für Laura

1. **Schichtplan:** Personal auf 12–14 Uhr und 17–19 Uhr ausrichten, freitags verstärken (70,8 Bestellungen/Tag), Fr–Sa abends bis 20 Uhr. 14–16 Uhr und sonntags (50,5/Tag) reicht eine kleinere Besetzung. Vor 11 Uhr und ab 23 Uhr: nur 1, 8 und 28 Bestellungen im Jahr → Öffnungszeiten prüfen.
2. **Speisekarte:** Brie Carre, Green Garden, Spinach Supreme und Mediterranean streichen: höchstens 6,87 % des Umsatzes (56.183 $), 6 Zutaten weniger im Einkauf. Spinach Pesto, Calabrese und Italian Vegetables (1,91–1,96 %) beobachten.
3. **Aktion:** „Nachmittags-Deal“ täglich 14–16 Uhr, Pizza L zum Preis von M. Bei +10 % im Zeitfenster +11.219 $ pro Jahr. 4–6 Wochen testen; zusätzlich ein Firmenangebot prüfen (große Bestellungen = 39,4 % des Umsatzes).

## 6. Dashboard

[![Dashboard](presentation/dashboard.png)](https://public.tableau.com/views/pizza_dashboard_17908653158890/bersicht)

🔗 [Interaktives Dashboard auf Tableau Public](https://public.tableau.com/views/pizza_dashboard_17908653158890/bersicht) – Filter nach Monat, Kategorie und Größe, Parameter „Top N“, Klick-Aktionen, Story „Empfehlungen“.

Hinweis zur Datenquelle: Das Dashboard nutzt die Auswahl `sales_lines` (48.620 Zeilen). Tableau Public hat die Dezimalpunkte der CSV-Datei mit deutscher Ländereinstellung nicht als Zahlen gelesen, deshalb ist dieselbe Auswahl als `exports/sales_lines.xlsx` angebunden. Inhalt und Kontrollsummen sind identisch mit `exports/sales_lines.csv`.

## 7. Grenzen der Daten und nächste Schritte

- Nur Umsatz, keine Kosten und Marge → der Nettoeffekt der Aktion ist offen.
- Nur ein Jahr → Saison und Trend lassen sich nicht trennen.
- Keine Kunden- und Personaldaten → wer groß bestellt und wie viele Mitarbeiter je Stunde arbeiten, ist unbekannt.
- Nächste Schritte: Aktion als Vorher/Nachher- oder A/B-Test messen, Uhrzeit und Wochentag großer Bestellungen auswerten, Kosten und Verderb der Zutaten erfassen.

## 8. Projektstruktur

```
pizza-sales-analysis/
├── README.md              # Projektbeschreibung, Kurzantworten, Links
├── data/                  # 4 Original-CSV von Kaggle
├── sql/
│   └── queries.sql        # alle Abfragen mit Kommentaren und Ergebnissen
├── exports/
│   ├── sales_lines.csv    # Auswahl für Tableau (VIEW sales_lines)
│   └── sales_lines.xlsx   # dieselbe Auswahl, Datenquelle des Dashboards
├── tableau/
│   └── pizza_dashboard.twbx
└── presentation/
    ├── presentation.pdf
    ├── index.html
    ├── er-diagram.png
    └── dashboard.png
```

## 9. Autor

**Sergii Vdovenkov** · [GitHub](https://github.com/SergiiVdovenkov)
