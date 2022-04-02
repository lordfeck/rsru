RSRU Template Guide (incomplete)
===================

The template format for RSRU is very straightforward, as in keeping with the project ethos.

## Template files and fields

There are a number of HTML files which RSRU reads in. Then rsru overwrites set fields with values read from the entries. This way, a website is generated.

Fields look as follows: `{% RSRU_TITLE %}` in a style reminiscent of Django. This makes it obvious to the parser which aspects should be overwritten.

The template may be changed at liberty. RSRU will work, provided the fields and the HTML comment in the base template file are all present.

### Files



### Switching Template
It is easy to switch template. Simply point the `$tplinc` variable in `conf.pl` to another directory containing your template files.

The files in this template directory should match those mentioned in this document, which are exactly those supplied in the example code.
