# Joe Johnston <jjohn@taskboy.com>
# 1. Rename db.pl
# 2. Put in your local DB creds
use strict;
use DBI;
{
    our $__dbh;
    sub get_dbh
    {
        return $__dbh if $__dbh;
        $__dbh = DBI->connect("dbi:mysql:tech_watch", "user", "pass") or die($DBI::ERRSTR);
        return $__dbh;
    }
}

1;
