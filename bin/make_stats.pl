#!/usr/local/bin/perl --
#
# Generate the JSON docs needed to produce the frontpage graphs
# Joe Johnston <jjohn@taskboy.com>
#
use strict;
use DBI;
use JSON;
use File::Basename;
use URI::Escape;
use FindBin;
require "$FindBin::Bin/db.pl";
use Getopt::Std;
my %Opts;
getopts('fgmt?', \%Opts);

my $data_dir = "/home/jjohnston/sites/trends/www/api";

make_terms("$data_dir/data/terms");
if ($Opts{t})
{
    print "Terms made\n";
    exit;
}
my $top_fc_tags = make_this_weeks_fc_top_tags();
write_json("$data_dir/data/fc/tags_this_week.json", $top_fc_tags);
if ($Opts{f})
{
    print "Top Freecode tags\n";
    exit;
}

my $github_recent_projects = make_this_weeks_github_projects();
write_json("$data_dir/data/github/projects_this_week.json", $github_recent_projects);
if ($Opts{g})
{
    print "Recent Github projects\n";
    exit;
}

my ($merged_top_ten) = get_this_weeks_tech_trends();
write_json("$data_dir/data/merged/this_week.json", $merged_top_ten) if $merged_top_ten;

# Do all of the top techs have metadata?
report_missing_metadata($merged_top_ten);

if ($Opts{m})
{
    exit;
}

my $changes = get_change_in_tech_last_week($merged_top_ten);
write_json("$data_dir/data/changes/tech_this_week.json", $changes);

for my $rec (@$merged_top_ten)
{
    my $last_six_weeks = get_past_six_weeks_for_term($rec->{name});
    write_json("$data_dir/data/changes/$rec->{name}.json", $last_six_weeks);
}

# for my $num (7)
# {
#     my $data = get_fc_projects_updated($num, "day");
#     write_json("$data_dir/data/fc/days_$num.json", $data) if $data;
# }

# for my $num (6, 12)
# {
#     my $data = get_fc_projects_updated($num, "week");
#     write_json("$data_dir/data/fc/weeks_$num.json", $data) if $data;
# }


#-----
# Subs
#-----
sub make_terms
{
    my ($base_dir) = @_;

    my $dbh = get_dbh();
    my $sth = $dbh->prepare("SELECT * FROM technology_metadata");
    unless ($sth->execute())
    {
        warn($sth->{Statement});
        return;
    }

    while (my $hr = $sth->fetchrow_hashref)
    {
        my $term = $hr->{technology}; # uri_escape($hr->{technology});
        write_json("$base_dir/$term.json", $hr);
    }
}

sub get_past_six_weeks_for_term
{
    my ($term) = @_;
    my $dbh = get_dbh();
    
    my @dates = $dbh->selectrow_array("SELECT DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 WEEK)),
DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 2 WEEK)),
DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 3 WEEK)),
DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 4 WEEK)),
DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 5 WEEK)),
DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 6 WEEK))");
    my @changes;

    for (my $i=0; $i< @dates; $i++)
    {
        my $start_date = $dates[$i];
        my $end_date = $dates[$i - 1];
        $end_date = undef if $i == 0;

        my $data = get_raw_weekly_trends($start_date, $term, $end_date);
        my $cnt = 0;
        for my $r (@$data)
        {
            $cnt += $r->[0]->{c};
        }
        
        push @changes, { date => $start_date,
                         count => $cnt,
                       }
    }

    return [ reverse @changes ];
}

sub get_change_in_tech_last_week
{
    my ($top_tech) = @_;
    my $dbh = get_dbh();

    my ($last_week) = $dbh->selectrow_array("SELECT DATE(DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 WEEK))");
    my ($last_week_tech) = get_this_weeks_tech_trends($last_week);

    my @changes;
    my (%past);
    my %terms;
    for (my $i=0;  $i < @$last_week_tech; $i++)
    {
        $past{ $last_week_tech->[$i]->{name} } = $i;
    }

    for (my $i=0;  $i < @$top_tech; $i++)
    {
        my $tech = $top_tech->[$i]->{name}; 
        my $cnt = sprintf("%d", map { $_->{count} } grep { $_->{name} eq $tech } @$top_tech);
        my %rec = ( name => $tech,
                    count => $cnt,
                  );
        if (exists $past{ $tech })
        {
            if ($past{ $tech } > $i)
            {
                $rec{change} = "down";
            }
            elsif ($past{ $tech } == $i)
            {
                $rec{change} = "none";
            }
            else
            {
                $rec{change} = "up";
            }
        }
        else
        {
            $rec{change} = "new";
        }

        push @changes, \%rec;
    }


    return \@changes;
}


sub get_raw_weekly_trends
{
    my ($from_date, $term, $end_date) = @_;
    my $dbh = get_dbh();

    unless ($from_date)
    {
        ($from_date) = $dbh->selectrow_array("SELECT DATE(CURRENT_TIMESTAMP)");
    }

    my $qdate = $dbh->quote($from_date);

    my @sql;

    my $term_criteria = " t.name NOT IN ('html', 'xml', 'css', 'arrays')";
    if ($term)
    {
        $term_criteria = sprintf(" t.name = %s ", $dbh->quote($term));
    }

    my $end_date_criteria = "";
    my $start_date_criteria = "";

    if ($end_date)
    {
        $start_date_criteria = sprintf("last_activity_date >= '%s 00:00:00'", $from_date);
        $end_date_criteria = sprintf(" AND last_activity_date <= '%s 23:59:59'", $end_date);
    }
    else
    {
        $start_date_criteria = sprintf("last_activity_date >= DATE_SUB('%s 00:00:00', INTERVAL 1 WEEK) ", $from_date);
    }
    
    push @sql, qq[SELECT t.name,count(*) AS c
FROM 
  (SELECT sot.tag_id
     FROM 
     (SELECT id 
      FROM so_questions 
      WHERE $start_date_criteria $end_date_criteria
            
     ) AS soq
     JOIN so_questions_tags AS sot on sot.question_id=soq.id
   ) as tag_ids
   JOIN so_tags AS t ON t.id=tag_ids.tag_id
WHERE 
   $term_criteria
GROUP BY (t.name)
ORDER BY c DESC
LIMIT 20
                ];

    $start_date_criteria = $end_date_criteria = "";
    if ($end_date)
    {
        $start_date_criteria = sprintf(" e.created >= '%s 00:00:00' ", $from_date);
        $end_date_criteria = sprintf(" AND e.created <= '%s 23:59:59' ", $end_date);
    }
    else
    {
        $start_date_criteria = sprintf(" e.created >= DATE_SUB('%s 00:00:00', INTERVAL 1 WEEK) ", $from_date);
    }

    push @sql, qq[SELECT t.name,count(*) as c 
  FROM gh_events as e 
    JOIN `gh_projects_tags` AS pt ON pt.`project_id`=e.project_id 
    JOIN so_tags AS t ON t.id=pt.tag_id 
  WHERE 
    $start_date_criteria $end_date_criteria
    AND $term_criteria
  GROUP BY (t.name)
  ORDER BY c DESC  
  LIMIT 20 
                ];

    $start_date_criteria = $end_date_criteria = "";
    if ($end_date)
    {
        $start_date_criteria = sprintf(" AND fcp.issued >= '%s 00:00:00' ", $from_date);
        $end_date_criteria = sprintf(" AND fcp.issued <= '%s 23:59:59'", $end_date);
    }
    else
    {
        $start_date_criteria = sprintf(" AND fcp.issued >= DATE_SUB('%s 00:00:00', INTERVAL 1 WEEK)", $from_date);
    }

    push @sql, qq[select t.`name`,count(*) as c 
  FROM fc_projects as fcp 
    LEFT JOIN fc_projects_tags AS fct ON fcp.`id`=fct.`project_id`  
      LEFT JOIN so_tags AS t ON fct.tag_id=t.id  
 WHERE  
   t.name IS NOT NULL 
   AND $term_criteria
   $start_date_criteria $end_date_criteria
   GROUP BY (t.name)
   ORDER BY c DESC
   LIMIT 20
                ];

    my @data;
    for my $s (@sql)
    {
        my $sth = $dbh->prepare($s);
        unless ($sth->execute)
        {
            warn($sth->{Statement});
            return;
        }
        push @data, $sth->fetchall_arrayref({});
    }

    
    return \@data;
}

sub get_this_weeks_tech_trends
{
    my ($from_date) = @_;
    my $dbh = get_dbh();

    my $data = get_raw_weekly_trends($from_date);

    my %sources;
    my %terms;
    for (my $c = 0; $c < @$data; $c++)
    {
        for my $hr (@{$data->[$c]})
        {
            $terms{$hr->{name}} += $hr->{c};
            $sources{$c}->{$hr->{name}} = $hr->{c};
        }
    }
    
    my @top10;
    for my $i (sort keys %sources)
    {
        my $cnt = 0;
        for my $k (sort {$sources{$i}->{$b} <=> $sources{$i}->{$a} }  keys %{$sources{$i}})
        {
            push @{ $top10[$cnt++] }, $k;
        }
    }

    # Figure out what agreement exists among the lists
    # Confidence figure 1 - low confidence => 3 - high confidence

    my @merged;
    for my $row (@top10)
    {
        my %h;
        for (@$row)
        {
            $h{$_}++;
        }

        if (keys %h == @$row || keys %h == 1)
        {
            # no agreement or complete agreement, use the first 
            push @merged, { name => $row->[0],
                            confidence => (keys %h == @$row ? 3 : 1),
                            count => $terms{$row->[0]},
                          };
        }
        else 
        {
            # Who got the most votes? Descending value sort, pick the first value
            my ($term) = sort { $h{$b} <=> $h{$a} } keys %h;
            push @merged, { name => $term,
                            confidence => 2,
                            count => $terms{$term},
                          }
        }
    }

    return \@merged;
}

sub get_weekly_tech_trends
{
    my $dbh = get_dbh();

    my $data = get_raw_weekly_trends();

    my %terms;
    my %sources;
    
    # for (my $c = 0; $c < @sql; $c++)
    for (my $c = 0; $c < @$data; $c++)
    {
        for my $hr (@{$data->[$c]})
        {
            $terms{$hr->{name}} += $hr->{c};
            $sources{$c}->{$hr->{name}} = $hr->{c};
        }
    }
    
    my @top10;
    for my $i (sort keys %sources)
    {
        my $cnt = 0;
        for my $k (sort {$sources{$i}->{$b} <=> $sources{$i}->{$a} }  keys %{$sources{$i}})
        {
            push @{ $top10[$cnt++] }, $k;
        }
    }

    # Figure out what agreement exists among the lists
    # Confidence figure 1 - low confidence => 3 - high confidence

    my @merged;
    for my $row (@top10)
    {
        my %h;
        for (@$row)
        {
            $h{$_}++;
        }

        if (keys %h == @$row || keys %h == 1)
        {
            # no agreement or complete agreement, use the first 
            push @merged, { name => $row->[0],
                            confidence => (keys %h == @$row ? 3 : 1),
                          };
        }
        else 
        {
            # Who got the most votes? Descending value sort, pick the first value
            my ($term) = sort { $h{$b} <=> $h{$a} } keys %h;
            push @merged, { name => $term,
                            confidence => 2,
                          }
        }
    }

    # Truncate this list to top 10
    my $cnt = 0;
    my @tmp;
    for my $k (sort { $terms{$b} <=> $terms{$a} } keys %terms)
    {
        last if $cnt++ > 9;
        push @tmp, {
                     name  => $k,
                     count => $terms{$k}
                   };
    }

    return \@tmp, \@merged;
}

sub get_fc_projects_updated
{
    my ($num, $type) = @_;

    
    my $dbh = get_dbh();

    my @found;
    while ($num)
    {
        
        my $sql = sprintf("SELECT count(*) AS c 
                           FROM fc_projects 
                           WHERE 
               issued >= DATE_SUB(CURRENT_TIMESTAMP, INTERVAL %d %s)
               AND issued < DATE_SUB(CURRENT_TIMESTAMP, INTERVAL %d %s)
                           ",
                          $num,
                          $type,
                          $num - 1,
                          $type
                         );
        
        my $sth = $dbh->prepare($sql);
        unless ($sth->execute())
        {
            warn($sth->{Statement});
            return;
        }
        
        my ($count) = $sth->fetchrow_array();
        push @found, $count;
        $num--;
    }

    return \@found;
}

sub write_json
{
    my ($filename, $data) = @_;
    return unless $filename && $data;

    my $base_dir = dirname($filename);
    unless (-d $base_dir)
    {
        system("mkdir -p $base_dir");
    }
    
    open my $out, ">$filename" or die "CANNOT WRITE '$filename': $!";
    print $out encode_json($data);
    close $out;
}

sub report_missing_metadata
{
    my ($top_tech) = @_;
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("SELECT id FROM technology_metadata WHERE technology=?");
    for my $r (@$top_tech)
    {
        my $name = $r->{name};
        unless ($sth->execute($name))
        {
            warn($sth->{Statement});
            return;
        }
        
        unless ($sth->rows)
        {
            warn("Unknown technology: $name\n");
        }
    }
}

sub make_this_weeks_fc_top_tags
{
    my $dbh = get_dbh();
    my $sth = $dbh->prepare("select * from view_fc_top_tags_this_week order by c DESC limit 10 ");
    unless ($sth->execute())
    {
        warn($sth->{Statement});
        return;
    }
    return $sth->fetchall_arrayref({});
}

sub make_this_weeks_github_projects
{
    my $dbh = get_dbh();

    my $rows = $dbh->selectall_arrayref("SELECT name FROM view_gh_most_active_projects_this_week ORDER BY c DESC LIMIT 20");
    my @project_names;
    for my $r (@$rows)
    {
        push @project_names, $dbh->quote($r->[0]);
    }

    my $sql = sprintf("select * from view_gh_most_active_projects_with_tags WHERE project_name IN (%s) order by c DESC limit 500", join(",", @project_names));

    my $sth = $dbh->prepare($sql);

    unless ($sth->execute())
    {
        warn($sth->{Statement});
        return;
    }

    my @projects;
    my $cnt = 0;
    while (my $hr = $sth->fetchrow_hashref())
    {
        if ($projects[-1] && $projects[-1]->{project_name} eq $hr->{project_name})
        {
            push @{ $projects[-1]->{tags} }, $hr->{tag_name};
        }
        else
        {
            $cnt += 1;
            if ($cnt > 10)
            {
                last;
            }
            push @projects, { project_name => $hr->{project_name},
                              tags => [ $hr->{tag_name} ],
                            };
        }
    }
    
    return \@projects;
    
}
