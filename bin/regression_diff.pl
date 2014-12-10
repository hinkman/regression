#!/opt/perl5/bin/perl -w
#!/Users/hinkman/perl5/perlbrew/perls/perl-5.16.0/bin/perl -w

use File::Slurp qw( edit_file edit_file_lines );
use File::Map qw( map_file unmap );
use File::Basename;
use Text::Diff;
use File::Copy;
# use String::CRC::Cksum qw(cksum);
use String::CRC;
use HTML::Entities;
use Config::YAML::Tiny;
use Archive::Extract;
use Getopt::Long;

select("STDERR");
$|=1;
select("STDOUT");
$|=1;

print "Version 3.3.1\n";
$debug=0;
%matches_hash=();
%exclude_complete_hash=();
%clean_up_complete_hash=();
%right_dir_hash=();

$date=`date '+%Y/%m/%d'`; chomp $date;
$dir_date=`date '+%Y%m%d%H%M%S'`;
chomp $dir_date;
# $gis50_top="/docrep/DEMO-GIS/mlh/mods";
# $gis41_url="/gis41_dirs";
# $gis50_url="/gis50_dirs";
# $log="/usr/local/apache2/htdocs/gis_results.html";
if ($ENV{"RAILS_ENV"} eq "production") {
    $output_dir="/var/www/regression/public/regression";
    $rails_server="localhost";
} else {
    $rails_server="localhost:3000";
    $output_dir="/Users/hinkman/git/regression/public/regression";
}
$url_top="/regression";
my $output_prefix;
my $left_zip;
my $right_zip;
my $result_id;
my $config_file;
# foreach $key (keys %ENV) {
#     print "$key $ENV{$key}\n";
# }
# exit;
GetOptions ("config_file=s" => \$config_file,
            "output_prefix=s" => \$output_prefix,
            "result_id=i" => \$result_id,
            "left_zip=s" => \$left_zip,
            "right_zip=s" => \$right_zip,
            "dir_date=s" => \$dir_date)
or die("Error in command line arguments\n");
# $output_prefix = $ARGV[3];
print "$config_file $output_prefix $left_zip $right_zip $dir_date $result_id\n" if ($debug);
# exit;

my $config = Config::YAML::Tiny->new( config => $config_file );

( -w "$output_dir/$output_prefix" ) or die "Incorrect output dir\n";

$basedir="$output_dir/$output_prefix/$dir_date";
$left_url="$url_top/$output_prefix/$dir_date/left";
$right_url="$url_top/$output_prefix/$dir_date/right";

`mkdir -p $basedir`;
$results_file="$basedir/index.html";
$results_url="$url_top/$output_prefix/$dir_date/index.html";
# ( -w $results_file ) or `echo '<!-- Start counter -->\n<!-- End counter -->\n<!-- Top of file -->' > $results_file`;

if ($result_id) {
    `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X PATCH $rails_server/results/$result_id.json -d '{ "result" : { "pct_complete": 0, "path" : "$results_url" } }'`
}

# $left_dir = zip_load($ARGV[1],"$basedir/left");
# $right_dir = zip_load($ARGV[2],"$basedir/right");
$left_dir = zip_load($left_zip,"$basedir/left");
$right_dir = zip_load($right_zip,"$basedir/right");

# $config->{left_dir};
# $right_dir = $config->{right_dir};
print "Left dir: $left_dir\n" if ($debug);

# exit;

$file_type = $config->{type};

$order_matters = "false";
if (exists $config->{order_matters}) {
    $order_matters = $config->{order_matters};
}
print "order_matters: $order_matters\n" if ($debug);

@patterns_hash_refs = @{$config->{filenames}};

if (exists $config->{exclusions}->{right}) {
    foreach my $hash_ref (@{$config->{exclusions}->{right}}) {
        $$exclude_right_hash_ref{$$hash_ref{pattern}} = $$hash_ref{type};
    }
}

if (exists $config->{exclusions}->{left}) {
    foreach my $hash_ref (@{$config->{exclusions}->{left}}) {
        $$exclude_left_hash_ref{$$hash_ref{pattern}} = $$hash_ref{type};
    }
}

if (exists $config->{reference_items}) {
    @reference_items = @{$config->{reference_items}};
}

%{$clean_hash}=();
if (exists $config->{clean_up}) {
    foreach my $hash_ref (@{$config->{clean_up}}) {
        $$clean_hash{$$hash_ref{pattern}}=$$hash_ref{fields};
    }
}

print "reference items: @reference_items\n" if ($debug);
foreach $hash_ref (@patterns_hash_refs) {
    print $$hash_ref{matching_fields}."\n" if ($debug);
}
# exit;

# curl -v -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST localhost:3000/unmatched_files/ -d '{ "unmatched_file" : { "result_id": 38, "side": "left", "name":"one", "url":"/url" } }'

`mkdir -p $right_dir/.hashed`;
$right_dir_array_ref=&load_right_dir_list($right_dir);
$right_dir_count=scalar(@{$right_dir_array_ref});
print "real $right_dir count $right_dir_count\n" if ($debug);
$count=$hashcount=$cleancount=0;
chomp($left_dir_count=`ls $left_dir | wc -l`); $left_dir_count=~s/\s//g;
if ($result_id) {
    print "`curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X PATCH $rails_server/results/$result_id.json -d '{ \"result\" : { \"left_count\": \"$left_dir_count\", \"right_count\" : \"$right_dir_count\" } }'`" if ($debug);
    `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X PATCH $rails_server/results/$result_id.json -d '{ "result" : { "left_count": "$left_dir_count", "right_count" : "$right_dir_count" } }'`
}
foreach $left_file (<$left_dir/*>) {
    $count++;
    # (not ($count % 10)) and &in_place_clean($results_file,{'\<\!\-\- Start counter \-\-\>\n.*\<\!\-\- End counter \-\-\>\n'=>"<!-- Start counter -->\nRunning: $count of $left_dir_count\n<!-- End counter -->\n"},"stringm");
    if (($result_id) and ((not ($count % 25)) or ($count == $left_dir_count))) {
        $pct_complete=int(($count / $left_dir_count) * 100);
        `curl -H 'Content-Type: application/json' -H 'Accept: application/json' -X PATCH $rails_server/results/$result_id.json -d '{ "result" : { "pct_complete": $pct_complete } }'`
    }
    print "$count $left_file\n" if ((not ($count % 10)) and ($debug));
    print "====================================================\n" if ($debug);
    print "Source file: $left_file\n" if ($debug);
    # (unlink $file and next) if ($file =~ /\.ignore$/);
    # (unlink $file and next) if ($file =~ /\.fail$/);
    # (unlink $file and next) if ($file =~ /^[0-9a-f]+_\._.*/);
    (unlink $left_file and next) if (-z $left_file);

    %{$finished_clean_hash}=%{$clean_hash};
    # @finished_reference_items=@reference_items;
    if ($file_type eq "EDI") {
        # Get the segment and element terminators before we start
        # munging up the file
        map_file $mapped_file, $left_file;
        $eld=substr($mapped_file,3,1);
        $sed=substr($mapped_file,105,1);
        unmap $mapped_file;
        $finished_clean_hash=&edi_clean_hash_setup($finished_clean_hash,$eld,$sed);
        # @finished_reference_items=map { eval "qr/$_/" } @finished_reference_items if (scalar(@finished_reference_items));
    }

    &in_place_clean($left_file,$exclude_left_hash_ref,"exclude") if (scalar(keys %{$exclude_left_hash_ref}));
    &in_place_clean($left_file,$finished_clean_hash,"clean");
    # exit;

    if (scalar(@reference_items)) {
        @dig_it_array=map { eval "qr/$_/" } @reference_items;
        print "reference items2: @dig_it_array\n" if ($debug);
        $useful_value=&dig_out_value($left_file,\@dig_it_array);
        print "useful value: $useful_value\n" if ($debug);
    } else {
        $useful_value="";
    }


    foreach $pattern_hash_ref (@patterns_hash_refs) {
        # TODO Clean-up file match logic
        if ((exists $$pattern_hash_ref{matching_fields}) and ($$pattern_hash_ref{matching_fields}=~/all/)) {
            # print "found matching_fields all\n" if ($debug);
            $left_file_match=basename($left_file);
        } elsif ((exists $$pattern_hash_ref{matching_fields}) and ($$pattern_hash_ref{matching_fields}=~/none/)) {
            # print "found matching_fields all\n" if ($debug);
            $left_file_match=".*";
        } elsif ((exists $$pattern_hash_ref{regex_left}) and (exists $$pattern_hash_ref{regex_left})) {
            $left_file=~m/$$pattern_hash_ref{regex_left}/;
            $left_file_match=eval "qr/$$pattern_hash_ref{regex_right}/";
        } else {
            @file_pattern_fields=split /\s*,\s*/,$$pattern_hash_ref{matching_fields};
            if (not grep(/^\d+$/,@file_pattern_fields)) {
                print "Bad file fieldlist: $$pattern_hash_ref{matching_fields}\n" if ($debug);
                next;
            }
            $delimiters="\\".join("\\",split(//,$$pattern_hash_ref{delimiters}));
            $delimiters=qr{$delimiters};
            @left_file_split=split /[$delimiters]/,basename($left_file);
            foreach my $part (@left_file_split) {
                print "left file part: $part\n" if ($debug);
            }
            $left_file_match="";
            for ($i=0; $i < @left_file_split; $i++) {
                if (grep { ($_ - 1) eq $i } @file_pattern_fields) {
                    $left_file_match.=$left_file_split[$i];
                } else {
                    $left_file_match.="[^$delimiters]*";
                }
                $left_file_match.="[$delimiters]" unless ($i==$#left_file_split);
            }
        }
        print "left_file_match = $left_file_match\n" if ($debug);
        $bp_string=$bp_id="";
        # exit;

        $right_file_list_ref=&setup_match_list($right_dir_array_ref,$left_file_match);
        print "matches @{$right_file_list_ref}\n" if ($debug);
        $possible_matches_ref=&find_match($right_dir,$left_file,$right_file_list_ref,$finished_clean_hash,\@dig_it_array,$useful_value,$bp_string,$sed);
        # print "possible @{$possible_matches_ref}\n" if ($debug);
        # if ($#$possible_matches_ref >= 0) {
        #     &output_entry($left_file,$possible_matches_ref,1,$useful_value,$bp_id);
        # }
        # last if ($output_line);
        # last if (not $#$possible_matches_ref);
    }
}
foreach my $right_file (sort @$right_dir_array_ref) {
    print "leftover right side: $right_file\n" if ($debug);
    # next if (exists $right_dir_hash{$right_file}{"diff"});
    my $cleaned_right_file=encode_entities($right_file,"<>&~*() ");
    `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST $rails_server/unmatched_files/ -d '{ "unmatched_file" : { "result_id": $result_id, "side": "right", "name":"$right_file", "url":"$right_url/$cleaned_right_file" } }'`;
}
# &in_place_clean($results_file,{'\<\!\-\- Start counter \-\-\>\n.*\<\!\-\- End counter \-\-\>\n'=>"Finished "},"stringm");
exit;

sub setup_match_list {
    my $current_dir_ref=shift || die "current dir array list in setup_match_list";
    my $current_file_match=shift || die "current match string in setup_match_list";
    my @temp_array;
    my %temp_seen;

    if (not exists $matches_hash{$current_file_match}) {
        print "New match list for $current_file_match\n" if ($debug > 1);
        @{$matches_hash{$current_file_match}}=grep(/$current_file_match/,@$current_dir_ref);
        print "setup_match_list found ".scalar(@{$matches_hash{$current_file_match}})." for $current_file_match\n" if ($debug > 1);
    } else {
        print "Found match list for $current_file_match\n" if ($debug > 1);
    }
    print "setup_match_list found ".scalar(@{$matches_hash{$current_file_match}})."\n" if ($debug);
    return $matches_hash{$current_file_match};
}

sub dig_out_value {
    (my $current_file, my $current_dig_it_array_ref)=@_;
    my $mapped_file;
    my $found_it="";

    print "In dig_out_value\n" if ($debug);
    map_file $mapped_file, $current_file;
    foreach my $match_string (@$current_dig_it_array_ref) {
        print "Checking $match_string\n" if ($debug);
        ($found_it)=($mapped_file =~ /$match_string/);
        ($found_it) and last;
    }
    unmap $mapped_file;
    # print "found it: $found_it\n" if ($debug);
    return($found_it);
}

sub output_entry {
    # (my $current_left_dir, my $current_left_file, my $current_matches_ref, my $show_possible, my $current_useful, my $current_left_bp)=@_;
    my $full_left_file=shift || die "current left file required in output_entry";
    my $current_matches_ref=shift || die "current matches required in output_entry";
    my $show_possible=shift || "0";
    my $current_useful=shift || "None found";
    my $current_left_bp=shift || "";
    my $possible_files="";

    print "In output_entry\n" if ($debug);
    my $current_left_file=basename($full_left_file);
    my $current_left_dir=dirname($full_left_file);
    $current_useful=encode_entities($current_useful,"<>&~*");
    print "$full_left_file $current_useful $current_left_bp $results_file\n" if ($debug);
    my $output_line="<!-- Top of file -->\n<!-- Start left $current_left_file -->\n\<font color=green\>$date\</font\>\n<p>";
    # if ($current_left_bp) {
    #     $output_line.="4.1 BP: <a href=\"http://sac-gis.itradenetwork.com:8020/ws/BPMonitor?bpid=$current_left_bp\&next=page.bpdetail\&pos=0&summaryPageType=curproc\&where=live\&autoRefresh=1\">$current_left_file</a> ($current_left_dir)";
    # } else {
        $output_line.="Left file: <a href=\"$left_url/$current_left_file\">$current_left_file</a>";
    # }
    $output_line.="<br>Help: $current_useful\n";
    if ($show_possible) {
        $output_line.="<ul>\nRight possible files\n";
        foreach my $match_file (@$current_matches_ref) {
            # if ($right_dir_hash{$match_file}{"bp_id"}) {
            #     $possible_files.="<li><a href=\"http://pd-gis01.itradenetwork.com:8080/ws/BPMonitor?bpid=".$right_dir_hash{$match_file}{"bp_id"}."\&next=page.bpdetail\&pos=0&summaryPageType=search\&where=live\&autoRefresh=1\">$match_file</a><br>";
            # } else {
                $possible_files.="<!-- Start right $match_file -->\n<li><a href=\"$right_url/$match_file\">$match_file</a><br>";
            # }
            ($right_dir_hash{$match_file}{"diff"}) and $possible_files.="<PRE>" . encode_entities($right_dir_hash{$match_file}{"diff"},"<>&~*") . "</PRE>";
            $possible_files.="</li>\n<!-- End right $match_file -->\n";
            (length($possible_files) > 500) and last;
        }
        $output_line.=$possible_files."</ul>\n<hr>\n<!-- End left $current_left_file -->\n";
    } else {
        $output_line.="<hr>\n<!-- End left $current_left_file -->\n";
    }
    &in_place_clean($results_file,{'\<\!\-\- Top of file \-\-\>\n'=>$output_line},"string");
    `chmod 777 $results_file`;
}

# sub create_output {
    # $output_line="<html><body>\n" . $output_line;
    # $output_line.="</body></html>\n";
    # open OUTPUT,">$log";
    # print OUTPUT $output_line;
    # close OUTPUT;
# }

sub in_place_clean {
    (my $editor, my $replace_strings_hashref, my $type)=@_;

    return if (($type eq "clean") and ($clean_up_complete_hash{$editor}));
    return if (($type eq "exclude") and ($exclude_complete_hash{$editor}));
    foreach my $rstring (keys %$replace_strings_hashref) {
        print "in_place_clean rstring $rstring\n" if ($debug);
        if ($type eq "string") {
            edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/gs } $editor;
        } elsif ($type eq "stringm") {
            edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/ms } $editor;
        } elsif ($type eq "clean") {
            if ($file_type eq "CARMAFF") {
                edit_file_lines { s/$rstring/$$replace_strings_hashref{$rstring}/eegs } $editor;
            } else {
                edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/eegs } $editor;
            }
            $clean_up_complete_hash{$editor}=1;
        } elsif ($type eq "exclude") {
            if ($$replace_strings_hashref{$rstring} eq "line") {
                edit_file_lines { $_ = '' if /$rstring/ } $editor;
            } elsif ($$replace_strings_hashref{$rstring} eq "string") {
                edit_file { s/$rstring//gs } $editor;
            } elsif ($$replace_strings_hashref{$rstring} eq "stringm") {
                edit_file { s/$rstring//gms } $editor;
            }
            $exclude_complete_hash{$editor}=1;
        }
    }
}

sub load_right_dir_list {
    (my $current_right_dir)=@_;
    my $current_right_array_ref;
    opendir(my $dh, "$current_right_dir") || die "can't opendir $current_right_dir: $!";
    @$current_right_array_ref=readdir($dh);
    @$current_right_array_ref=map { /^[^\.]/ ? $_ : () } @$current_right_array_ref;
    closedir $dh;
    print "load_right_dir found ".scalar(@$current_right_array_ref)." files\n" if ($debug);
    print "         files found @$current_right_array_ref\n" if ($debug > 1);
    return $current_right_array_ref;
}

sub find_match {
    # (my $current_50_dir, my $current_41_file, my $current_file_match, my $current_clean)=@_;
    my $current_right_dir=shift || die "current right dir required in find_match";
    my $full_left_file=shift || die "current left file required in find_match";
    my $matches_ref=shift || die "list of right side files matched required";
    my $current_clean=shift || "";
    my $current_dig_it_array_ref=shift || "";
    my $current_useful=shift || "";
    my $current_bp_string=shift || "";
    my $current_sed=shift || "";  # segment delimiter for EDI
    my $mapped_file;
    my $matches_keep_ref;
    my $matched_file;
    my $match_string;
    my $found_match=0;
    my $found_useful="";
    my $file_cksum=0;
    my $file_rows_left=0;
    my $file_rows_right=0;
    my $index_counter=0;
    my @temp_left;
    my @temp_right;

    my $current_left_file=basename($full_left_file);
    my $cleaned_left_file=encode_entities($current_left_file,"<>&~*() ");
    my $current_left_dir=dirname($full_left_file);
    # map_file $mapped_file, $current_left_file;
    # $file_cksum=cksum($mapped_file);
    # unmap $mapped_file;
    $file_cksum=(split(/\s+/,`cat '$full_left_file' | sort | cksum`))[0];
    print "left cksum $file_cksum $full_left_file\n" if ($debug);
    if ($debug > 1) {
        print "Potential matches:\n  ";
        print join("\n  ",@$matches_ref),"\n";
    } elsif ($debug) {
        print "Potential matches: ".scalar(@$matches_ref)."\n";
    }
    if (scalar(@$matches_ref)) {
        for ($i=0; $i < @$matches_ref; $i++) {
            print "------------------------------\n" if ($debug);
            $matched_file=$$matches_ref[$i];
            if (not exists $right_dir_hash{$matched_file}) {
                $right_dir_hash{$matched_file}{"cksum"} = 0;
                $right_dir_hash{$matched_file}{"useful"} = "";
                $right_dir_hash{$matched_file}{"diff"} = "";
                $right_dir_hash{$matched_file}{"bp_id"} = 0;
            }
            print "looping match $matched_file ".$right_dir_hash{$matched_file}{"cksum"}."\n" if ($debug);
            if (($current_bp_string) and (not $right_dir_hash{$matched_file}{"bp_id"})) {
                print "bp_match_string $current_bp_string\n" if ($debug > 1);
                $right_dir_hash{$matched_file}{"bp_id"}=$matched_file;
                $right_dir_hash{$matched_file}{"bp_id"}=~s/$current_bp_string/$1/;
            } else {
                print "not bp_match_string $current_bp_string  ".$right_dir_hash{$matched_file}{"bp_id"}."\n" if ($debug > 1);
            }
            if (not $right_dir_hash{$matched_file}{"cksum"}) {
                if (not -r "$current_right_dir/.hashed/$matched_file") {
                    print "hashing: $matched_file\n" if ($debug > 1);
                    $hashcount++;
                    print "    hash $hashcount $current_left_file $matched_file\n" if (not ($hashcount % 100));
                    if ($current_clean) {
                        (not -r "$current_right_dir/.cleaned/$matched_file") and &clean_me($current_right_dir,$matched_file,$current_clean);
                        $mapped_file="$current_right_dir/.cleaned/$matched_file";
                    } else {
                        $mapped_file="$current_right_dir/$matched_file";
                    }
                    $right_dir_hash{$matched_file}{"cksum"}=(split(/\s+/,`cat '$mapped_file' | sort | cksum`))[0];
                    open HASH,">$current_right_dir/.hashed/$matched_file";
                    print HASH $right_dir_hash{$matched_file}{"cksum"};
                    close HASH;
                    print "completed hash $matched_file $right_dir_hash{$matched_file}{cksum}\n" if ($debug > 1);
                } else {
                    $right_dir_hash{$matched_file}{"cksum"}=`cat '$current_right_dir/.hashed/$matched_file'`;
                    chomp $right_dir_hash{$matched_file}{"cksum"};
                }
            } else {
                print "already hashed $matched_file $right_dir_hash{$matched_file}{cksum}\n" if ($debug > 1);
            }
            my $current_right_file=(-r "$current_right_dir/.cleaned/$matched_file") ? "$current_right_dir/.cleaned/$matched_file" : "$current_right_dir/$matched_file";
            if (($current_useful) and (not $right_dir_hash{$matched_file}{"useful"})) {
                print "making useful: $matched_file\n" if ($debug > 1);
                $right_dir_hash{$matched_file}{"useful"}=&dig_out_value("$current_right_file",$current_dig_it_array_ref);
                print "useful done: $right_dir_hash{$matched_file}{useful}\n" if ($debug > 1);
            } else {
                print "not useful $current_useful  $right_dir_hash{$matched_file}{useful}\n" if ($debug > 1);
            }
            print "checking match right $matched_file left $current_left_file\n"  if ($debug > 1);
            # my $diff = diff "$file", "$gis50dir/$matched_file", { STYLE => "Context" };
            # print "$diff\n" if ($debug > 1);
            if ($file_cksum == $right_dir_hash{$matched_file}{"cksum"}) {
                print "MATCH! $matched_file result_id:$result_id, left_name:$current_left_file, right_name:$matched_file\n\n" if ($debug);
                $found_match=1;
                `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST $rails_server/successful_files/ -d '{ "successful_file" : { "result_id": $result_id, "left_name": "$current_left_file", "right_name":"$matched_file" } }'`;
                unlink $full_left_file;
                delete $right_dir_hash{$matched_file};
                $index_counter=0;
                $index_counter++ until $$right_dir_array_ref[$index_counter] eq $matched_file;
                splice(@$right_dir_array_ref, $index_counter, 1);
                unlink "$current_right_dir/.cleaned/$matched_file";
                unlink "$current_right_dir/.hashed/$matched_file";
                unlink "$current_right_dir/$matched_file";
                # ( -w $results_file ) and &in_place_clean($results_file,{"\<\!\-\- Start right $matched_file \-\-\>\n.*\<\!\-\- End right $matched_file \-\-\>\n"=>""},"stringm");
                splice @$matches_ref,$i,1;
                last;
            }
            print "No match right $matched_file left $current_left_file\n"  if ($debug > 1);
            if (($current_useful) and ($right_dir_hash{$matched_file}{"useful"}) and ($current_useful eq $right_dir_hash{$matched_file}{"useful"})) {
                print "Matching useful for $matched_file\n" if ($debug);

                # if there is a segment delimiter, it must be EDI, so it might be
                # one long line and we need to split before sort. We sort because we
                # are not guarenteed to get the line but still might have all of the lines
                if ($current_sed) {
                    print "Found sed for $matched_file $current_sed\n" if ($debug);
                    chomp($file_rows_left=`wc -l < '$full_left_file'`); $file_rows_left=~s/\s//g;
                    chomp($file_rows_right=`wc -l < '$current_right_file'`); $file_rows_right=~s/\s//g;
                    if ((not ($file_rows_left)) and (not $file_rows_right)) {
                        print "Single lines $matched_file\n" if ($debug);
                        @temp_left=grep { s/$/$current_sed\n/ } split(/$current_sed/,`cat '$full_left_file'`);
                        @temp_right=grep { s/$/$current_sed\n/ } split(/$current_sed/,`cat '$current_right_file'`);
                        # $right_dir_hash{$matched_file}{"diff"}=diff(\@temp_left, \@temp_right, { STYLE => "OldStyle" });
                    } else {
                        print "Not single lines $matched_file\n" if ($debug);
                        @temp_left=`cat '$full_left_file'`;
                        @temp_right=`cat '$current_right_file'`;
                        # $right_dir_hash{$matched_file}{"diff"}=diff(\@temp_left, \@temp_right, { STYLE => "OldStyle" });
                    }
                } else {
                    @temp_left=`cat '$full_left_file'`;
                    @temp_right=`cat '$current_right_file'`;
                }
                if (not (($order_matters eq "true") or ($order_matters eq "1"))) {
                    @temp_left=sort @temp_left;
                    @temp_right=sort @temp_right;
                }
                print "Found $full_left_file left_temp=".scalar(@temp_left)." $current_right_file right_temp=".scalar(@temp_right)."\n" if ($debug);
                $right_dir_hash{$matched_file}{"diff"}=diff(\@temp_left, \@temp_right, { STYLE => "Table" });
                print "Diff for $matched_file:\n" if ($debug);
                print $right_dir_hash{$matched_file}{"diff"}."\n" if ($debug);
                &parse_diff($current_left_file,$matched_file,$right_dir_hash{$matched_file}{"diff"},$current_useful);
                delete $right_dir_hash{$matched_file};
                $index_counter=0;
                $index_counter++ until $$right_dir_array_ref[$index_counter] eq $matched_file;
                splice(@$right_dir_array_ref, $index_counter, 1);
                (not $found_useful) and $found_useful=$matched_file;
                last;
            }
        }
    }

    # if we haven't found a successful or unsuccessful (via useful) match...
    if ((not $found_match) and (not $found_useful)) {

        # Special case where we weren't given a useful value in the config, but the files
        # can be matched on a one-to-one via filename, we want to get a diff. 
        if (($#$matches_ref == 0) and (not $current_useful)) {
            $right_dir_hash{$$matches_ref[0]}{"diff"}=(-r "$current_right_dir/.cleaned/".$$matches_ref[0]) ? diff("$full_left_file", "$current_right_dir/.cleaned/".$$matches_ref[0], { STYLE => "Table" }) : diff("$full_left_file", "$current_right_dir/".$$matches_ref[0], { STYLE => "Table" });
            &parse_diff($current_left_file,$$matches_ref[0],$right_dir_hash{$$matches_ref[0]}{"diff"},$current_useful);
            delete $right_dir_hash{$$matches_ref[0]};
            $index_counter=0;
            $index_counter++ until $$right_dir_array_ref[$index_counter] eq $$matches_ref[0];
            splice(@$right_dir_array_ref, $index_counter, 1);
        } else {

            # Call it unmatched left
            `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST $rails_server/unmatched_files/ -d '{ "unmatched_file" : { "result_id": $result_id, "side": "left", "name":"$current_left_file", "url":"$left_url/$cleaned_left_file" } }'`;
        }
        return($matches_ref);        
    }
}

sub clean_me {
    (my $clean_dir, my $clean_file, my $clean_hash)=@_;
    `rm -rf $clean_dir/.cleaned; mkdir $clean_dir/.cleaned` if (not -d "$clean_dir/.cleaned");
    copy("$clean_dir/$clean_file","$clean_dir/.cleaned/$clean_file");
    print "clean me: $clean_file\n" if ($debug > 1);
    $cleancount++;
    print "        clean $cleancount $clean_file\n" if (not ($cleancount % 100));
    &in_place_clean("$clean_dir/.cleaned/$clean_file",$exclude_right_hash_ref,"exclude");
    &in_place_clean("$clean_dir/.cleaned/$clean_file",$clean_hash,"clean");
}

# sub edi_clean_hash_setup {
#     (my $eld, my $sed, my $doctype)=@_;
#     my $default_edi={
#         qr{(ISA\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){8})[^\Q$eld\E]*(\Q$eld\E)[^\Q$eld\E]*(\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){2})[^\Q$eld\E]*(\Q$eld\E)((?:[^\Q$eld$sed\E]*[\Q$eld$sed\E]){7})} => '$1.$2.$3.$4.$5.$6.$7',
#         qr{(\Q$sed\E\s?ISA\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){8})[^\Q$eld\E]*(\Q$eld\E)[^\Q$eld\E]*(\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){2})[^\Q$eld\E]*(\Q$eld\E)((?:[^\Q$eld$sed\E]*[\Q$eld$sed\E]){7})} => '$1.$2.$3.$4.$5.$6.$7',
#         qr{(\Q$sed\E\s?GS\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){3})[^\Q$eld\E]*(\Q$eld\E)[^\Q$eld\E]*(\Q$eld\E)[^\Q$eld\E]*(\Q$eld\E)((?:[^\Q$eld$sed\E]*[\Q$eld$sed\E]){2})} => '$1.$2.$3.$4.$5.$6',
#         qr{(\Q$sed\E\s?BGN\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){3})[^\Q$eld$sed\E]*([\Q$eld$sed\E])} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?BSN\Q$eld\E)((?:[^\Q$eld\E]*\Q$eld\E){3})[^\Q$eld$sed\E]*([\Q$eld$sed\E])} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?ST\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?SE\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?GE\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?IEA\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?L11\Q$eld\E)[^\Q$eld\E]*(\Q$eld\E)(PP\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?G62\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3',
#         qr{(\Q$sed\E\s?G62\Q$eld\E)([^\Q$eld\E]*\Q$eld\E)[^\Q$eld$sed\E]*(\Q$eld\E[XY]\Q$eld\E)[^\Q$eld$sed\E]*(\Q$sed\E)} => '$1.$2.$3.$4',
#     };
#         # qr{(ITNHUB\Q$eld\E[^\Q$eld$sed\E]*\Q$sed\E)},
#     my $dig_it=[
#         qr{(BIG\Q$eld\E[^\Q$eld$sed\E]*\Q$eld\E[^\Q$eld$sed\E]*\Q$eld\E[^\Q$eld$sed\E]*\Q$eld\E[^\Q$eld$sed\E]*\Q$eld\E)},
#         qr{(BPT\Q$eld\E(?:[^\Q$eld\E]*\Q$eld\E){8}[^\Q$eld$sed\E]*\Q$sed\E)},
#         qr{(AK1\Q$eld\E[^\Q$eld\E]*\Q$eld\E[^\Q$eld$sed\E]*\Q$sed\E)},
#         qr{(\<PONum\>\d+\<\/PONum\>)},
#         qr{(\<ITNPONum\>\d+\<\/ITNPONum\>)},
#         qr{(\<OriginalPONum\>\d+\<\/OriginalPONum\>)},
#         qr{(PO_HDR\s+\d+)},
#     ];
#     my $gp={
#         qr{(FILE_HDR\s\s[^\s]+\s+[^\s]+\s+)(?:\d){14}(\s+\~)} => '$1.$2',
#     };
#     my $mis={
#         qr{(2012)\d\d\d\d( )\d\d(:)\d\d(:)\d\d} => '$1.$2.$3.$4',
#     };
#     ($doctype eq "dig_it") and return $dig_it;
#     ($doctype eq "gp") and return $gp;
#     ($doctype eq "mis") and return $mis;
#     (not $doctype) and return $default_edi;
# }

sub edi_clean_hash_setup {
    (my $replace_strings_hashref, my $eld, my $sed)=@_;
    # our %clean_up_complete_hash;
    # our %exclude_complete_hash;

    # return if (($type eq "clean") and ($clean_up_complete_hash{$editor}));
    # return if (($type eq "exclude") and ($exclude_complete_hash{$editor}));
    foreach my $rstring (keys %$replace_strings_hashref) {
        $newrstring=eval "qr/$rstring/";
        print "in_place_clean $eld $sed rstring $rstring $newrstring\n" if ($debug);
        $$replace_strings_hashref{$newrstring}=$$replace_strings_hashref{$rstring};
        delete $$replace_strings_hashref{$rstring};
        # if ($type eq "string") {
        #     edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/gs } $editor;
        # } elsif ($type eq "stringm") {
        #     edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/ms } $editor;
        # } elsif ($type eq "clean") {
        #     edit_file { s/$rstring/$$replace_strings_hashref{$rstring}/eegs } $editor;
        #     $clean_up_complete_hash{$editor}=1;
        # } elsif ($type eq "exclude") {
        #     if ($$replace_strings_hashref{$rstring} eq "line") {
        #         edit_file_lines { $_ = '' if /$rstring/ } $editor;
        #     } elsif ($$replace_strings_hashref{$rstring} eq "string") {
        #         edit_file { s/$rstring//gs } $editor;
        #     }
        #     $exclude_complete_hash{$editor}=1;
        # }
    }
    # exit;
    return $replace_strings_hashref;
}


# [shag:hinkman]<bash:309%> perl -e 'use Config::XMLPerl qw(config_load) ; my $config = config_load("regression_diff_conf.xml"); foreach $hash_ref (@{$config->{filenames}{pattern}}) { print $$hash_ref{matching_fields}; };'

sub zip_load {
    (my $zip_file, my $extract_dir)=@_;

    my $ae = Archive::Extract->new( archive => $zip_file );
    my $ok = $ae->extract( to => $extract_dir ) or die $ae->error;
    return $extract_dir;

}

sub parse_diff {
    (my $left_filename, my $right_filename, my $diff_output, my $useful)=@_;
    my @flag_locations;
    my $header_line_done=0;

    my @split_diff=split(/\n/,$diff_output);
    # my $file_key=unpack("%32W*",$left_filename) % 65535;
    my $file_key=crc($left_filename);

    my $offset = 0;
    my $result = index($split_diff[0], '+', $offset);
    while ($result != -1) {
        print "Found + at $result\n" if ($debug);
        push(@flag_locations,$result);
        $offset = $result + 1;
        $result = index($split_diff[0], '+', $offset);
    }

    foreach my $line (@split_diff) {
        my $first_char=substr($line, 0, 1);
        my $last_char=substr($line, -1, 1);
        my $left_line_num=0;
        my $left_line="<no line>";
        my $right_line_num=0;
        my $right_line="<no line>";

        print "$file_key $first_char $last_char '$line'\n" if ($debug);

        if ($first_char eq "*") {
            $left_line_num=int(substr($line, ($flag_locations[0] + 1), ($flag_locations[1] - $flag_locations[0] - 1))) + 1;
            $left_line=substr($line, ($flag_locations[1] + 1), ($flag_locations[2] - $flag_locations[1] - 1));
            print "left $file_key $left_line_num\n" if ($debug);
        }

        if ($last_char eq "*") {
            $right_line_num=int(substr($line, ($flag_locations[2] + 1), ($flag_locations[3] - $flag_locations[2] - 1))) + 1;
            $right_line=substr($line, ($flag_locations[3] + 1), ($flag_locations[4] - $flag_locations[3] - 1));
            print "right $file_key $right_line_num\n" if ($debug);
        }

        if ($right_line_num or $left_line_num) {
            if (not $header_line_done) {
                `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST $rails_server/unsuccessful_files/ -d '{ "unsuccessful_file" : { "result_id": $result_id, "left_line": "$left_filename|==|$left_url/$left_filename", "right_line": "$right_filename|==|$right_url/$right_filename", "left_line_number": "-1", "right_line_number": "-1", "compare_key": "$file_key", "useful": "$useful" } }'`;
                $header_line_done=1;
            }
            `curl -s -H 'Content-Type: application/json' -H 'Accept: application/json' -X POST $rails_server/unsuccessful_files/ -d '{ "unsuccessful_file" : { "result_id": $result_id, "left_line": "$left_line", "right_line": "$right_line", "left_line_number": "$left_line_num", "right_line_number": "$right_line_num", "compare_key": "$file_key" } }'`;
        } 
    }
}


