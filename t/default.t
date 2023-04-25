use strict;
use warnings;

use Test::More;

#system("rm -rf output");
system("perl rsru.pl");
my @diff = qx(diff -r output t/expected_output);

diag explain \@diff;

# diff -r output/rss.xml t/expected_output/rss.xml
# 13c13
# < <lastBuildDate>Tue, 25 Apr 2023 17:02:20 UTC</lastBuildDate>
# ---
# > <lastBuildDate>Tue, 25 Apr 2023 16:44:18 UTC</lastBuildDate>

cmp_ok scalar(@diff), "<=", 5;

done_testing;
