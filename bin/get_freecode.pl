#!/usr/local/bin/perl --
# Joe Johnston <jjohn@taskboy.com>

use strict;
use XML::Feed;
use DBI;
use URI;
use FindBin;
require "$FindBin::Bin/db.pl";

my $feed = q[https://freecode.com/?format=atom];
my $X = XML::Feed->parse(URI->new($feed));

# print $X->title, "\n";

my $successful = 0;
my $cnt = 0;
for my $e ($X->entries)
{
    $cnt++;
    my %p = (id => $e->id,
             project_url => "",
             issued => $e->issued,
             title => $e->title,
             tags => [],
            );
    $p{issued} =~ s/T/ /;
    my $c = $e->content->body;
    my ($tags) = $c =~ m!<p><strong>Tags:</strong> ([^<]+)</p>!;
    $p{tags} = [ split(", ", $tags) ];

    my $list = $e->{entry}->{elem}->getElementsByTagName("link");
    if ($list->size)
    {
        $p{project_url} = $list->get_node(0)->getAttribute("href");
    }

    $successful++ if save_post(\%p);

}

# printf("Processed %d/%d\n", $successful, $cnt);


sub save_post
{
    my ($p) = @_;
    return unless $p;
    my $dbh = get_dbh();
    
    # question meta
    my $exists = $dbh->selectrow_array("SELECT count(*) FROM fc_projects WHERE id=" . $dbh->quote($p->{id}));

    if ($exists)
    {
        # update
        my $sql = q[UPDATE fc_projects SET title=?,project_url=?,issued=? WHERE id=?];

        my $sth = $dbh->prepare($sql);
        unless ($sth->execute(@$p{qw[title project_url issued id]}))
        {
            warn($sth->{Statement});
            return;
        }
        
    }
    else
    {
        # insert
        my $sql = q[INSERT INTO fc_projects (title, project_url, issued, id) 
                    VALUES (?, ?, ?, ?)];
        my $sth = $dbh->prepare($sql);
        unless ($sth->execute(@$p{qw[title project_url issued id]}))
        {
            warn($sth->{Statement});
            return;
        }
 
    }

    # tags
    $dbh->do("DELETE FROM fc_projects_tags WHERE project_id=" . $dbh->quote($p->{id}));
    my $sth = $dbh->prepare("INSERT INTO fc_projects_tags (project_id,tag_id) VALUES (?,?)");
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

        unless ($sth->execute($p->{id}, $tag_id))
        {
            warn($sth->{Statement});
            next;          
        }
    }

    return $p->{id};
}

