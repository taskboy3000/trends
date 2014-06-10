#!/usr/local/bin/perl --
use strict;
use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../");
use Trends::Dispatch;

Trends::Dispatch->dispatch();
