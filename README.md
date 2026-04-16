## SQL-Cleaning-Customer-Orders
### Using MySQL to clean data from a table of customer orders.
<br/>

The objective of this project was to demonstrate cleaning and normalizing data using MySQL, as it is important to have a cleaning pipeline and prevent innaccurate conclusions.

The dataset has a number of errors. Some of which are different cases for first and last name, product names, and duplicate rows.

I attempted to write portions of the SQL CTE to act as a catch-all for certain data that is possible to standardize. 
Some errors required more specifically-targted approaches, such as quantity entered as a text value, rather than an integer.

Other issues, such as correcting the upper and lower cases for names, was possible to fix, but would break if 3 or more names were entered into single field.
Data platforms such as BigQuery and Snowflake also have functions such as INITCAP() that can solve this in a more concise manner.
