#!/usr/local/bin/perl --
# Get StackOverflow stuff
# Joe Johnston <jjohn@taskboy.com>

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;
use JSON;
use DBI;
use IO::Uncompress::Gunzip ('gunzip');
use Time::HiRes;
use FindBin;
require "$FindBin::Bin/db.pl";

my $start = Time::HiRes::time();
our $NEW = 0;

my $posts = get_posts();
unless ($posts)
{
    warn("Failed to fetch posts\n");
    exit;
}
#printf "Quota: %d/%d\n", $posts->{quota_remaining}, $posts->{quota_max};

if ($posts->{backoff})
{
    print "Request to backoff for $posts->{backoff} seconds\n";
    exit;
}

my $processed = 0;
for my $p (@{$posts->{items} || []})
{
    $processed += 1 if save_post($p);
}

#printf("Processed: %d/%d questions\tNew: %d\n", $processed, scalar @{$posts->{items}}, $NEW);
#printf("Completed: %.2f seconds\n", (Time::HiRes::time() - $start));

sub get_posts
{
    my $ua = LWP::UserAgent->new;
    my $base = 'https://api.stackexchange.com';
    # my $path = '/2.1/posts?order=desc&sort=activity&site=stackoverflow';
    my $path = q[/2.1/questions?order=desc&sort=activity&site=stackoverflow&pagesize=100];

    my $res = $ua->request(HTTP::Request->new(GET => "$base$path"));
    if ($res->is_success)
    {
        my $raw = $res->content();
        my $inflated;
        gunzip(\$raw, \$inflated);
        my $posts;
        eval { $posts = decode_json($inflated); };
        if ($@)
        {
            warn("parse: $@");
            return;
        }
        return $posts;
    }
    return;
}

sub save_post
{
    my ($p) = @_;
    return unless $p;
    my $dbh = get_dbh();
    
    # question meta
    my $exists = $dbh->selectrow_array("SELECT count(*) FROM so_questions WHERE id=" . $dbh->quote($p->{question_id}));

    if ($exists)
    {
        # update
        my $sql = q[UPDATE so_questions SET title=?,answer_count=?,creation_date=FROM_UNIXTIME(?),last_activity_date=FROM_UNIXTIME(?),view_count=?,link=? WHERE id=?];

        my $sth = $dbh->prepare($sql);
        unless ($sth->execute(@$p{qw[title answer_count creation_date last_activity_date view_count link question_id]}))
        {
            warn($sth->{Statement});
            return;
        }
        
    }
    else
    {
        # insert
        my $sql = q[INSERT INTO so_questions (title,answer_count,creation_date,last_activity_date,view_count,link,id) 
                    VALUES (?, ?, FROM_UNIXTIME(?), FROM_UNIXTIME(?), ?, ?, ?)];
        my $sth = $dbh->prepare($sql);
        unless ($sth->execute(@$p{qw[title answer_count creation_date last_activity_date view_count link question_id]}))
        {
            warn($sth->{Statement});
            return;
        }
        $NEW++; # pretty lazy, jjohn
    }

    # tags
    $dbh->do("DELETE FROM so_questions_tags WHERE question_id=" . $dbh->quote($p->{question_id}));
    my $sth = $dbh->prepare("INSERT INTO so_questions_tags (question_id,tag_id) VALUES (?,?)");
    for my $t (@{$p->{tags} || []})
    {
        my ($tag_id) = $dbh->selectrow_array("SELECT id FROM so_tags WHERE name=" . $dbh->quote($t));
        unless ($tag_id)
        {
            my $sth = $dbh->prepare("insert into so_tags (name) VALUE (?)");
            unless ($sth->execute(lc($t)))
            {
                warn($sth->{Statement});
                next;
            }
            $tag_id = $dbh->{mysql_insertid};
        }

        unless ($sth->execute($p->{question_id}, $tag_id))
        {
            warn($sth->{Statement});
            next;          
        }
    }

    return $p->{question_id};
}

{
my $dbh;
sub get_dbh
{
    return $dbh if $dbh;
    $dbh = DBI->connect("dbi:mysql:tech_watch", "editor", "editor");
}
}
