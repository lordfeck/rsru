#===============================================================================
# RSRU user-configurable constants
# Don't be daft: This is not executable alone. Do not ammend the key names.
#===============================================================================

# Path setup, template include dir
my $tplinc = "./html";

(
    # Path Configuration

    tplinc => "$tplinc",
    entrydir => "./entries",
    out => "./output",

    # Master template and any other blank HTML templates

    tpl => "$tplinc/rsru_template.html",
    blankEntry => "$tplinc/rsru_entry.html",
    blankCatEntry => "$tplinc/rsru_cat.html",
    blankTplHp => "$tplinc/index.html",
    blankTplHpEntry => "$tplinc/rsru_hp_entry.html",

    # Presentation Config

    # Filename Prefix, prepended to all output HTML
    fnPre => "rsru",
    siteName => "RSRU",
    siteHeaderDesc => "Really Small, Really Useful software listings.",
    siteHomepageHeader => 'Welcome to RSRU!',
    siteHomepageDesc => "How do you do? Please enjoy your time browsing our lightweight software catalogue.",
    
    # Logging levels
    debug => 0,
    verbose => 0,
    
    # Wipe destination directory when writing
    clearDest => 1,

    # These default cats are always generated, even if empty.
    # Hitherto unknown cats will be appended to a derived array if found.
    cats => ["utility", "media", "sysadmin", "gfx", "dev"],
)

