use strict;
use warnings;
use 5.010;
use LWP::UserAgent;
use Term::ANSIColor;
use threads;
use Thread::Queue;

my ($target, $wordlist) = @ARGV;
my $ua = LWP::UserAgent->new();
my $thread_count = 10;  # Number of threads to use
my $url_queue = Thread::Queue->new();
my @found = ();
my %status_colors = (
    200 => "bold green",
    403 => "bold red",
    500 => "red",
    401 => "yellow",
    404 => "red"
);

# Common false positives to ignore
my @ignored_status_codes = (404);
my @ignored_urls = ("http://$target/favicon.ico");

system("clear");
print_title();

# Check if both target and wordlist are provided
unless (defined $target and defined $wordlist) {
    print "USAGE: \n\tperl adminfinder.pl {TARGET_URI} {WORDLIST}\n\n";
    exit;
}

open my $wordlist_file, '<', $wordlist or die("Error: Unable to open the file $wordlist");

# Start worker threads
for (1..$thread_count) {
    threads->create(\&worker_thread);
}

# Add URLs to the queue
while (my $line = <$wordlist_file>) {
    chomp $line;
    my $url = construct_url($target, $line);
    $url_queue->enqueue($url);
}

close $wordlist_file;

# Signal threads to finish
$url_queue->enqueue(undef) for 1..$thread_count;

# Wait for all threads to finish
$_->join() for threads->list();

print "Valid Pages\n------------------------------------------\n";
print join("\n", @found) . "\n";

sub worker_thread {
    while (my $url = $url_queue->dequeue()) {
        last unless defined $url;
        my $status_code = get_url_status($ua, $url);
        next if is_ignored_status($status_code, $url);
        print_status($url, $status_code);
        push(@found, $url) if is_valid_status($status_code);
    }
}

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

sub is_ignored_status {
    my ($status_code, $url) = @_;
    return 1 if grep { $_ == $status_code } @ignored_status_codes;
    return 1 if grep { $url eq $_ } @ignored_urls;
    return 0;
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
