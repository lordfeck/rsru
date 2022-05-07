#===============================================================================
# RSRU user-configurable constants for BLANDBLOG
# Don't be daft: This is not executable alone. Do not amend the key names.
#===============================================================================

#======================================================================
# Path setup, template include dir
my $tplRoot = "./tpl";  # Root template dir (for all templates & common)
#======================================================================
(
    # Target: dev or production. Dev uses relative URLs, production uses live URL
    target => "dev",

    # Production URL, excluding forward stroke 
    liveURL => "http://www.example.com",

    # Path Configuration
    tplRoot => "$tplRoot",
    tplinc => "${tplRoot}/bland",  # Template include dir
    entrydir => "./entries_samples/bland",
    out => "./output",
    # Wipe destination directory before writing output files
    clearDest => 0,

    # Presentation Config

    # Filename Prefix, prepended to all output HTML
    siteName => "Bland blog",
    siteHeaderDesc => "It's not pretending to be anything different.",
    siteHomepageHeader => "LATEST SCRIBBLES",
    siteHomepageDesc => "I endeavour to please.",
    maxPerPage => 10,
    maxHpHighlights => 6,
    showCatTotal => 1,

    # RSS Configuration (requires XML::RSS)
    rssEnabled => 1,
    rssFilepath => "rss.xml",       # Saved at the root of the output path
    rssEntryMax => 10,
    rssLang => "en",
    rssCopyright => "No Copyright",

    # Imaging configuration (requires GD)
    imagesEnabled => 1,
    thumbnailSize => "300x300",
    imgSrcDir => "./img",
    imgDestDir => "img",            # Destination subdir, appended to liveURL or out path
    imgToJpeg => 1,                 # Convert fullres PNG to JPEG
    noClobberImg => 1,              # Skip images if they already exist
    
    #======================================================================
    # Edit these to modify entry and template keywords
    #======================================================================
    # These default cats are always generated, even if empty.
    # Hitherto unknown cats will be appended to a derived array if found.
    cats => ["life", "opinions", "reviews"],
    # List of known keys for each entry
    knownKeys => [qw(title category desc summary img_desc date is_highlight)],
    # Necessary keys. RSRU will fail if these are not present in any entry.
    necessaryKeys => [qw(title category desc date)],
    # Description for each category, will appear on the first page of each
    catDesc => {
        life => "Snapshots of the everyday.",
        opinions => "You'll hear them.",
        reviews => "Books, music, films, what works and what doesn't.",
    },
    #======================================================================

    # Master template and any other blank HTML templates
    # Typically, these should not be altered.
    tpl => "rsru_base.html",
    blankEntry => "rsru_entry.html",
    blankEntryImg => "rsru_entry_img.html",
    blankCatEntry => "rsru_cat.html",
    blankTplHp => "rsru_index.html",
    blankTplHpEntry => "rsru_hp_entry.html",
    blankTplNav => "pagination_nav.html",
    rssBlockTop => "rsru_rss_top.html",
    rssBlockBottom => "rsru_rss_bottom.html",
    # Logging levels
    debug => 0,
    verbose => 0,

)

