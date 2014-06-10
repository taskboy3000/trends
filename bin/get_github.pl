#!/usr/local/bin/perl --
# Get Github activity
# Joe Johnston <jjohn@taskboy.com>

use strict;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use DBI;
use Data::Dumper;
use MIME::Base64;
use FindBin;
require "$FindBin::Bin/db.pl";
require "$FindBin::Bin/github_auth_token.pl";

our $TagExceptionsLog = "./tag_exceptions.log";

unlink $TagExceptionsLog;

my $events = get_events();
for my $e (@$events)
{
    # next if $e->{type} eq "IssuesEvent"; 
    #printf "Type: %s\n", $e->{type};
    #printf "Event ID: %s\n", $e->{id};
    #printf "Owner: %s\n", $e->{org}->{login};
    #printf "Repo Name: [%d] %s\n", $e->{repo}->{id}, $e->{repo}->{name};
    
    my %params = (repo_id => $e->{repo}->{id},
                  name => $e->{repo}->{name},
                  event_id => $e->{id},
                  event_type => $e->{type},
                 );

    my $tree = get_tree($e->{repo}->{name});
    if ($tree)
    {
        my $tags = get_tags_from_tree($tree->{tree}, $e->{repo}->{name});
        #printf ("Tags: %s\n", join(", ", keys %$tags));
        $params{tags} = [ keys %$tags ];
        #$params{tags} = [ keys %tags ];
    }
    
    # print "--\n";
    save_event(\%params);
}

sub wget
{
    my ($url) = @_;
    return unless $url;

    my $ua = LWP::UserAgent->new;

    my $req = HTTP::Request->new(GET => $url);
    my $token = github_auth_token();
    my $auth = encode_base64("$token:");

    $req->header("Authorization" => "Basic $auth");
    return $ua->request($req);    
}

sub get_events
{
    my $base = 'https://api.github.com';
    my $path = q[/events];
    
    my $res = wget("$base$path");
    if ($res->is_success)
    {
        my $raw = $res->content();
        my $posts = decode_json($raw);
        return $posts;
    }
    else
    {
        my $error;
        eval { $error = decode_json($res->content) };
        if ($error)
        {
            print "$error->{message}\n";
        }
        else
        {
            warn("oops");
        }
    }
    return;
}

sub get_tree
{
    my ($owner_repo) = @_;
    return unless length($owner_repo) > 3;

    my $base = 'https://api.github.com';
    my $path = qq[/repos/$owner_repo/git/trees/HEAD?recursive=1];
    my $res = wget("$base$path");

    if ($res->is_success)
    {
        my $raw = $res->content();
        my $tree = decode_json($raw);
        return $tree;
    }
    return;
    
}

sub get_tags_from_tree
{
    my ($tree, $project) = @_;
    return unless ref $tree eq 'ARRAY';

    # Map path extensions to a tags    
    
    my %ext2tag = (
                   "action" => "automator",
                   "c" => "c",
                   "cc" => "c++",
                   "class" => "java",
                   "cpp" => "c++",
                   "css" => "html",
                   "csv" => "text",
                   "cxx" => "c++",
                   "egg" => "python",
                   "erb" => "ruby",
                   "gemspec" => "ruby",
                   "h" => "c",
                   "handlebars" => "javascript",
                   "htm" => "html",
                   "html" => "html",
                   "jar" => "java",
                   "java" => "java",
                   "js" => "javascript",
                   "json" => "javascript",
                   "lau" => "lua",
                   "less" => "html",
                   "m" => "matlab",
                   "php" => "php",
                   "pl" => "perl",
                   "pm" => "perl",
                   "py" => "python",
                   "pyc" => "python",
                   "rb" => "ruby",
                   "rdf" => "xml", # Unsure
                   "rst" => "python",
                   "sed" => "sed",
                   "sh" => "bash",
                   "sql" => "sql",
                   "war" => "java",
                   "xml" => "xml",
                   "xsl" => "xml",
                   "scala" => "scala",
                   "csh" => "c shell",
                   "hh" => "c++",
                   "jsp" => "java",
                   "xhtml" => "html",
                   "xslt" => "xml",
                   "mustache" => "javascript",
                   "go" => "go",


                  );

    # You can ignore graphic file formats, 
    # audio files
    # and most documentation formats
    my %ignore = (
                  "inc" => 1,
                  "cfg" => 1,
                  "cmake" => 1,
                  "code" => 1,
                  "pem" => 1,
                  "scss" => 1, # revisit
                  "compress" => 1,
                  "conf" => 1,
                  "db" => 1,
                  "desktop" => 1,
                  "doc" => 1,
                  "dox" => 1,
                  "egg-info" => 1,
                  "elf" => 1,
                  "eot" => 1,
                  "gif" => 1,
                  "bat" => 1,
                  "goff" => 1,
                  "gz" => 1,
                  "ico" => 1,
                  "in" => 1,
                  "jison" => 1, # revisit
                  "xib" => 1,
                  "strings" => 1,
                  "svn-base" => 1,
                  "icns" => 1,
                  "wxs" => 1,
                  "plist" => 1,
                  "sdk" => 1,
                  "po" => 1,
                  "mako" => 1,
                  "vars" => 1,
                  "tarball" => 1,
                  "versions" => 1,
                  "jpg" => 1,
                  "jshintrc" => 1,
                  "lock" => 1,
                  "md" => 1,
                  "mp3" => 1,
                  "msg" => 1,
                  "obj" => 1,
                  "ogg" => 1,
                  "otf" => 1,
                  "ld" => 1,
                  "pdf" => 1,
                  "png" => 1,
                  "pod" => 1,
                  "podspec" => 1,
                  "pri" => 1,
                  "pro" => 1,
                  "qrc" => 1,
                  "rc" => 1,
                  "qml" => 1, # ambiguous
                  "svg" => 1,
                  "text" => 1,
                  "tgz" => 1,
                  "tiff" => 1,
                  "tmpl" => 1, # ambiguous
                  "ttf" => 1,
                  "txt" => 1,
                  "txx" => 1,
                  "woff" => 1,
                  "zcml" => 1,
                  "zip" => 1,
                  "vert" => 1,
                  "frag" => 1,
                  "func" => 1,
                  "shad" => 1,
                  "vtk" => 1,
                  "ini" => 1,
                  "d" => 1,
                  "example" => 1,
                  "wsgi" => 1,
                  "mak" => 1,
                  "old" => 1,
                  "ac" => 1,
                  "freebsd" => 1,
                  "fc" => 1,
                  "if" => 1,
                  "te" => 1,
                  "service" => 1,
                  "postinst" => 1,
                  "properties" => 1,
                  "prerm" => 1,
                  "conffiles" => 1,
                  "local" => 1,
                  "pot" => 1,
                  "m4" => 1,
                  "yml" => 1,
                  "t" => 1,
                  "data" => 1,
                  "cmd" => 1,
                  "md5" => 1,
                  "sha1" => 1,
                  "bit" => 1,
                  "mss" => 1,
                  "tex" => 1,
                  "options" => 1,
                  "twig" => 1, # revisit
                  "feature" => 1,
                  "xlf" => 1,
                  "dist" => 1,
                  "xliff" => 1,
                  "tpl" => 1,
                  "dat" => 1,
                  "lst" => 1,

                  
                 );

    my %tags;
    for my $b (@$tree)
    {
        #     {
        #       "path": "subdir/file.txt",
        #       "mode": "100644",
        #       "type": "blob",
        #       "size": 132,
        #       "sha": "7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b",
        #       "url": "https://api.github.com/repos/octocat/Hello-World/git/7c258a9869f33c1e1e1f74fbb32f07c86cb5a75b"
        #     }  
        
        my @parts = split("/", $b->{path});
        my $file = $parts[-1];
        next if substr($file, 0, 1) eq '.'; # ignore dot files
        next if index($file, ".") == -1; # no extension

        my ($ext) = ($file =~ m!\.([^.]+)$!);
        if (my $tag = $ext2tag{lc $ext})
        {
            $tags{$tag}++;
        }
        else
        {
            #warn("Unknown extension: '$ext' on '$b->{path}'\n");
            unless ($ignore{lc $ext})
            {
                log_tag_exceptions("$ext :: $b->{path} :: $project");
            }
        }
    }
    return \%tags;
}

sub save_event
{
    my ($p) = @_;
    return unless $p;
    my $dbh = get_dbh();
    
    # project meta
    my $exists = $dbh->selectrow_array("SELECT count(*) FROM gh_projects WHERE id=" . $dbh->quote($p->{repo_id}));

    if ($exists)
    {
        # update
        my $sql = q[UPDATE gh_projects SET name=?,updated=CURRENT_TIMESTAMP WHERE id=?];

        my $sth = $dbh->prepare($sql);
        unless ($sth->execute($p->{name}, $p->{repo_id}))
        {
            warn($sth->{Statement});
            return;
        }
        
    }
    else
    {
        # insert
        my $sql = q[INSERT INTO gh_projects (id, name, updated) VALUES (?, ?, CURRENT_TIMESTAMP)];
        my $sth = $dbh->prepare($sql);
        unless ($sth->execute(@$p{('repo_id', 'name')}))
        {
            warn($sth->{Statement});
            return;
        }
        
    }

    my $sql = q[INSERT INTO gh_events (id, project_id, type, created) VALUES (?,?,?,CURRENT_TIMESTAMP)];
    my $sth = $dbh->prepare($sql);
    $sth->execute(@$p{('event_id', 'repo_id', 'event_type')}); # It's OK for this to fail

    # tags
    $dbh->do("DELETE FROM gh_projects_tags WHERE project_id=" . $dbh->quote($p->{question_id}));
    $sth = $dbh->prepare("INSERT INTO gh_projects_tags (project_id,tag_id) VALUES (?,?)");

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

        unless ($sth->execute($p->{repo_id}, $tag_id))
        {
            warn($sth->{Statement});
            next;          
        }
    }

    return $p->{repo_id};
}

sub log_tag_exceptions
{
    my ($msg) = @_;

    open my $log, ">>$TagExceptionsLog";
    printf $log ("%s %s\n", scalar localtime(), $msg);
    close $log;
}
