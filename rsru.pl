#!/usr/bin/env perl

#===============================================================================
# Thransoft RSRU
# Collation and generation of software listings for a static software catalogue.
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020
#
# With Thanks: https://stackoverflow.com/questions/63835994/
#===============================================================================

use strict;
use warnings;
use v5.10;
use File::Copy;
use Time::Piece;
use List::Util qw(first);

#===============================================================================
# Begin user-configurable
#===============================================================================
my $tplinc = "./html";
my $entrydir = "./entries";
my $out = "./rsru";
my $tpl = "$tplinc/rsru_template.html";
my $blankEntry = "$tplinc/rsru_entry.html";
my $blankCatEntry = "$tplinc/rsru_cat.html";
my $blankTplHp = "$tplinc/index.html";      # Blank HTML for the homepage
my $blankTplHpEntry = "$tplinc/rsru_hp_entry.html";
my $fnPre = "rsru";
my $siteName = "RSRU";
my $siteHeaderDesc = "Really Small, Really Useful software listings.";
my $siteHomepageHeader = 'Welcome to RSRU!';
my $siteHomepageDesc = "How do you do? Please enjoy your time browsing our lightweight software catalogue.";
my $debug = 0;
my $verbose = 0;
my $clearDest = 1;

# Default cats are always generated, even if empty.
# hitherto unknown cats will be appended to this list if found.
my @cats = ("utility", "media", "sysadmin", "gfx", "dev");

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
my %catsFilledEntries;      # Hash of filled entries in HTML for each category
my $writtenOut = 0; # A count of written out files.

# Consts
my $DATE_FORMAT = "%Y-%m-%d";
my $MAX_CATS = 8;
my $MIN_ENTRIES = 5;
my $MAX_ENTRIES = 5;
my $YES = 'yes';
my $NO_SUMMARY = 'No summary necessary.';

# List of known keys for each entry
my @knownKeys = qw(title version category interface img_desc os_support order date desc dl_url is_highlight);
my @necessaryKeys = qw(title version category order date desc);

# Declare Functions (but don't define yet)
sub sort_entries;
sub sort_all_entries;
sub get_highlighted_entries;

# Useful Helper Function.
# ARGUMENTS: Filename to be read in. RETURNS: Contents of file as string.
sub read_whole_file {
    my $fileName = $_[0];
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
        say "EID: $entryId" if $debug;
        while (my ($key, $val) = each (%$hashRef)) {
            say "KEY: $key. VAL: $val";
        }
    }
}

# Read in the template, look for the RSRU markers, split it.
sub read_partition_template {
    open(TPL, "$tpl") or die ("Fatal: Couldn't open template $tpl!");
    
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

# Takes a key and prints the HTML for its contents
# ARGUMENTS: Entry ID
# RETURNS: Scalar reference to woven template
sub entrykvs_to_html {
    my $entryId = $_[0];
    my $filledEntry = $tplEntry;
    
    # Find and replace, boys. Find and replace.
    foreach my $key (@knownKeys) {
        if ($key eq "date") {
            my $date = $entryKvs{$entryId}{'date'}->strftime('%m/%d/%Y');
            $filledEntry =~ s/{% $key %}/$date/g;
        } else {
            $filledEntry =~ s/{% $key %}/$entryKvs{$entryId}{$key}/g;
        }
    }
    # Do anchor for links from elsewhere. Anchor is currently entry Id (key in %entryKvs)
    $filledEntry =~ s/{% KEY %}/$entryId/g;
    
    say "Filled $entryId:\n$filledEntry" if ($debug);
    return \$filledEntry;
}

# Clear destination before write (configurable)
# Currently, will not clear any subdirs in $out
sub clear_dest {
    for my $unwanted (glob "$out/*.*") {
        next if -d $unwanted;
        say "clear_dest: Removing $unwanted..." if ($debug);
        unlink $unwanted or warn("Problem deleting $unwanted\n");
    }
}

# Copy any resources to outdir. For now, this is only CSS.
sub copy_res {
    for my $cssFile (glob "$tplinc/*.css") {
        copy($cssFile,"$out/") or die ("Problem copying $cssFile to $out.");
    }
}

# Insert title and description to master template top
sub paint_desc {
    $tplTop =~ s/{% HEAD_TITLE %}/$siteName/;
    $tplTop =~ s/{% HEAD_DESC %}/$siteHeaderDesc/;
}

sub generate_cat_tabs {
    my $activeCat = $_[0];
    my $catFn; # Cat Filename (used for hyperlinks)
    my $cwCat;  # Current Working Category
    my $filledCats; # Tabs of categories, eventually filled

    # handle special case of index.html
    $catFn = 'index.html';
    $cwCat = $tplCatTab;
    $cwCat =~ s/{% CAT_NAME %}/'home'/;
    $cwCat =~ s/{% CAT_URL %}/$catFn/;
    if ($activeCat eq 'index'){
        $cwCat =~ s/{% IS_ACTIVE %}/active/;
    }
    $filledCats .= $cwCat;

    # Now fill in the category tabs
    foreach my $cat (@cats) {
        $catFn = $fnPre."_".$cat.".html";
        $cwCat = $tplCatTab;
        $cwCat =~ s/{% CAT_NAME %}/$cat/;
        $cwCat =~ s/{% CAT_URL %}/$catFn/;
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

# Insert the cat links. called by paint_template when it is used to process
# each category page.
# ARGUMENTS: active cat, page number
sub prep_tpltop {
    my ($activeCat, $pageNo) = @_; # FIXME pageNo isn't set for some reason
    my $pageTxt = "";
    $pageTxt = "(Page $pageNo)" if $pageNo;
    my $catTabs = generate_cat_tabs($activeCat);
    my $cwTplTop = $tplTop;
    $cwTplTop =~ s/{% RSRU_TITLE %}/$siteName :: $activeCat $pageTxt/;
    $cwTplTop =~  s/{% RSRU_CATS %}/$catTabs/;
    return $cwTplTop;
}

# Print gathered entries into our template files. Do one for each cat.
# ARGUMENTS: Cat name
sub paint_template {
    my $catName = $_[0];
    my $outFn = "$out/". $fnPre . "_" . $catName . ".html";
    my $currentEntry;
    my $pageNo = 1;
    my $cwTplTop = prep_tpltop($catName, $pageNo); 

    open (my $fh, '>', $outFn);
    print $fh $cwTplTop;
    
    for my $entryId (sort_entries $catName) {
        next unless ($entryKvs{$entryId}{"category"} eq $catName);
        $currentEntry = entrykvs_to_html $entryId;
        print $fh $$currentEntry;
    }

    print $fh $tplBottom; 
    $writtenOut++;
    close $fh;
}

# Use the $tplHpEntry template to generate a list of entries for the homepage.
# ARGUMENTS: An array of entry key names.
sub generate_entries_hp {
    my $hpEntries = "";
    my ($cwHpEntry, $catFn, $cat);

    for my $entry (@_) {
       $cwHpEntry = $tplHpEntry;
        
       $cwHpEntry =~ s/{% ENTRY_NAME %}/$entryKvs{$entry}{"title"}/;
       if ($entryKvs{$entry}{'summary'}) {
           $cwHpEntry =~ s/{% ENTRY_DESC %}/$entryKvs{$entry}{'summary'}/;
       } else {
            say "No summary found for $entry; its summary will be omitted on homepage." if $verbose;
            $cwHpEntry =~ s/{% ENTRY_DESC %}/$NO_SUMMARY/;
       }
       $cat = $entryKvs{$entry}{"category"};
       $cwHpEntry =~ s/{% ENTRY_CAT %}/$cat/;
       $catFn = $fnPre."_".$cat.".html#$entry";
       $cwHpEntry =~ s/{% ENTRY_CAT_URL %}/$catFn/;
       $hpEntries .= $cwHpEntry;
    }
    return $hpEntries;
}

# Print the homepage. ARGS: None.
sub paint_homepage {
    my $outFn = "$out/index.html";
    
    my $cwTplTop = prep_tpltop('index'); 
    my (@latest, @highlights);

    open (my $fh, '>', $outFn) or die ("Fatal: Couldn't open $outFn for writing!");
    print $fh $cwTplTop;
        
    $tplHp =~ s/{% RSRU_HPHD %}/$siteHomepageHeader/;
    $tplHp =~ s/{% RSRU_HPDESC %}/$siteHomepageDesc/;

    print $fh $tplHp;

    if (scalar (@latest) < $MIN_ENTRIES){
        @latest = sort_all_entries($MAX_ENTRIES); 
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


# Sort the given cat's entries. TODO sort order: DATE > RANK > ENTRY_NAME, currently only DATE.
# Argument: Cat name. [If not supplied, sort ALL entries by date]
# Returns: A list that consists of ordered entry IDs for each cat
sub sort_entries {
    my $cwCat = $_[0];
    my %entryDate;

    for my $entryId (keys %entryKvs) {
        if ($entryKvs{$entryId}{"category"} eq $cwCat) {
           $entryDate{$entryId} = $entryKvs{$entryId}{"date"};
        } 
    }

    my @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } keys %entryDate;

    say "SORTED: @sorted, Length: ". scalar @sorted . " " if $debug;
    return @sorted;
}

# Do the same as above but with no heed to each category. Just returns a list
# of all entries sorted by date.
# ARGUMENTS: max index
sub sort_all_entries {
    my $max = $_[0];
    my $itr = 0;
    my %entryDate;
    for my $entry (keys %entryKvs) {
        break if ($itr == $max);
        say "entry $entry and $entryKvs{$entry}{'date'}" if $debug;
        $entryDate{$entry} = $entryKvs{$entry}{"date"};
        $itr++;
    }
    my @sorted = sort { $entryDate{$b} <=> $entryDate{$a} } keys %entryDate;
    say "Sorted are @sorted." if $debug;
    return @sorted;
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
    $entryId = $_[0];
    open (ENTRY, '<', "$entrydir/$entryId") or die "Couldn't open $entrydir/$entryId";
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
                    say "New category found: $val." if $verbose;
                    push (@cats, $val);
                }
            }
            $entryData{$key} = $val;
            print "KEY: $key VALUE: $val\n" if ($debug);
        } else {
            # $_ means current line... '_' looks like a line
            $entryData{desc} .= $_;
        }
    }
    say "$entryId DESC: $entryData{desc}" if ($debug);
    close ENTRY;

    return \%entryData;
}

# Read in the contents of the entrydir. Calls read_entry
# on each text file therein. We will use this to fill our
# entryKvs.
sub read_entrydir {
    opendir(ENTRIES, "$entrydir") or die "Directory of entries not found."; 
    # Read in entries, exclude dotfiles
    my @entries = grep !/^\./, readdir ENTRIES;
    closedir ENTRIES;
    say "Entrydir listing: @entries" if ($debug);

    # $entryID is assigned inside read_entry
    $entryKvs{$entryId} = read_entry $_ for @entries;
    print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($debug);
    print (values %entryKvs, " values in entrykvs.\n") if ($debug);
    dump_kvs if ($verbose);
}

#===============================================================================
# End Fndefs, begin exec.
#===============================================================================
say "RSRU starting. Master template: $tpl";

# Check we have what's needed.
die "Template file $tpl not found, cannot continue." unless -f $tpl;
mkdir $out unless -d $out;

say "==> Begin read of $entrydir contents ==>";
read_entrydir;
say "CATS: @cats" if ($debug);
say "Warning: More than $MAX_CATS exist in file. Template may be malformed." if (scalar (@cats) > $MAX_CATS);
say "<== Read Finished <==";

say "==> Begin read of template files ==>";
read_partition_template;

# Now load in our entry template file. This should be a HTML table with the appropriate areas for our data marked out
$tplEntry = read_whole_file($blankEntry);

# Load in blank HTML for homepage items. Fills the global vars tplHp and tplHpEntry.
$tplHp = read_whole_file($blankTplHp);
$tplHpEntry = read_whole_file($blankTplHpEntry);

# Load in the HTML for each category in the catbar
$tplCatTab = read_whole_file($blankCatEntry);
say "<== Read Finished <==";

say "<== Begin template interpolation... ==>";
clear_dest if ($clearDest);
copy_res;
paint_desc;
foreach my $cat (@cats) { paint_template $cat; }
paint_homepage;
say "<== Template interpolation finished. Wrote $writtenOut files. ==>";

say "RSRU complete.";
