#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU v1.0
# Collation and generation of software listings for a static software catalogue.
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020
# WWW: http://soft.thran.uk
# 
# With Thanks: https://stackoverflow.com/questions/63835994/
#===============================================================================

use strict;
use warnings;
use v5.10;

use File::Copy;
use Time::Piece;
use List::Util qw(first);
use Cwd qw(getcwd);

#===============================================================================
# Read in user-configurable values
#===============================================================================

my %uc = do getcwd . "/conf.pl";
die 'Problem reading config' if $!;
# Copy cats list from the user conf and make it a mutable array.
my @cats = @{$uc{cats}};

#===============================================================================
# End usr config, begin function defs and global vars.
#===============================================================================
my %entryKvs;       # Master key-value store, holds all read-in entries
my $entryId;        # Entry-id variable of current working entry, used for reads
my $tplTop;         # The 'top' half of the per-category template
my $tplBottom;      # The 'bottom' half of the same. Entries will go between
my $tplEntry;       # The blank HTML for each entry
my $tplCatTab;      # Blank HTML for each category
my $tplHp;          # Blank HTML for homepage
my $tplHpEntry;     # Blank HTML for entries on the homepage
my $tplNav;         # Blank HTML for nav section
my %catsFilledEntries;      # Hash of filled entries in HTML for each category
my $writtenOut = 0; # A count of written out files.
my $writtenEntries = 0;     # total count of written entries in all files
my $baseURL = '.';  # Relative is default

# Consts
my $DATE_FORMAT = "%Y-%m-%d";
my $MAX_CATS = 8;
my $MIN_ENTRIES = 5;
my $MAX_ENTRIES = 5;
my $YES = 'yes';
my $NO_SUMMARY = '';
my $TPL_EMPTY_CAT = "<h1>Notice</h1><p>This category is currently empty. Finely-curated entries are forthcoming!</p>";

# List of known keys for each entry
my @knownKeys = @{$uc{knownKeys}};
my @necessaryKeys = @{$uc{necessaryKeys}};

# Declare Functions (but don't define yet)
sub sort_entries;
sub sort_all_entries;
sub get_highlighted_entries;

# Useful Helper Function.
# ARGUMENTS: Filename to be read in. RETURNS: Contents of file as string.
sub read_whole_file {
    my $fileName = shift;
    my $fileContent;
    open(my $fh, "$fileName") or die ("Fatal: couldn't open $fileName!");
    $fileContent .= $_ while <$fh>;
    close $fh;
    return $fileContent;
}

# Dump everything we've gathered into our KVS to stdout, format nicely. Intended for verbose mode.
sub dump_kvs {
    print "Dumping contents of entry KVS. All keys read in: ";
    print (keys %entryKvs, "\n");

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        say "EID: $entryId" if $uc{debug};
        while (my ($key, $val) = each (%$hashRef)) {
            say "KEY: $key. VAL: $val";
        }
    }
}

# Read in the template, look for the RSRU markers, split it.
sub read_partition_template {
    open(TPL, $uc{tpl}) or die ("Fatal: Couldn't open template $uc{tpl}!");
    
    while (<TPL>) {
        last if /\s*(<!--BEGIN RSRU-->)/;
        $tplTop .= $_;
    }

    # Skip everything that isn't for the "easel" area
    while (<TPL>) { last if /\s*(<!--END RSRU-->)/; }

    # Then read the rest
    while (<TPL>) { $tplBottom .= $_; }
    close TPL;
}

# Iterate through an entry and ensure all the specified necessary (necified?)
# keys are present. Failure stops everything!
# ARGS: Entry ID
sub verify_necessary_keys {
    my $entryId = shift;
    foreach my $key (@necessaryKeys){
        die "Key $key missing from $entryId.txt; please add $key: <value> to the entry file!" unless (first { /$key/ } keys %{$entryKvs{$entryId}});
    }
}

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = shift;
    my $filledEntry = $tplEntry;
    
    verify_necessary_keys ($entryId);

    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        if ($key eq "date") {
            my $date = $entryKvs{$entryId}{'date'}->strftime('%d/%m/%Y');
            $filledEntry =~ s/{% $key %}/$date/g;
        } else {
            $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/g;
        }
    }
    # Do anchor for links from elsewhere. Anchor is currently entry Id (key in %entryKvs)
    $filledEntry =~ s/{% KEY %}/$entryId/g;
    
    say "Filled $entryId:\n$filledEntry" if ($uc{debug});
    $writtenEntries++;
    return \$filledEntry;
}

# Clear destination before write (configurable)
# Currently, will not clear any subdirs in $uc{out}
sub clear_dest {
    for my $unwanted (glob "$uc{out}/*.*") {
        next if -d $unwanted;
        say "clear_dest: Removing $unwanted..." if ($uc{debug});
        unlink $unwanted or warn("Problem deleting $unwanted\n");
    }
}

# Copy any resources to outdir. For now, this is only CSS.
sub copy_res {
    for my $cssFile (glob "$uc{tplinc}/*.css") {
        copy($cssFile,"$uc{out}/") or die ("Problem copying $cssFile to $uc{out}.");
    }
}

# Insert title and description to master template top
sub paint_desc {
    $tplTop =~ s/{% HEAD_TITLE %}/$uc{siteName}/;
    $tplTop =~ s/{% HEAD_DESC %}/$uc{siteHeaderDesc}/;
}

sub generate_cat_tabs {
    my $activeCat = shift;
    my $catFn; # Cat Filename (used for hyperlinks)
    my $cwCat;  # Current Working Category
    my $filledCats; # Tabs of categories, eventually filled

    # handle special case of index.html
    $catFn = "$baseURL/index.html";
    $cwCat = $tplCatTab;
    $cwCat =~ s/{% CAT_NAME %}/home/;
    $cwCat =~ s/{% CAT_URL %}/$catFn/;
    if ($activeCat eq 'index'){
        $cwCat =~ s/{% IS_ACTIVE %}/active/;
    }
    $filledCats .= $cwCat;

    # Now fill in the category tabs
    foreach my $cat (@cats) {
        $catFn = "${baseURL}/$uc{fnPre}_${cat}_1.html";
        $cwCat = $tplCatTab;
        $cwCat =~ s/{% CAT_NAME %}/$cat/;
        $cwCat =~ s/{% CAT_URL %}/$catFn/;
        # Remove IS_ACTIVE from home tab
        $filledCats =~ s/{% IS_ACTIVE %}//;
        # Set only the active cat to have the HTML class "active"
        if ($cat eq $activeCat) {
            $cwCat =~ s/{% IS_ACTIVE %}/active/;
        }  else {
            $cwCat =~ s/{% IS_ACTIVE %}//;
        }
        $filledCats .= $cwCat;
    }
    return $filledCats;
}

# Calculate the max page index for a category
# Note: This will be easier once entryKvs is restructured
# ARGS: Cat name
# RETURNS: Max page index
sub calculate_max_page {
    my $catName = shift;
    my $catSize = 0;
    foreach (keys %entryKvs){
        $catSize++ if ($entryKvs{$_}{category} eq $catName);
    }
    use integer;
    return ($catSize / $uc{maxPerPage}) + 1; 
}


# Prepare the navbar.
# Arguments: Cat Name, Current Index, isLast
# Returns: prepared navbar HTML
sub prep_navbar {
    my ($catName, $pgIdx, $isLast) = @_;
    my $cwNavbar = $tplNav;
    my %url;
    my ($prev, $next, $max);

    $max = calculate_max_page($catName);
    $url{max} = "$baseURL/$uc{fnPre}_${catName}_$max.html";

    if ($pgIdx == 1) {
        $url{prev} = "#"     
    } else {
        $prev = $pgIdx - 1;
        $url{prev} = "$baseURL/$uc{fnPre}_${catName}_$prev.html";
    }
    if ($isLast eq 'no'){
        $next = $pgIdx + 1;
        $url{next} = "$baseURL/$uc{fnPre}_${catName}_$next.html";
    } else {
        $url{next} = "#";
    }

    $cwNavbar =~ s/{% IDX_PREV %}/$url{prev}/;
    $cwNavbar =~ s/{% IDX_NEXT %}/$url{next}/;
    $cwNavbar =~ s/{% IDX %}/$pgIdx/;
    $cwNavbar =~ s/{% MAX %}/$max/;
    $cwNavbar =~ s/{% MAX_URL %}/$url{max}/;
    return $cwNavbar;
}

# Insert the cat links. called by paint_template when it is used to process
# each category page.
# ARGUMENTS: active cat, page number
sub prep_tpltop {
    my ($activeCat, $pgIdx) = @_; 
    my $pageTxt = "";
    $pageTxt = "(Page $pgIdx)" if $pgIdx;
    my $catTabs = generate_cat_tabs($activeCat);
    my $cwTplTop = $tplTop;
    $cwTplTop =~ s/{% RSRU_TITLE %}/$uc{siteName} :: $activeCat $pageTxt/;
    $cwTplTop =~  s/{% RSRU_CATS %}/$catTabs/;
    return $cwTplTop;
}

# Print gathered entries into our template files. Do one for each cat.
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = shift;
    my $currentEntry;
    my $pgIdx = 1;
    my $cwTplTop = prep_tpltop($catName, $pgIdx); 
    my $catIsEmpty = 1;

    my $entryIdx = 0;
    my $outFn = "$uc{out}/$uc{fnPre}_${catName}_${pgIdx}.html";
    my $navBar;

    open (my $fh, '>', $outFn);
    print $fh $cwTplTop;

    print $fh "<p id=\"catDesc\">$uc{catDesc}{$catName}</p>" if ($uc{catDesc}{$catName} && $pgIdx == 1);

    for my $entryId (sort_entries $catName) {
        say "$entryIdx is entry index. for $entryId" if $uc{debug};
        # Handle pagination
        if ($entryIdx >= $uc{maxPerPage}) {
            print $fh prep_navbar($catName, $pgIdx, 'no');
            print $fh $tplBottom; 
            $pgIdx++;
            close $fh;
            $outFn = "$uc{out}/$uc{fnPre}_${catName}_${pgIdx}.html";
            open ($fh, '>', $outFn);
            print $fh prep_tpltop($catName, $pgIdx); 
            say "NEW PAGE!! $pgIdx" if $uc{debug};
            $writtenOut++;
        }
        next unless ($entryKvs{$entryId}{"category"} eq $catName);
        $entryKvs{$entryId}{pgIdx} = $pgIdx;
        $currentEntry = entrykvs_to_html $entryId;
        $catIsEmpty = 0;
        print $fh $$currentEntry;
        $entryIdx++;
    }
    
    print $fh $TPL_EMPTY_CAT if $catIsEmpty;

    
    print $fh prep_navbar($catName, $pgIdx, 'yes');
    print $fh $tplBottom; 
    # Increment grand total for reporting files written after process completes
    $writtenOut++;
    close $fh;
}

# Use the $tplHpEntry template to generate a list of entries for the homepage.
# ARGUMENTS: An array of entry key names
sub generate_entries_hp {
    my $hpEntries = "";
    my ($cwHpEntry, $catFn, $cat, $date);

    for my $entry (@_) {
       $cwHpEntry = $tplHpEntry;
        
       $cwHpEntry =~ s/{% ENTRY_NAME %}/$entryKvs{$entry}{"title"}/;
       if ($entryKvs{$entry}{'summary'}) {
           $cwHpEntry =~ s/{% ENTRY_DESC %}/$entryKvs{$entry}{'summary'}/;
       } else {
            say "No summary found for $entry; its summary will be omitted on homepage." if $uc{verbose};
            $cwHpEntry =~ s/{% ENTRY_DESC %}/$NO_SUMMARY/;
       }
       $cat = $entryKvs{$entry}{"category"};
       $cwHpEntry =~ s/{% ENTRY_CAT %}/$cat/;
       $date = $entryKvs{$entry}{'date'}->strftime('%d/%m/%Y');
       $cwHpEntry =~ s/{% ENTRY_DATE %}/$date/;
       $catFn = "$baseURL/$uc{fnPre}_${cat}_$entryKvs{$entry}{pgIdx}.html#$entry";
       $cwHpEntry =~ s/{% ENTRY_CAT_URL %}/$catFn/;
       $hpEntries .= $cwHpEntry;
    }
    return $hpEntries;
}

# Print the homepage. ARGS: None.
sub paint_homepage {
    my $outFn = "$uc{out}/index.html";
    
    my $cwTplTop = prep_tpltop('index'); 
    my (@latest, @highlights);

    open (my $fh, '>', $outFn) or die ("Fatal: Couldn't open $uc{out}Fn for writing!");
    print $fh $cwTplTop;
        
    $tplHp =~ s/{% RSRU_HPHD %}/$uc{siteHomepageHeader}/;
    $tplHp =~ s/{% RSRU_HPDESC %}/$uc{siteHomepageDesc}/;
    $tplHp .= "<p>Current total entries: " . scalar %entryKvs . "</p>";

    print $fh $tplHp;

    if (scalar (%entryKvs) >= $MIN_ENTRIES){
        @latest = sort_all_entries($MAX_ENTRIES); 
        print $fh '<h2>Latest Entries</h2>';
        print $fh generate_entries_hp(@latest);
    } else {
        say "Total entries are below $MIN_ENTRIES. Skipping latest on homepage.";
    }
    
    @highlights = get_highlighted_entries; 
    if (@highlights) {
        print $fh '<h2>Highlights</h2>';
        print $fh generate_entries_hp(@highlights);
    }
    print $fh $tplBottom; 
    $writtenOut++;
    close $fh;
}


# Sort the given cat's entries. TODO sort order: DATE > RANK > ENTRY_NAME, currently only DATE, ENTRY NAME.
# Argument: Cat name. [If not supplied, sort ALL entries by date]
# Returns: A list that consists of ordered entry IDs for each cat
sub sort_entries {
    my $cwCat = shift;
    my %entryDate;

    for my $entryId (keys %entryKvs) {
        if ($entryKvs{$entryId}{"category"} eq $cwCat) {
           $entryDate{$entryId} = $entryKvs{$entryId}{"date"};
        } 
    }

    # First sort alphabetically, then by date
    my @sorted = sort keys %entryDate;
    @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } @sorted;

    say "SORTED: @sorted, Length: ". scalar @sorted . " " if $uc{debug};
    return @sorted;
}

# Do the same as above but with no heed to each category. Just returns a list
# of all entries sorted by date.
# ARGUMENTS: max index
sub sort_all_entries {
    my $max = shift;
    my %entryDate;
    for my $entry (keys %entryKvs) {
        say "entry $entry and $entryKvs{$entry}{'date'}" if $uc{debug};
        $entryDate{$entry} = $entryKvs{$entry}{"date"};
    }
    # First sort alphabetically, then by date
    my @sorted = sort keys %entryDate;
    @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } @sorted;
    say "Sorted are @sorted." if $uc{debug};
    return @sorted[0..$max-1];
}

sub get_highlighted_entries {
    my @highlights;
    foreach (keys %entryKvs) {
        next unless ($entryKvs{$_}{is_highlight});
        push (@highlights, $_) if ($entryKvs{$_}{is_highlight} eq $YES);
    }
    return @highlights;
}

# Read the contents of an individual entry file. Entryfiles are plain text and in
# a simple format. See 'samplesoft1.txt' for an example.
# Argument: Entry ID (equivalent to the name of its text file)
# Returns a reference to a key-value store of all obtained key-values from the entryfile.
sub read_entry {
    $entryId = shift;
    open (ENTRY, '<', "$uc{entrydir}/$entryId") or die "Couldn't open $uc{entrydir}/$entryId";
    $entryId =~ s/\.txt//;

    my %entryData;
    while (<ENTRY>) {
        # Skip comments (hash-commenced lines)
        next if /^#/;
        # Lines with a colon have a key, lines without are descriptions
        if (/:/) {
            chomp;
            # Watch for URLs! spilt will split at each colon it finds, unless restrained as such:
            my ($key, $val) = split /:\s+/; 
            if ($key eq "date"){
                $entryData{"date"} = Time::Piece->strptime($val, $DATE_FORMAT); 
                next;
            } elsif ($key eq "category"){
                unless ( first { /$val/ } @cats ){
                    say "New category found: $val." if $uc{verbose};
                    push (@cats, $val);
                }
            }
            $entryData{$key} = $val;
            print "KEY: $key VALUE: $val\n" if ($uc{debug});
        } else {
            # $_ means current line... '_' looks like a line
            $entryData{desc} .= $_;
        }
    }
    say "$entryId DESC: $entryData{desc}" if ($uc{debug});
    close ENTRY;

    return \%entryData;
}

# Read in the contents of the entrydir. Calls read_entry
# on each text file therein. We will use this to fill our
# entryKvs.
sub read_entrydir {
    opendir(ENTRIES, "$uc{entrydir}") or die "Directory of entries not found."; 
    # Read in entries, exclude dotfiles
    my @entries = grep !/^\./, readdir ENTRIES;
    closedir ENTRIES;
    say "Entrydir listing: @entries" if ($uc{debug});

    # $entryID is assigned inside read_entry
    $entryKvs{$entryId} = read_entry $_ for @entries;
    print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($uc{debug});
    print (values %entryKvs, " values in entrykvs.\n") if ($uc{debug});
    dump_kvs if ($uc{verbose});
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================
say "RSRU starting. Master template: $uc{tpl}";

if (scalar @ARGV and ($ARGV[0] eq '-p') or $uc{target} eq 'production') {
    $baseURL = $uc{liveURL};
    say "Production mode configured, base URL: $baseURL";
}

# Check we have what's needed.
die "Template file $uc{tpl} not found, cannot continue." unless -f $uc{tpl};
mkdir $uc{out} unless -d $uc{out};

say "==> Begin read of $uc{entrydir} contents ==>";
read_entrydir;
say "CATS: @cats" if ($uc{debug});
warn "Warning: More than $MAX_CATS exist in file. Template may be malformed.\n" if (scalar (@cats) > $MAX_CATS);
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;

# Now load in our entry template file. This should be a HTML table with the appropriate areas for our data marked out
$tplEntry = read_whole_file($uc{blankEntry});

# Load in blank HTML for homepage items. Fills the global vars tplHp and tplHpEntry.
$tplHp = read_whole_file($uc{blankTplHp});
$tplHpEntry = read_whole_file($uc{blankTplHpEntry});
$tplNav = read_whole_file($uc{blankTplNav});
# Load in the HTML for each category in the catbar
$tplCatTab = read_whole_file($uc{blankCatEntry});
say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
clear_dest if ($uc{clearDest});
copy_res;
paint_desc;
foreach my $cat (@cats) { paint_template $cat; }
paint_homepage;
say "<== Template interpolation finished. ==>";

say "RSRU complete. Wrote $writtenEntries total entries into $writtenOut files.";
