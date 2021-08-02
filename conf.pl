#===============================================================================
# RSRU user-configurable constants
# Don't be daft: This is not executable alone. Do not amend the key names.
#===============================================================================

# Path setup, template include dir

my $tplinc = "./html";

(
    # Target: dev or production. Dev uses relative URLs, production uses live URL
    target => "dev",

    # Production URL, excluding forward stroke 
    liveURL => "http://www.example.com",

    # Path Configuration

    tplinc => "$tplinc",
    entrydir => "./entries",
    out => "./output",

    # Presentation Config

    # Filename Prefix, prepended to all output HTML
    fnPre => "rsru",
    siteName => "RSRU",
    siteHeaderDesc => "Really Small, Really Useful software listings.",
    siteHomepageHeader => 'Welcome to RSRU!',
    siteHomepageDesc => "How do you do? Please enjoy your time browsing our lightweight software catalogue.",
    maxPerPage => 10,
    
    # These default cats are always generated, even if empty.
    # Hitherto unknown cats will be appended to a derived array if found.
    cats => ["utility", "media", "sysadmin", "gfx", "dev"],

    # Master template and any other blank HTML templates
    # Typically, these should not be altered.
    tpl => "$tplinc/rsru_template.html",
    blankEntry => "$tplinc/rsru_entry.html",
    blankCatEntry => "$tplinc/rsru_cat.html",
    blankTplHp => "$tplinc/index.html",
    blankTplHpEntry => "$tplinc/rsru_hp_entry.html",
    blankTplNav => "$tplinc/pagination_nav.html",

    # Logging levels
    debug => 0,
    verbose => 0,
    
    # Wipe destination directory before writing output files
    clearDest => 1,

)

