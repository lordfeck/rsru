RSRU Template Guide (incomplete)
===================

The template format for RSRU is very straightforward, as in keeping with the project ethos.

## Template files and fields

There are a number of HTML files which RSRU reads in. Then rsru overwrites set fields with values read from the entries. This way, a website is generated.

Fields look as follows: `{% RSRU_TITLE %}` in a style reminiscent of Django. This makes it obvious to the parser which aspects should be overwritten.

The template may be changed at liberty. RSRU will work, provided the fields and the HTML comment in the base template file are all present.

### Files

`rsru_template.html`: The base template file. Each page rendered by rsru.pl will build atop this file.

**FIELDS**

`RSRU_TITLE`, `HEAD_TITLE`, `HEAD_DESC`, `RSRU_CATS`.

TITLE and HEAD TITLE are the configured title in conf.pl, as is the description. Cats is the list of categiories with a link to the first page of each category.

**SPECIAL NOTE**

Everything between the HTML comments `<!--BEGIN RSRU-->` and `<!--END RSRU-->` is where further rendering happens. RSRU reads in until it hits BEGIN RSRU, then looks for END RSRU. From there it reads to the bottom. This is how we generate a consistent header and footer. Thus, everything in between these markers of the template file is discarded.

**TODO:** Document other files and fields if necessary. Though, it is quite obvious what each file and field does after running the script.


### Switching Template
It is easy to switch template. Simply point the `$tplinc` variable in `conf.pl` to another directory containing your template files.

The files in this template directory should match those mentioned in this document, which are exactly those supplied in the example code.
