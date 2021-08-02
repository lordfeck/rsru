# Thransoft RSRU

## What is RSRU?
Simple static HTML page generator written in Perl. Intended for the sole task of generating my RSRU section, but may have broader usage potential. GPLv3 licence.

RSRU works only in HTML and CSS. There are fewer than 150 lines of CSS. That's living the simple life.

## What does RSRU mean?
*R*eally *S*mall, *R*eally *U*seful. It's the name of a section on my website which lists software matching the criteria of being really small and really useful.

## What does RSRU do?
RSRU will read each text file in the `entries/` directory. It will determine the title, description, category and other fields for each entry. These will be made into rows which are appended to web pages. It also generates a nice homepage for your website.

Each entry will belong to a category. Each category will appear as tab-style HTML pages.

## Configure RSRU
Before the script may be used, it is first necessary to tailor `conf.pl` to your liking.

### Command Line Flags

* `-p` Call `./rsru.pl -p` to use production mode. The configured live URL will be used as the base URL for all internal links.

## Add an entry to RSRU
Add a new file under `./entries/`. It should have the extension `.txt`.

Fill in the text file like the example that follows. Each of the 'fields' have their key terminated by a colon. then the field's value is the rest of the line. Eg, `title: New Entry Making An Entrance` will produce the key `title` and the value `New Entry Making An Entrance`. These fields are split then used to fill in the appropriate parts of the blank template files.

The rest of the file is read until the end and any text there serves as a description. It can be anything in HTML.

### An example entry

```
title: Sample Soft
version: 1
category: utility
interface: console
img_desc: img.jpg
os_support: Linux
order: 3
date: 2020-01-01
dl_url: http://www.themostamazingwebsiteontheinternet.com/
is_highlight: no
summary: Something short but interesting said here.
# Lines beginning '#' are skipped, i.e comments
# The rest of the file is the description in HTML
Sample soft offers no convenience to the user. It only exists to provide a sample for RSRU.
This is a new line.
This is <b>bold</b> to test HTML.
```

**NOTE:** The minimum required fields are: _title, version, category, order, date, desc_. These are coded as `@necessaryKeys` in `rsru.pl`.

### Running RSRU

Once you have added all your entries, run `./rsru.pl` and it will get busy weaving your pages. By default, these will be written to `./output/`.

**NICE:** The homepage will link to your 5 most recent entries, if at least 5 have been added.

Any entries with the value 'yes' for `is_highlight:` will be added to the 'Highlights' section on the homepage.

## Templating
The template files are read by default from `./html/`. Each HTML file under here is essential and used to weave the output.

FUTURE: see TEMPLATES.md, which will describe each file and how to customise it.

## Publishing
RSRU has no self-publishing features. While such is possible with the right CPAN modules, such is beyond the scope of this project. 

The author suggests use of [rsync](http://rsync.samba.org) to drop the files on your server. Or script scp, sftp, ftp to do it for you. Alternatively, you could upload RSRU to your web server and set the output directory to somewhere under the www-root.

## Requirements
* Perl, at least version 5.10 and List::Util present. This should be available in the standard library of most recent Perls.
* Anything that runs Perl. The author has tested only on Linux. Some I/O features should probably `use File;` for better Windows support.

### CPAN Modules
Presently, RSRU operates using only standard library modules. The project goals will not require any hard dependencies on any CPAN modules. Future non-essential features (eg, RSS) may depend upon CPAN modules, but RSRU will still perform its core duties without them.

## Future hackery for RSRU
* I've plans to hack it into a "microblogger" system. Think of a way to share clips of sites, quotes, images, whatever else.
* Run as CGI. This may be possible if we write to stdout instead of files. (_I've no interest in writing this, but the door is always open to friendly PRs..._)

