SurveyResult parser
===================

The Survey result parser is used to calculate scores of different factors across survey results.
The execution uses the following steps:
1. The definition of score calculation is read and interpreted
2. The survey results are loaded.
3. The survey participants are filtered on a set of conditions.
3. For every participant the definition rules are run and result in a answer-per-rule. The results of the survey are
  mere input parameters. A definition rule can use multiple survey answers in a single calculation
4. The list of scoring results and meta-information about the rule and participant is now created
5. All results are now parsed into a tree form, with the levels: Matrix-tile, indicator and question(rule)
6. Scores are averaged on question level and scaled to the indicator and matrix-tile level.
7. An output HTML file is created. This can also be plain text output

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
The definition sheet must have the following format:

1. matrix-tile
2. indicator scale on matrix tile
3. indicator-name
4. unique identifier
5. question scale on indicator
6. question
7. answer options in text form
8. rule-type
9. scaling-curve-formula
10. e-value of curve
11-28. answer scores / formula

== Rule types

### "1 antwoord" (single answer)

### "dummy"

### "meta berekening" (multiple question input calculation)

### "cloud" (text answer cloud)
