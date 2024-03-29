RSRU.pl Dev Log
=================

# Release History

## R3.2 (22/04/2023)
Various fixes to the templates. Also fixed the calculation of max highlighted issues on the homepage, some problems with substituting items on the footer.

Fairly minor but they'd annoy me if I found these bugs in someone else's work.

## R3.1 (07/05/2022)
Bugs fixed:
- max entries on HP may be arbitrary, previously rsru would only show "latest entries" if there were at least 5
- `{% STATIC_ROOT %}` is now applied to the top of templates, meaning other static assets like images may be included in the heading of templates

Features added:
- New template styles: New News and Bland Blog. This proves that RSRU can build more than just catalogue websites.

## R3 (04/04/2022)
Bugs fixed:

- Category bar now displays properly on mobile
- Table styling improved
- Navbar back links were broken
- Odd/even category pages weren't paginated properly
- RSS max entries wasn't enforced
- The category wasn't shown in RSS feeds
- Other layout glitches

Features added:

- Command line switches to show version, show help, change config file,
     change output dir, force rebuild site, force production mode
- Thumbnail support
- Image processing to convert JPG to PNG
- New paths using each category name as a sub directory
- Total contents of each category may be shown on its page
- Template files may avail of a common template directory, to reduce duplication
- Highlighted entries have special CSS applied
- Images may be skipped for conversion if they already exist
- Homepage has a configurable max number of highlights
- Sample config files and entries for each theme
- Extensive user documentation covering installation, templating and everyday use

## R2 (27/11/2021)
Bugs fixed:

- Entries on homepage are generated only if there are enough
- Date output is correctly formatted (was US, now UK format)
- Template layout improvements
- Colons caused descriptions to be ignored (misread as entry keys)

Features added:

- RSS feed generation
- New template: linkcat
- Add nocache headers to templates
- Report total entries on homepage
- Add date to homepage lists
- Descriptions for category pages


## R1 (03/08/2021)
Initial release. Everything planned was implemented. Some bugs were introduced.

