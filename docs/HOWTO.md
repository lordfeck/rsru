_RSRU_ HOWTO
============

User's Guide covering installation, configuration, customisation and utilisation. Valid for Release 3.

# RSRU in brief

RSRU, or _Really Small, Really Useful_, is a static website builder written in Perl.
It currently specialises in building "catalogue" style websites, so it is ideal for building a website dedicated to collections.

Sample templates are included for building a link catalogue or a software catalogue. These may be adapted to fit your needs.

PRACTICAL AND CONVENIENT TO THOSE ALREADY FAMILIAR WITH THE UNIX TERMINAL

## How RSRU works, in brief

When invoked, RSRU does the following:

- Reads in HTML template files from `./tpl/<template_name>/`
- Reads text files of individual entries from `./entries/`
- Determines the categories for each entry
- Sorts the entries of each category into alphabetical then chronological order
- Writes HTML pages for each entry containing all its entries.

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

CPAN is the packager for Perl. It will fetch and install our helper modules. To install these, open a command line on your Windows or \*nix box and run:

```
$ cpan install XML::RSS GD
```

You'll also need `Time::Piece` if you're using anything in the Fedora/RH/CentOS family.

## Download and extract RSRU

Download the latest version of RSRU from [Thransoft](https://soft.thran.uk) or [GitHub](https://github.com/lordfeck/rsru/releases). Extract the tar or zipfile to a convenient location in your filesystem.

```
$ tar -xvzf rsru_r3.tar.gz
```

On Windows you can use the Windows file extraction wizard, 7zip, WinZip, WinRAR, pkzip or whichever unzipper is nearest to hand.

# Configuration

The default config file `./conf.pl` defaults to the *softcat* style. Other styles are available, currently only *linkcat*. See the sample config files in the `conf_samples/` directory for to try each of these styles. A full explanation is given later.

## Edit conf.pl
Before the script may be used, it is first necessary to tailor `conf.pl` to your liking. The config file is just a plain Perl hash, which means you can include any other Perl code you fancy. It also means that when editing the values, please be careful to edit only between the "quote marks" and leave all the values to the left of the fat arrows `=>` alone.

Most config options are structured as follows:

`optionName => "optionValue",`

Just edit "optionValue" to be whatever you wish. There are adequate comments explaining the options, but further explanation follows:

`liveURL` specifies the base URL for production mode. This is the web address for where you intend to publish the site built by RSRU.

`tplinc` should point to the source directory containing the template files. This value points to the template directory matching each sample config file. Change this to change the style RSRU uses to generate your website. By default it includes `tplroot` but you may point it to any valid directory on your system, so long as it includes the necessary template files and preferably also the `static/rsru.css` file.

`out` is the directory where RSRU will write the website it has built. This defaults to `./output`. You may view these output files in a web browser after they are built.

`entrydir` where to read the entry files from. Default: `entries/`.

`clearDest` set to 1 if you want RSRU to wipe the output directory before writing the generated website. Set it to 0 if you want the old files left alone. Manually override this by running RSRU with the `-r` command line flag, which will set RSRU to wipe the output folder. **Note: This will erase everything in the output directory. If you want additional files copied to your output directory, include them in your template's `static` directory.**

## Presentation config
Edit the following fields in conf.pl to set some descriptive text fields on the site. `siteName` is a particularly important one!

`siteName`, `siteHeaderDesc`. Site Name is used in the HTML "TITLE" element and the masthead of each page. HeaderDesc is a brief description printed beneath.

`siteHomepageHeader`, `siteHomepageDesc` are used to fill in a heading and description on your site's homepage. The description should describe your website's purpose and its contents to a visitor.

`maxPerPage` pagination control. This sets the maximum number of entries that will be printed in each category page before a new page is made.

`maxHpHighlights` the maximum number of highlighted entries that will be shown on the homepage.

`showCatTotal` set to 1 if you want the total amount of entries displayed at the top of each category page. Set to 0 if you don't want this.

## RSS Config

`rssEnabled` set to 1 if you want an RSS feed generated. Set to 0 if not. When this is set to 0 links and meta tags for RSS are not generated.

`rssFilepath` set a filename for the generated RSS feed. Usually the default is fine. This filename will be included in the RSS meta tags and the RSS footer link.

`rssEntryMax` set a value for the maximum number of entries that will be included in the RSS feed. 

`rssLang` set the language tag for RSS.

`rssCopyright` set your copyright licence for RSS (eg, your name or creative commons).

## Image config

`imagesEnabled` set to 1 to enable thumbnail generation and image copying/linking for each entry that has images. Set to 0 to disable all images.

`thumbnailSize` set to the resolution you want for the thumbnails in the format `<WIDTH>x<HEIGHT>`. The default of 150x150 is a sane value. Note: You will also need to edit the template CSS file to match this value.

`imgSrcDir` the directory where RSRU will look for its images.

`imgDestDir` where RSRU will write the final images. This directory will be under the root of your website's URL.

`imgToJpeg` if set to 1, all source images will be converted to JPEG. If set to 0, only the thumbnails are rendered as JPEG and the original image will simply be copied to the destDir.

`noClobberImg` a timesaving measure. Images will not be re-converted if they already exist under the destDir. Set to 1 to enable, 0 to disable. Run RSRU with the `-r` command line flag if you want to ignore this setting and overwrite all images.

## Category config

This section uses Perl lists. Please edit only the values inside the `[ EDIT_THESE ],` list, i.e. between the brackets. **The category list and known keys list must be single words, or phrases with underscores. Do not use spaces.** If you mess with the list formatting RSRU and its big brother Perl will not like you.

`cats` a Perl list of the default categories. The categories in your entries should match one of these, but this isn't necessary. Unknown categories will have pages generated regardless. **Do not use spaces for the cat names, but you may use underscores or hyphens in their place.**

`knownKeys` A list of keys that are possible to be in each entry text file. Each of these keys should also exist in the rsru_entry.html and rsru_entry_img.html template files. When building an entry, RSRU will look for each of these keys in each of your entry text files, then fill their values into their placeholders in the template. **NOTE:** *desc* should always be in this list.

`necessaryKeys` A subset of the above list. All these keys will be mandatory for each entry. If RSRU encounters an entry without any of these keys, it will print an error message and exit. 

`catDesc` A Perl array mapping each category name to a description. Formatted as follows: `CAT_NAME => "category description",`. The category description is printed at the top of each category page in your website. To exclude a description for a certain category, just make its string empty. `CAT_NAME` should match the category name in the `cats` list described above.

## Logging levels

By default, RSRU doesn't say much while it is working. If you need to know what it is doing with your precious entries, here is how to make it talk more.

`verbose` If your website isn't being built right set this to `1` to enable verbose logging. It may offer clues to where you have went wrong.

`debug` If "verbose" didn't remedy your malady, set this one to `1`. Things will be very noisy and this may actually make matters less clear.

# Customisation

Now that you've RSRU ready and waiting on your system, it is time to decide which template you prefer.

Currently, two templates are available: linkcat and softcat. 

![linkcat screenshot](../misc/linkcat.png)

![softcat screenshot](../misc/rsru3.png)

You can easily try either using the command line switches:

`./rsru.pl -c conf_samples/conf_linkcat.pl`

`./rsru.pl -c conf_samples/conf_softcat.pl`

Pick one of these styles and tweak the keywords, css and HTML layout to your liking. A guide instructing you in this very task follows.

## Templating
The template files are read by default from `./tpl/<TPL_NAME>/`. Each HTML file under here is essential and used to weave the output. There is also a `common` directory which holds HTML template files that are common to all templates *(This is possible because much of the style is just handled with CSS)* but it is trivial to override the common template files.

The template format for RSRU is very straightforward. RSRU maps placeholder fields in the template files to keyword values in your entry text files. To illustrate this practically:

You have an entry called `excellent.txt`. Inside it:

```
title: Excellent entry!
rating: 100/10

They don't come any better.
```

RSRU reads in a template file called `rsru_entry.html`. Inside it there is:

```
<h1>{% title %}</h1>
<div>{% desc %}</div>
<div>{% rating %}</div>
```

RSRU then takes the entry text file, finds the `{% placeholder_fields %}` inside the HTML template file and replaces those with the values in the text file. 

You may customise any part of these HTML files. RSRU will then take your superb hypertext craftsmanship and make it into a full fledged website. All it asks is that you leave the special keyword fields intact inside each file. Otherwise things will be weird and broken, like you probably were in school. An explanation of each file and its fields follows.

### Common template directory contents

These are found under `./tpl/common/`.

**rsru_base.html**

The base template file. Each page rendered by rsru.pl will build atop this file.

**Fields in rsru_base.html**

Special fields are in capital letters. They are in the same `{% KEYWORD_BLOCK %}` format mentioned above. These are replaced with values sourced from `conf.pl` or other template files.

`FEEDBLOCK_TOP`: Where the RSS feed meta link (if enabled) is transplanted. This is the filled contents of `rsru_rss_top.html` are written.

`RSRU_TITLE`, `HEAD_TITLE`: These are replaced with your configured site name in conf.pl. This is the value mapped to `siteName` in the conf file.

`HEAD_DESC`: This is replaced with the value of `siteHeaderDesc` in `conf.pl`. This is the header description displayed under the title on every page.

`RSRU_CATS`: A link to the homepage and links to the first page of each category are rendered here. The links are generated using the template file `rsru_cat.html`. This list appears at the top of every page.

`FEEDBLOCK_BOTTOM` Where the RSS feed link (if enabled) is transplanted. This is the filled contents of `rsru_rss_bottom.html` are written. It is a link to your RSS feed at the bottom of each page.

**SPECIAL NOTE**

Everything between the HTML comments `<!--BEGIN RSRU-->` and `<!--END RSRU-->` is where further rendering happens. RSRU reads in until it hits BEGIN RSRU, then looks for END RSRU. From there it reads to the bottom. This is how we generate a consistent header and footer. 

#### Other common template files

**rsru_index.html**

Unique text for the homepage, displayed above the latest entries list.

**Fields in rsru_index.html**

`RSRU_HPHD`: Homepage header. Replaced with the contents of `siteHeaderDesc` in conf.pl. Intended to be a friendly greeting for your visitors.

`RSRU_HPDESC`: Homepage description. Replaced with the contents of `siteHomepageDesc`  in conf.pl. A good place to describe the contents and purpose of your website.

**rsru_cat.html**

Used to generate a link to each of your categories at the top of every page.

**Fields in rsru_cat.html**

`IS_ACTIVE`: Replaced with the text `active` to apply the CSS class for an active link. This is applied to the pages of the currently active category. It provides a navigation aid in the link bar.

`CAT_URL`: The link to the first page of this category.

`CAT_NAME`: Replaced with the name of this category. The name of each category is sourced from the `cats` list in conf.pl is sourced from the `cats` list in conf.pl.

**pagination_nav.html**

Template for the pagination at the bottom of each category page. Links to next/previous pages. RSRU will create a new page for each category once the value of `maxPerPage` is exceeded. This template is used to find your way back and forwards through each category.

**Fields in pagination_nav.html**

`IDX_PREV`, `IDX_NEXT`: Links to the previous and next pages in this category.

`IDX`: Replaced with the current page number. Used to show to your visitors how far deep they are.

`MAX_URL`: A link to the final page in each category. Used to jump to the end.

`MAX`: The total number of pages in this category.

**rsru_hp_entry.html**

Template for individual entries linked from the homepage. Used to build lists of the latest entries and highlighted entries in your site.

**Fields in rsru_hp_entry.html**

`ENTRY_NAME`: The `name` of this entry. This is the value of `name` in its entry text file.

`ENTRY_DESC`: The description for this entry. This is the value of `summary` in its entry file. Optional.

`ENTRY_DATE`: The date of each entry. This is the value of the `date` key in its entry file.

`ENTRY_CAT`, `ENTRY_CAT_URL`: The name of its category and link to the category page of this entry.

**rsru_rss_top.html**

Made into an RSS link in the meta section of your pages.

**rsru_rss_bottom.html**

Made into an RSS link at the bottom of each page.

### Template files in the template root directory

These are found under `./tpl/<TEMPLATE_NAME>/`.

**rsru_entry.html**

The HTML template file that is filled in for each entry. RSRU will generate a category page for each category of entries you've specified. The entry pages will be filled with HTML for each entry generated from this template.

**Fields in rsru_entry.html**

`IS_HIGHLIGHT`: Sets the css classes to include `highlight` if the current entry is a highlight. Otherwise this is left blank. Intended for you to tweak the appearance of entries that are highlights, so they may be set apart from the others.

`KEY`: The entry "key". This is the same name as the entry text file. Used to generate an anchor tag on the page, so there is a convenient anchor link to each entry.

`desc`: Replaced with the description from each entry text file. This is the main text content of your entry. *The description is unique because it hasn't any keyword in the entry file.* Rather, it is the rest of the entry text file contents which may be anything in HTML. See further below under "utilisation" for an illustrated example.

**Other fields**

The other fields in this file match what you've specified in conf.pl's `knownKeys` list. Examples from the softcat conf.pl: `knownKeys => ["title", "version", "category", "interface", "img_desc", "img_src", "os_support", "order", "date", "desc", "dl_url", "is_highlight"],`

The values of each of these fields are taken from the keywords in each entry file. A description of how to use these in your config file and template file will be provided later.

**rsru_entry_img.html**

This HTML template file is identical to the one above, except for additional fields that allow for the inclusion of a thumbnail and a link to the full size image.

**Additional fields for imaging**

`img_full`: The link to the full resolution image for this entry in your website's image directory.

`img_tn`: The generated thumbnail image for each entry's image. Displayed and used as the hyperlink to the full resolution image.

`img_desc`: Sourced from the entry text file, this is the hover-over tooltip and alternate description used for each image.

### A note on the static directory

This is located at the path `./tpl/<TEMPLATE_NAME>/static/`.

Under here, `rsru.css` should be located. This is the base CSS file for the website. You may tailor the CSS here to match your desired layout and colour scheme. Some understanding of CSS and HTML is assumed.

This CSS file is included in the meta tags of each page, so its CSS properties and values are available on each page of your website.

All the contents of the static directory are copied to the root of the generated website. This makes it an ideal location to store your `favicon.ico`, other CSS files or any logos and common images that will be used throughout your website.

### Creating your own theme

To create your own theme, do the following:

1. Choose a pre-existing theme that closely matches your taste and interests. Copy its config file from `conf_samples/` to `./conf.pl`.

2. Copy the pre-existing theme's directory contents to a new directory under `./tpl/`.

3. Edit the HTML files and CSS under your new theme's root directory to suit your liking.

4. Edit `config.pl`'s tplRoot value to match your template directory root. Also while you are there, edit liveURL, siteName, siteHeaderDesc and the other fields to be values appropriate for your website.

5. Decide which possible keywords may be used in your entry files. Put these keywords into the `knownKeys` list in `conf.pl`. Also decide which keywords are mandatory for each entry and put these into the `necessaryKeys` list.

6. Edit `rsru_entry.html` and `rsru_entry_img.html` to include these keywords. You may also want to tweak the CSS to ensure they are laid out tidily.

7. If you wish to modify any of the `common` template files, simply copy these to your new template root directory. Then RSRU will use these instead of the common template files. The template root directory has priority over anything in `common`.

# Utilisation

Everyday usage for RSRU. How to fill your website with your entries.

## Add an entry to RSRU
Add a new file under `./entries/`. It should have the extension `.txt`.

Fill in the text file like the example that follows. Each of the 'fields' have their key terminated by a colon. then the field's value is the rest of the line. Eg, `title: New Entry Making An Entrance` will produce the key `title` and the value `New Entry Making An Entrance`. 

These fields are split then used to fill in the appropriate parts of the blank template files as described above. The `{% keyword %}` in `rsru_entry.html` will be replaced with the value for each of these fields.

The rest of the file is read until the end and any text there serves as a description. It can be anything in HTML.

### An example entry - softcat

This uses the "softcat" template.

```
title: Sample Soft
version: 1
category: utility
interface: console
img_desc: screenshot of sample soft
img_src: samplesoft_1.jpg
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

**NOTE:** The minimum required fields are: _title, version, category, date, desc_. These are coded as `necessaryKeys` in `conf.pl`. It is possible to change this list, should you see fit. When a necessary field is absent, RSRU will throw an error and stop its work. This is to serve as a useful reminder.

Just create an entry text file like this and put it under `entries/`. Give it a unique file name ending in `.txt.` **Do not use spaces**, rather, use underscores or hyphens for your entry name. The text file name is used as your entry name throughout RSRU, it will uniquely distinguish it from the others. It is also used as the anchor links on its category page.

**Categories**

Always give your entry a value for `category:`. This should be one of the categories in the `cats => ["cat1", "cat2", "catN"]` conf.pl list. This ensures your entry will appear under the correct category page.

**Dating**

Your entry also requires a date in the `date:` key. The date must be in the format `YYY-MM-DD`. This is essential for sorting your entries into chronological order. The date will also be shown in each entry's HTML table, if a field exists in the template for the date.

### An example entry - linkcat

```
title: ebay
is_highlight: no
url: https://www.ebay.co.uk
ecc: 8
heaviness: 8
date: 2002-03-01
category: fun
img_src: ebay-2002.png
img_desc: ebay back in the day

Cool auction site! <i>Please bid on my listings!!</i>
```

### A note on imaging

If the `GD` Perl module has been successfully installed, or is just available on your system, then RSRU will be able to generate thumbnails and link to the full resolution images for each entry on your site.

To include an image with your entry, simply save it under `img/` and name it whatever you like (no spaces in the filename is preferred). Then put the keyword `img_src: <your_image_name>` in the entry text file. This image will be copied to the `imgDestDir` and linked in your entry. Also, a thumbnail is generated and copied to this imgDestDir. The thumbnail is included in the entry's HTML and used as a hyperlink to the full resolution image.

It is actually optional to include the `img_src:` keyword in the entry text file. If you just save your image file with a filename that matches the entry text file name, RSRU will find it and use it as your entry's image.

RSRU currently supports both JPG and PNG image formats. Thumbnails are always saved as JPG.

### Running RSRU

Once you have added all your entries, run `./rsru.pl` and it will get busy weaving your pages. By default, these will be written to `./output/`.

RSRU will write a website into this output directory with the following structure:

```

index.html                  # Site Homepage
rsru.css                    # Master CSS template

<cat_name>/index.html       # Index page for this category
<cat_name>/2.html           # Second page for this category
<cat_name>/3.html           # Third page for this category, & so on

img/<entry_image>.jpg       # Image file for an entry    
img/<entry_image>_tn.jpg    # Thumbnail for the entry

```

**NICE:** The homepage will link to your 5 most recent entries, if at least 5 have been added.

Any entries with the value 'yes' for `is_highlight:` will be added to the 'Highlights' section on the homepage. They will also have additional CSS applied to distinguish them from the ordinary.

Entries will be sorted in the following schema: ALPHABETICAL ORDER then CHRONOLOGICAL ORDER. This means that the entries will always appear in the same order on each page. The sort order is newest first.

Open index.html in a web browser and look around. If you are happy with how this all looks, then run `./rsru.pl -p` to build the production version of your website. Copy this website to your host on the World Wide Web and tell all your friends. Relish in your creation. It's done!

## Command Line Flags (optional)
- `-p` for *P*roduction mode. Call `./rsru.pl -p`. The configured live URL will be used as the base URL for all internal links. Without this flag, relative links are instead used. Use production mode when you're building the live version of your website for the Internet. Use non-production mode when you're testing it on your local system.
- `-c <conf>` to load in the specified *C*onfig file. Call `./rsru.pl -c <conf_file>.pl`. The specified configuration file is used to configure your site.
- `-r` for *R*ebuild. Will ignore no-clobber img option and **will wipe everything** in the output dir before writing your website there.
- `-h` for *H*elp. Prints command line options then exits.
- `-v` for *V*ersion. Prints release information then exists.
- *None*. It is possible to call `./rsru.pl` with no command line flags. It will read in `./conf.pl` and build its configured website.

## Publishing
RSRU has no self-publishing features. While such is possible with the right CPAN modules, such is beyond the scope of this project. 

The author suggests use of [rsync](http://rsync.samba.org) to drop the files on your server. Or script scp, sftp, ftp to do it for you. Alternatively, you could upload RSRU to your web server and set the output directory to somewhere under the www-root.

## Final word

Thanks for reading through this HOWTO. I hope it has been comprehensive.

If anything is unclear, you are welcome to open a ticket on the [RSRU Github](https://github.com/lordfeck/rsru) page with your query. Bug reports and feature suggestions are also welcome.
