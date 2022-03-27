_RSRU_ HOWTO
============

User's Guide covering installation, configuration, customisation and utilisation. Valid for Release 3.

# RSRU in brief

RSRU, or _Really Small Really Useful_, is a static website builder written in Perl.
It currently specialises in building "catalogue" style websites, so it is ideal for building a website dedicated to collections.

Sample templates are included for building a link catalogue or a software catalogue. These may be adapted to fit your needs.

PRACTICAL AND CONVENIENT TO THOSE ALREADY FAMILIAR WITH THE UNIX TERMINAL

# Installation

## System Requirements

- Windows, Linux or Mac OSX. RSRU has been tested on Windows and Linux but should also work on OSX.
- Perl v5.18 or later (exact version hasn't been tested, but RSRU is very vanilla Perl so probably works on older versions too).

## Readying Perl

If you are on Windows, first [install Strawberry Perl](https://strawberryperl.com/). If you are using Linux or OSX, your operating system has good taste and already includes Perl.

If you have never used Perl before, run `cpan` from a command window and agree to all the defaults. This will allow installation of helper modules for RSRU.

## Installing Helper Modules (Optional)

You may wish to include pictures in your website. You may also wish to generate RSS feeds so your eager audience can stay informed of your latest discoveries.
In these cases, RSRU needs some help to perform these duties. *If you opt against installing these, RSRU is still usable but will be without RSS and graphics processing.*

**NOTE:** To install the graphics module on Linux, another library must first be installed. This is not necessary on Windows.

Open a command window and run the following as root/sudo on Debian:

```
# apt install build-essential libgd-dev
```

Or on Void Linux:

```
# xbps-install base-devel gd-devel
```

I haven't used other Linux versions, but if you find how to install the GD dev library for that distro it should work. You can also install the Perl modules directly using your distro's packager, if you prefer and have the knowhow.

### Installing the CPAN modules

CPAN is the pakager for Perl. It will fetch and install our helper modules. To install these, open a command line on your Windows or \*nix box and run:

```
$ cpan install XML::RSS GD
```

You'll also need `Time::Piece` if you're using anything in the Fedora/RH/CentOS family.

## Download and extract RSRU

Download the latest version of RSRU from [Thransoft](https://soft.thran.uk) or [GitHub](https://github.com/lordfeck/rsru/releases). Extract the tar or zipfile to a convenient location in your filesystem.

```
$ tar -xvzf rsru_r3.tar.gz
```

On Windows, you can use the Windows file extraction wizard, 7zip, WinZip, WinRAR, pkzip or whichever archiever is nearest to hand.

# Configuration

The default config file `./conf.pl` defaults to the softcat style. Other styles are available, currently only `linkcat`.

## Edit conf.pl
Before the script may be used, it is first necessary to tailor `conf.pl` to your liking. The config file is just a plain Perl hash, which means you can include any other Perl code you fancy. It also means that when editing the values, please be careful to edit only between the "quote marks" and leave all the values to the left of the fat arrows `=>` alone.

Most config options are structured as follows:

`optionName => "optionValue",`

Just edit "optionValue" to be whatever you wish. There are adequate comments explaning the options, but further explanation follows:

`liveURL` specifies the base URL for production mode. This is the web address for where you intend to publish the site built by RSRU.

`tplinc` should point to the source directory containing the template files. This value points to the template directory matching each sample config file. Change this to change the style RSRU uses to generate your website.

`out` is the directory where RSRU will write the website it has built. This defaults to `./output`. You may view these output files in a web browser after they are built.

`entrydir` where to read the entry files from. Default: `entries/`.

`clearDest` set to 1 if you want RSRU to wipe the output directory before writing the generated website. Set it to 0 if you want the old files left alone. Manually override this by running RSRU with the `-r` command line flag, which will set RSRU to wipe the output folder.

## Presentation config
Edit the following fields in conf.pl to set some descriptive text fields on the site. `siteName` is a particularly important one!

`siteName`, `siteHeaderDesc`. Site Name is used in the HTML "TITLE" element and the masthead of each page. HeaderDesc is a brief description printed beneath.

`siteHomepageHeader`, `siteHomepageDesc` are used to fill in the homepage.

`maxPerPage` the maximum number of entries that will be printed before a new page is made. Used for each category.

`maxHpHighlights` the maximum number of highlighted entries that will be shown on the homepage.

`showCatTotal` set to 1 if you want the total amount of entries displayed at the top of each category page. Set to 0 if you don't want this.

## RSS Config

`rssEnabled` set to 1 if you want an RSS feed generated. Set to 0 if not. When set to 0, links and meta tags for RSS are not generated.

`rssFilepath` set a name for the generated RSS feed. Usually the defualt is fine.

`rssEntryMax` set a value for the maximum number of entries that will be included in the RSS feed. 

`rssLang` set the language tag for RSS.

`rssCopyright` set your copyright licence for RSS (eg, your name, or creative commons).

## Image config

`imagesEnabled` set to 1 to enable thumbnail generation and image copying/linking for each entry that has images. Set to 0 to disable all images.

`thumbnailSize` set to the resolution you want for the thumbnails in the format `<WIDTH>x<HEIGHT>`. The default of 150x150 is a sane value. Note: You will also need to edit the template CSS file to match this value.

`imgSrcDir` the directory where RSRU will look for its images.

`imgDestDir` where RSRU will write the final images. This directory will be under the root of your website's URL.

`imgToJpeg` if set to 1, all source images will be converted to JPEG. If set to 0, only the thumbnails are rendered as JPEG and the original image will simply be copied to the destDir.

`noClobberImg` a timesaving measure. Images will not be re-converted if they already exist under the destDir. Set to 1 to enable, 0 to disable. Run RSRU with the `-r` command line flag if you want to ignore this setting and overwrite all images.

## Category config

This section uses Perl lists. Please edit only the values inside the `[qw( EDIT_THESE )],` list, i.e. between the parentheses. If you mess with the list formatting RSRU and its big brother Perl will not like you.

`cats` a Perl list of the default categories. The categories in your entries should match one of these, but this isn't necessary. Unknown categories will have pages generated regardless.

`knownKeys`

`necessaryKeys`

`catDesc`

## Logging levels

`debug`

`verbose`

# Customisation

Now that you've RSRU ready and waiting on your system, it is time to decide which template you prefer.

(screenshots of both, how to switch keywords in the tpl)

## Templating
The template files are read by default from `./tpl/softcat`. Each HTML file under here is essential and used to weave the output.

See [TPL_README](TPL_README.md), which will describe each file and how to customise it. (This guide is due a revamp)


# Utilisation

## Add an entry to RSRU
Add a new file under `./entries/`. It should have the extension `.txt`.

Fill in the text file like the example that follows. Each of the 'fields' have their key terminated by a colon. then the field's value is the rest of the line. Eg, `title: New Entry Making An Entrance` will produce the key `title` and the value `New Entry Making An Entrance`. These fields are split then used to fill in the appropriate parts of the blank template files.

The rest of the file is read until the end and any text there serves as a description. It can be anything in HTML.

### An example entry - softcat

This uses the "softcat" template.

```
title: Sample Soft
version: 1
category: utility
interface: console
img_desc: screenshot of sample soft
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

**NOTE:** The minimum required fields are: _title, version, category, date, desc_. These are coded as `necessaryKeys` in `conf.pl`. It is possible to change this list, should you see fit.

### An example entry - linkcat

### Running RSRU

Once you have added all your entries, run `./rsru.pl` and it will get busy weaving your pages. By default, these will be written to `./output/`.

**NICE:** The homepage will link to your 5 most recent entries, if at least 5 have been added.

Any entries with the value 'yes' for `is_highlight:` will be added to the 'Highlights' section on the homepage.

## Command Line Flags (optional)
- `-p` for *P*roduction mode. Call `./rsru.pl -p`. The configured live URL will be used as the base URL for all internal links. Without this flag, relative links are instead used.
- `-c <conf>` to load in the specified *C*onfig file. Call `./rsru.pl -c <conf_file>.pl`. The specified configuration file is used to configure your site.
- `-r` for *R*ebuild. Will ignore no-clobber img option and will wipe outout dir.
- `-h` for *H*elp. Prints command line options then exits.
- `-v` for *V*ersion. Prints release information then exists.
- *None*. It is possible to call `./rsru.pl` with no command line flags. It will read in `./conf.pl` and build its configured website.

## Publishing
RSRU has no self-publishing features. While such is possible with the right CPAN modules, such is beyond the scope of this project. 

The author suggests use of [rsync](http://rsync.samba.org) to drop the files on your server. Or script scp, sftp, ftp to do it for you. Alternatively, you could upload RSRU to your web server and set the output directory to somewhere under the www-root.


## TODO:
edit entries, images howto, describe all keys for entries

run it

command line flags

how to publish it

sample entries & conf files for all tpls...
