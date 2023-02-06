package Nipe::Engine::Start {
	use strict;
	use warnings;
	use Nipe::Utils::Device;

	sub new {
		my %device       = Nipe::Utils::Device -> new();
		my $dnsPort      = "9061";
		my $transferPort = "9051";
		my @table        = ("nat", "filter");
		my $network      = "10.66.0.0/255.255.0.0";

		system ("tor -f .configs/$device{distribution}-torrc > /dev/null");

		foreach my $table (@table) {
			my $target = "ACCEPT";

			if ($table eq "nat") {
				$target = "RETURN";
			}

			system ("iptables -t $table -F OUTPUT");
			system ("iptables -t $table -A OUTPUT -m state --state ESTABLISHED -j $target");
			system ("iptables -t $table -A OUTPUT -m owner --uid $device{username} -j $target");

			my $matchDnsPort = $dnsPort;

			if ($table eq "nat") {
				$target = "REDIRECT --to-ports $dnsPort";
				$matchDnsPort = "53";
			}

			system ("iptables -t $table -A OUTPUT -p udp --dport $matchDnsPort -j $target");
			system ("iptables -t $table -A OUTPUT -p tcp --dport $matchDnsPort -j $target");

			if ($table eq "nat") {
				$target = "REDIRECT --to-ports $transferPort";
			}

			system ("iptables -t $table -A OUTPUT -d $network -p tcp -j $target");

			if ($table eq "nat") {
				$target = "RETURN";
			}

			system ("iptables -t $table -A OUTPUT -d 127.0.0.1/8    -j $target");
			system ("iptables -t $table -A OUTPUT -d 192.168.0.0/16 -j $target");
			system ("iptables -t $table -A OUTPUT -d 172.16.0.0/12  -j $target");
			system ("iptables -t $table -A OUTPUT -d 10.0.0.0/8     -j $target");

			if ($table eq "nat") {
				$target = "REDIRECT --to-ports $transferPort";
			}

			system ("iptables -t $table -A OUTPUT -p tcp -j $target");
		}

		system ("iptables -t filter -A OUTPUT -p udp -j REJECT");
		system ("iptables -t filter -A OUTPUT -p icmp -j REJECT");

        system("sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null");
        system("sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null");

		return 1;
	}
}

1;