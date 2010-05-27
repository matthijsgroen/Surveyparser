SurveyResult parser
===================

Input files
-----------
This tool uses 2 input files:
1. A resultset from a checkmarket survey, stored as valid CSV
2. A definition sheet how the results should be interpreted, scored and scaled to a whole. Also in valid CSV

### The checkmarket file:
When downloading the checkmarket file, the file does not always contain valid formatted CSV. It is recommended to
store the file as a .xls file and export the active sheet as .CSV.

The program splits the checkmarket file in 2 column groups. Question-data and meta-data
The first 19 columns are considered meta-data:

0. "E-mailadres"
1. "Achternaam"
2. "Voornaam"
3. "Taal"
4. "Optioneel veld 1"
5. "Datum toegevoegd"
6. "Datum uitgenodigd"
7. "Datum e-mail bekeken"
8. "Datum doorgeklikt"
9. "Datum herinnerd (niet geantwoord)"
10. "Datum herinnerd (gedeeltelijk geantwoord)"
11. "Datum geantwoord"
12. "Einde bereikt"
13. "Invultijd (seconden)"
14. "Distributiemethode"
15. "Browser"
16. "Besturingssysteem"
17. "IP"
18. "Geolocatie (via IP)"

Column 4, "Optioneel veld 1" is used to store the intercalation of the name e.g. "van" or "van der"

### The definition sheet

