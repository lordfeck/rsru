#===============================================================================
# RSRU user-configurable constants
# Don't be daft: This is not executable alone. Do not amend the key names.
#===============================================================================

# Path setup, template include dir
#=======================================================================
my $tplRoot = "./tpl";  # Root template dir (for all templates & common)
#=======================================================================

# NOTE: 1 is ENABLED, 0 is DISABLED
(
    # Target: dev or production. Dev uses relative URLs, production uses live URL
    target => "dev",

    # Production URL, excluding trailing stroke. May be a subdir
    liveURL => "http://www.example.com",

    # Path Configuration
    tplRoot => "$tplRoot",
    tplinc => "${tplRoot}/softcat",  # Template include dir
    entrydir => "./entries_samples/softcat",
    out => "./output",
    # Wipe destination directory before writing output files
    clearDest => 0,

    # Presentation Config
    siteName => "RSRU",
    siteHeaderDesc => "Really Small, Really Useful software listings.",
    siteHomepageHeader => 'Welcome to RSRU!',
    siteHomepageDesc => "How do you do? Please enjoy your time browsing our lightweight software catalogue.",
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
    thumbnailSize => "150x150",
    imgSrcDir => "./img",
    imgDestDir => "img",            # Destination subdir, appended to liveURL or out path
    imgToJpeg => 1,                 # Convert fullres PNG to JPEG
    noClobberImg => 1,              # Skip images if they already exist
    
    #======================================================================
    # Configure category and entry names. These must match the fields in your template files
    #======================================================================
    # These default cats are always generated, even if empty.
    # Hitherto unknown cats will be appended to a derived array if found.
    cats => [qw(utility media sysadmin gfx dev)],
    # List of known keys for each entry
    knownKeys => [qw(title version category interface img_desc img_src os_support order date desc dl_url is_highlight)],
    # Necessary keys. RSRU will fail if these are not present in any entry.
    necessaryKeys => [qw(title version category date desc)],
    # Description for each category, will appear on the first page of each
    catDesc => {
        utility => "Small programs for accomplishing a specific task",
        media => "Sound & Video",
        sysadmin => "Controlling & profiling your system",
        gfx => "Computer graphics creation",
        dev => "Developemnt tools and aids, compilers, languages",
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

