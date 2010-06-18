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
Navigate to the folder using the `cd` command. Windows users: use forward-slashes (/) in this prompt instead of back-slashes (\\)
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
	
After the pull. You'll need to edit the `run.rb` file again to set your filename and filters.

Preparating input Files
=======================
The tool uses 3 CSV (**C**omma **S**eparated **V**alues) input files.
All CSV input files must be text separated by double quotes ("), and field separated by a comma (,)

1. the survey results from check market.
2. the calculation rules
3. the mapping between variables used in the calculation rules and the question-result names from checkmarket

Check market survey results
---------------------------
The standard check market CSV file does not have a valid CSV format. My recommendation is to download the results in XLS format, and export the excel file as CSV. Place the CSV file in the `config/` folder of the tool.

Calculation rules 
-----------------
The calculation rules can be placed in an spreadsheet of choosing. The export of the sheet must be done in CSV. There are certain columns mandatory in the sheet. They are detected by their column name (first row). Letter casing does not matter when the names are read.

Here follows a list with columnnames and their function.

### Matrixvak	
This column contains the name of the matrix-tile. All rules using the same name will be grouped together. "Matrixvak" is the grouping on the highest level.

### score in matrixvak	
This column either contains a percentage or the text `n.v.t.`. The percentage indicates how much the indicator (in the column `indicator`) is scaled towards the total of this matrix-tile.

### indicator	
This column contains the name of an indicator in the current matrix tile. All rules using the same indicator-name and matrix-tile-name will be grouped together.

### score in indicator
This column either contains a percentage or the text `n.v.t.`. The percentage indicates how much the question (in the column `question`) is scaled towards the total of this indicator.

### vraag
This column contains text of a analysis question or calculation. Under this name will the formula and statistics be presented.

### antwoordformule	
This column contains a formula. The formula will be executed for each participant of the *selection*. For more information about formula's see the *Formulas* section.

### groepsformule	
When all calculations on participant level are done and the answers are numeric, a average is calculated. This average can be used in the formula of this column.
The average of the answers of this line will be available under the name `value`. For more information about formula's see the *Formulas* section.

Variable mappings
-----------------
This file must contain a mapping between the analysis document and the checkmarket questions. Because all checkmarket values are numbered in order of the questions, a total remapping must be done if a question is inserted or removed from the set. To have a centric overview of the variables used, a mapping is created, so that after a question mutation not all formula's in the analysis sheet need to be rechecked.

The format of this sheet is simple. The first column contains the names used in the formula's. The second column contains the corresponding field in the checkmarket resultset.

The first row of the sheet is reserved for column names and will not be used as a mapping.

Configuration of the tool
=========================
All configuration is done in the `run.rb` file. You'll need to configure the filenames of the used files here, and define the output files and participant sets.

	parser = Runner.new \
		:scoring_definition => "config/analysis.csv",
		:value_mapping => "config/mapping.csv",
		:panel_document => "config/checkmarket_results.csv"

I hope this part speaks for itself.

Defining output sets
--------------------
After the parser part as described above, the output sets need to be defined.
They have the folling format:

	# comments can be placed after a hash (#) token.
	parser.run_with_filter "my_result.html", "My result title" do |filter|
		filter.question "question_id", "value"
		filter.question "other_question_id", "value", "alternate_value"
		
		filter.meta_data "field", "value"
	end

The filter part can contain multiple rules how to determine wich participant is included in the performed calculations.
After a `filter.question` statement the identifier of the question field must be given (surrounded by double quotes). For example: `"q1"`.
After that, one or multiple values can be given for that field. This means that this field **MUST** contain one of those provided values. If the value is not in the given set, that participant is excluded from the calculation. Also, the participant rule must pass *all* tests provided in the filter section.
To indicate that an empty value is allowed the term `nil` can be used.

### example:

	# - Eindhoven - KP + IP - BCRO+Legal - iedereen (totaal ingevuld + niet totaal ingevuld)
	parser.run_with_filter "iedereen.html", "Eindhoven - KP + IP - BCRO+Legal - iedereen" do |filter|
		filter.question "q1", "6" # Eindhoven
		filter.question "q2", "1", "2" # IP + KP
		filter.question "q3", nil, "1", "2", "3", "8" # Bouw + Civiel + Ruimtelijke ontwikkeling + Legal
	end

Running the tool
================
Start a ruby prompt, and navigate to the appropriate folder. (under windows this is probably `\\msysgit\\msysgit\\survey_parser`)

	ruby run.rb
	
The tool will run the analysis rules over the selected participants over the checkmarket-results and output its files in .html form.

Formula calculations
====================
Formula's can be used on participant rule leven and on grouped-participant rule level. Formula's can contain:

- numbers: `1`, `4.3`, `-4.2`
- texts: `"Hello"`
- functions: `SUM(1, 4, 2)`
- variables: `5 + value`
- parenthesis: `5 + (10.3 * 2)`
- percentages: `50%` (these will be converted to `0.5`) 33% and 66% will be converted to 1/3 and 2/3 so they have an infinite precision (33.33333% and 66.66666%)
- nil: `nil` this means 'no value' when `nil` is used in an operation, the result will always be `nil`. (`5 + nil = nil`)

Operations:
-----------
Operations are symbols that perform a calculation operation. They have a left-side argument and a right-side argument.

	left-side + (operation) right-side

the following operations are supported:

- addition (+): the right-side is added to the left-side `5 + 3 = 8`
- subtraction (-): the right-side is subtracted from the left-side `5 - 3 = 2`
- multiplication (*): the left-side is multiplied by the right side `5 * 3 = 15`
- division (/): the left-side is divided by the right side `15 / 3 = 5`
- power (^): the left-side is multiplied by the power of the right side `5 ^ 2 = 25`

Functions:
----------
Functions are terms, followed by parenthesis. Between the parenthesis, arguments can be provided for the function. Arguments are separated by comma's.
Terms always start by a letter, and can include underscores and numbers.
The following functions are available:

**SUM(argument1, argument2, ..., argumentN)** Adds all arguments together. nil arguments are ignored.
Examples:

	sum(1, 2, 3, 5, 8) = 19
	sum(1, nil, 3.4) = 4.4
	sum() = nil
	sum(nil) = nil

**MAX(argument1, argument2, ..., argumentN)** returns the highest value from the provided arguments. nil arguments are ignored.
Examples:

	max(1, 2, 3, 4) = 4
	max(5, 3.4, 8, 2) = 8
	max(nil, 4, 2) = 4
	max() = nil
	
**MIN(argument1, argument2, ..., argumentN)** returns the smallest value from the provided arguments. nil arguments are ignored.
Examples:

	min(1, 2, 3, 4) = 1
	min(5, 3.4, 8, 2) = 2
	min(nil, 4, 2) = 2
	min() = nil

**AVG(argument1, argument2, ..., argumentN)** returns the average value from the provided arguments. nil arguments are ignored.
Examples:

	avg(1, 2, 3, 4) = 2.5
	avg(5, 3.4, 8, 2) = 4.6
	avg(nil, 4, 2) = 3
	avg() = nil

It is prevered to use `AVG` over addition and division, because:

	1 + 5 + value + 2 / 4
	
	value = 3
	1 + 5 + value + 2 / 4 = 2.75
	AVG(1, 5, value, 2) = 2.75

	value = nil
	1 + 5 + value + 2 / 4 = nil
	AVG(1, 5, value, 2) = 2.66667
	
**SELECT(index, choice1, coiche2, ..., choiceN)** returns the selected choice based on index. index of nil returns nil.
Examples:

	select(1, 5, 6) = 5
	select(2, 5, 6) = 2
	select(0, 5, 6) = nil
	select(3, 5, 6) = nil
	select(3, 5, 6, 7, 8, 9) = 7	
	select(nil, 4, 2) = nil
	select(1) = nil
	select() = nil

**EMPTY(value)** returns 1 if the given value is empty, 0 otherwise.
Examples:

	empty(5) = 0
	empty(0) = 0
	empty(nil) = 1
	empty("Amsterdam") = 0
	empty("") = 1
	
Variables
---------



