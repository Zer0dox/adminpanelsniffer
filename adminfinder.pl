use strict;
use warnings;
use 5.010;
use LWP::UserAgent;
use Term::ANSIColor;

my ($target, $wordlist) = @ARGV;
my $ua = LWP::UserAgent->new();
my @found = ();
my %status_colors = (
    200 => "bold green",
    403 => "bold red",
    500 => "red",
    401 => "yellow",
    404 => "red"
);

system("clear");
print_title();

# Check if both target and wordlist are provided
unless (defined $target and defined $wordlist) {
    print "USAGE: \n\tperl adminfinder.pl {TARGET_URI} {WORDLIST}\n\n";
    exit;
}

open my $wordlist_file, '<', $wordlist or die("Error: Unable to open the file $wordlist");

# Loop through each line in the wordlist
while (my $line = <$wordlist_file>) {
    chomp $line;
    my $url = construct_url($target, $line);
    my $status_code = get_url_status($ua, $url);
    print_status($url, $status_code);
    push(@found, $url) if is_valid_status($status_code);
}

close $wordlist_file;

print "Valid Pages\n------------------------------------------\n";
print join("\n", @found) . "\n";

sub construct_url {
    my ($base_url, $path) = @_;
    return "http://$base_url/$path";
}

sub get_url_status {
    my ($ua, $url) = @_;
    my $response = $ua->get($url);
    return $response->code;
}

sub print_status {
    my ($url, $status_code) = @_;
    my $color = $status_colors{$status_code} || "yellow";
    print color($color);
    print "$url responded with status code: $status_code\n";
    print color("reset");
}

sub is_valid_status {
    my $status_code = shift;
    return $status_code == 200 || $status_code == 403 || $status_code == 401;
}

sub print_title {
    print color("magenta");
    print "#################################################\n";
    print color("yellow");
    print "#            Admin Panel Sniffer                #\n";
    print "#            Written by Nightmare               #\n";
    print color("magenta");
    print "#################################################\n";
    print color("reset");
}
