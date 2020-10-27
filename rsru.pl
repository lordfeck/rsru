#!/usr/bin/env perl

# Thransoft RSRU
# Collation and generation of software listings for a static website.
# Licence: GPLv3. See "licence.txt" for full details.
# Author: Thran. Authored: 09/09/2020

# With Thanks: https://stackoverflow.com/questions/63835994/

use strict;
use warnings;
use v5.10;

# Begin user-configurable
my $tplinc = "./html";      # Where shall I find my easel?
my $entrydir = "./entries"; # Where shall I find my work?
my $out = "./rsru";         # Where shall I place my finished work?
my $tpl = "$tplinc/rsru_template.html"; # What is my easel named?
my $debug = 0;
my $verbose = 1;

# Default cats are always generated, even if empty.
# hitherto unknown cats will be appended to this list if found.
my @cats = ("utility", "media", "sysadmin", "gfx", "dev");

# End usr config, begin function and global vars.
my %entryKvs;
my $entryId;

# List of known keys for each entry
my @knownKeys = qw(title version category interface img_desc os_support order date_added desc);

# Dump everything we've gathered into our KVS to stdout, format nicely. Intended for verbose mode.
sub dump_kvs {
    print "Dumping contents of entry KVS. All keys read in: ";
    print (keys %entryKvs, "\n");

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        say "EID: $entryId";
        while (my ($key, $val) = each (%$hashRef)) {
            say "KEY: $key. VAL: $val";
        }
    }
}

# Print gathered entries into our template files. Incomplete. TODO: complete.
sub print_templates {

    while (my ($entryId, $hashRef) = each (%entryKvs)) {
        say "EID: $entryId";
        foreach (@knownKeys) {
            say "KEY: $_. VAL: $entryKvs{$entryId}{$_}";
        }
    }

    open(TPL, "$tpl");
    say <TPL>;
}

sub read_entry {
    ($entryId) = $_[0];
    open (ENTRY, '<', "$entrydir/$entryId") or die "Couldn't open $entrydir/$entryId";
    #FIXME: This should be a new variable for clarity's sake
    $entryId =~ s/\.txt//;

    my %entryData;
    while (<ENTRY>) {
        # Skip comments (hash-commenced lines)
        next if /^#/;
        # Lines with a colon have a key, lines without are descriptions
        if (/:/) {
            chomp;
            my ($key, $val) = split /:\s*/; 
            $entryData{$key} = $val;
            print "KEY: $key VALUE: $val\n" if ($debug);
        } else {
            # $_ means current line... '_' LOOKS LIKE A LINE... BRILLIANT!
            $entryData{desc} .= $_;
        }
    }
    say "DESC: $entryData{desc}" if ($debug);
    close ENTRY;

    return \%entryData;
}

# End Fndefs, begin exec.
say "RSRU starting. Master template: $tpl";

# Check we have what's needed.
die "Template file $tpl not found, cannot continue." unless -f $tpl;
mkdir $out unless -d $out;

opendir(ENTRIES, "$entrydir") or die "Directory of entries not found."; 
# Read in entries, exclude dotfiles
my @entries = grep !/^\./, readdir ENTRIES;
closedir ENTRIES;
say "Entrydir listing: @entries" if ($debug);

say "==> Begin read of $entrydir contents ==>";
$entryKvs{$entryId} = read_entry $_ for @entries;

print (keys %entryKvs, " Keys in entrykvs. $entryId (last read)\n") if ($debug);
print (values %entryKvs, " values in entrykvs.\n") if ($debug);

say "<== Read Finished <==";

dump_kvs if ($verbose);

say "<== Begin template interpolation... ==>";
say "Forthcoming, soon to be at the ready. But that day is not today. Apologies, The Management.";
#print_templates;
say "<== Template interpolation finished ==>";

say "RSRU finishing. Closing filehandles.";
close TPL;
