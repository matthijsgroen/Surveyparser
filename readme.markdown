SurveyResult parser
===================

The SurverResult parser is a tool to calculate scores of survery results. Calculations can be based on one or multiple question results.
The question results will be made to an average, wich can be put to a second calculation for scaling or curving the result.

Installation
============
To install and use this tool, you'll need the following:
 1. GIT
 2. Ruby
 3. A gem called `fastercsv`
 4. This tool

1. Installing GIT
-----------------
On Debian/Ubuntu Linux use your package manager:

	sudo apt-get install git

On Windows:
 1. [Download msysgit from google code](http://code.google.com/p/msysgit/)
 2. Install

2. Installing Ruby
------------------
On Debian/Ubuntu Linux use your package manager:

	sudo apt-get install ruby

On Windows:
1. [Download rubyinstaller](http://rubyinstaller.org/)
2. Install

3. Installing the necessary gems
--------------------------------
Gems are code plugins for ruby. We use the fastercsv gem for easy reading of CSV files.

Open a ruby shell on windows, or a normal shell on linux

	gem install fastercsv
	
4. Installing this tool
-----------------------
Open a git shell on windows, or a normal shell on linux.
Navigate to the folder using the 'cd' command. Windows users: use forward-slashes (/) in this prompt instead of back-slashes (\)
In your folder of choosing, run:

	git clone git://github.com/matthijsgroen/Surveyparser.git survey_parser

A folder called survey_parser will be created and this project will be downloaded in it.
The installation is now complete!

Updating the tool
=================
When the tool updates, (you can see the added changes [on github](http://github.com/matthijsgroen/Surveyparser/commits/master)) you need to update the code locally too.
Open a git shell on windows, or a normal shell on linux.

When the code is downloaded, the changed will be merged with the existing code. If there are unknown (uncommitted) changes in the code when trying to merge, the merge will fail. To prevent this, we purge all uncommited changes from the files under GIT management

	git reset --hard

After this, the code can be 'pulled' and merged from github again

	git pull
	
After the pull. You'll need to edit the run.rb file again to set your filename and filters.

Preparating input Files
=======================
The tool uses 3 CSV (*C*omma *S*eparated *V*alues) input files.
All CSV input files must be text separated by double quotes ("), and field separated by a comma (,)
 1. the survey results from check market.
 2. the calculation rules
 3. the mapping between variables used in the calculation rules and the question-result names from checkmarket

Check market survey results
---------------------------
The standard check market CSV file does not have a valid CSV format. My recommendation is to download the results in XLS format, and export the excel file as CSV. Place the CSV file in the *config/* folder of the tool.

Calculation rules 
-----------------
The calculation rules can be placed in an spreadsheet of choosing. The export of the sheet must be done in CSV. There are certain columns mandatory in the sheet. They are detected by their column name (first row). Letter casing does not matter when the names are read.

Here follows a list with columnnames and their function.

### Matrixvak	
Deze kolom bevat de naam hoe de matrixvakken worden gepresenteerd in de analysetool resultaten. Wanneer dezelfde naam in meerdere regels worden gebruikt, worden de regels gegroepeerd onder deze noemer.

### score in matrixvak	
Deze kolom bevat het percentage hoe de indicator als totaal gezien moet worden van het matrixvak. De totale score op de indicator wordt met het percentage vermenigvuldigd.

### indicator	
Deze kolom bevat de naam hoe de indicatoren worden gepresenteerd in de analysetool resultaten. Wanneer dezelfde naam in meerdere regels worden gebruikt, worden de regels gegroepeerd onder deze noemer.

### score in indicator
Deze kolom bevat het percentage hoe de vraag als totaal gezien moet worden van de indicator. De totale score op de vraag wordt met het percentage vermenigvuldigd.

### vraag
Onder deze noemer worden de antwoorden gepresenteerd onder de indicator

### groepsformule	
Deze formule wordt uitgevoerd nadat het gemiddelde is bepaald van alle antwoordformules

### antwoordformule	
Deze formule wordt op participant niveau uitgevoerd

variable mapping
----------------


