package GLPI::Agent::HTTP::Server::ToolBox::Results::NetDiscovery;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox::Results::Fields";

use Memoize;

use GLPI::Agent::Tools;
use GLPI::Agent::Target::Local;

memoize('__sortable_by_ip');

sub new {
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless $self, $class;

    return $self;
}

sub order { 20 }

sub sections {
    return {
        name    => "default",
        index   => 0, # section index, lowest is show first
        #title   => "Device", # No section title will be shown if title is not set
    },
    {
        name    => "network",
        index   => 1,
        title   => "Networking"
    },
    {
        name    => "netscan",
        index   => 10,
        title   => "Networking scan datas"
    };
}

sub fields {
    my ($self) = @_;

    return {
        name    => "name",
        section => "default",
        type    => "readonly",
        from    => [ qw(SNMPHOSTNAME DNSHOSTNAME IP) ], # First giving a value is used
        text    => "Device name or IP",
        column  => 0,
        editcol => 0,
        index   => 0, # Used to order field in edit mode and in a given edit column
        noedit  => 1,
    },
    {
        name    => "ip",
        section => "network",
        type    => "readonly",
        from    => "IP",
        text    => "IP",
        column  => 1,
        editcol => 0,
        index   => 1,
        tosort  => sub { __sortable_by_ip(@_); },
        noedit  => 1,
    },
    {
        name    => "ips",
        section => "network",
        type    => "readonly",
        text    => "IPs",
        column  => 9,
        editcol => 0,
        index   => 2,
    },
    {
        name    => "mac",
        section => "network",
        type    => "readonly",
        from    => "MAC",
        text    => "MAC",
        column  => 1,
        editcol => 1,
        index   => 2,
    },
    {
        name    => "serial",
        section => "default",
        type    => "readonly",
        from    => "SERIAL",
        text    => "SerialNumber",
        column  => 4,
        editcol => 1,
        index   => 1,
    },
    {
        name    => "description",
        section => "default",
        type    => "readonly",
        from    => "DESCRIPTION",
        text    => "Description",
        column  => 100,
        editcol => 0,
        index   => 10,
    },
    {
        name    => "location",
        section => "default",
        type    => "readonly",
        from    => "LOCATION",
        text    => "Location",
        column  => 10,
        editcol => 0,
        index   => 6,
    },
    {
        name    => "type",
        section => "default",
        type    => "readonly",
        from    => "TYPE",
        text    => "Type",
        column  => 1,
        editcol => 1,
        index   => 0,
    },
    {
        name    => "contact",
        section => "default",
        type    => "readonly",
        from    => "CONTACT",
        text    => "Contact",
        column  => 1,
        editcol => 1,
        index   => 30,
    },
    {
        name    => "tag",
        section => "default",
        type    => "readonly",
        text    => "Tag",
        column  => 20,
        editcol => 0,
        index   => 20,
        noedit  => 1,
    },
    {
        name    => "source",
        section => "default",
        type    => "readonly",
        text    => "Source",
        column  => 21,
        editcol => 1,
        index   => 21,
        noedit  => 1,
    },
    {
        name    => "ip_range",
        section => "netscan",
        type    => "readonly",
        from    => "-ip_range",
        text    => "IP Range",
        column  => 30,
        editcol => 0,
        index   => 30,
        noedit  => 1,
    },
    {
        name    => "credential",
        section => "netscan",
        type    => "readonly",
        from    => "AUTHSNMP",
        text    => "Credential",
        column  => 31,
        editcol => 1,
        index   => 31,
        noedit  => 1,
    };
}

sub __sortable_by_ip {
    my ($device) = @_;
    return '' unless $device && $device->{ip};
    return $device->{ip} unless $device->{ip} =~ /^\d+\.\d+\.\d+\.\d+$/;
    # encoding ip as hex string make it sortable by cmp comparator
    return join("", map { sprintf("%02X",$_) } split(/\./, $device->{ip}));
}

sub _getDevices {
    my ($self) = @_;

    # Get stored credentials & ip_range for devices from local target storage
    my $yaml_config = $self->{results}->yaml('configuration') || {};
    my $path = $yaml_config->{networktask_save} // '.';

    # Make sure path exists as folder before accessing storage
    mkdir $path unless -d $path;

    my $target = GLPI::Agent::Target::Local->new(
        logger     => $self->{logger},
        delaytime  => 0,
        basevardir => $self->{results}->{toolbox}->{server}->{agent}->{config}->{vardir},
        path       => $path
    );

    my $storage = $target->getStorage();
    my $devices = $storage->restore(name => "NetDisco-Devices") // {};

    # Check to clean up expired ips but no more than one time an hour
    my $now = time;
    if (!$devices->{_cleanup_expiration} || $now > $devices->{_cleanup_expiration}) {
        foreach my $ip (keys(%{$devices})) {
            next unless ref($devices->{$ip});
            delete $devices->{$ip}
                if $devices->{$ip}->{expiration} && $now > $devices->{$ip}->{expiration};
        }
        $devices->{_cleanup_expiration} = $now + 3600;
        $storage->save(name => "NetDisco-Devices", data => $devices);
    }

    return $devices;
}

sub analyze {
    my ($self, $name, $tree, $file) = @_;

    return unless $name && $tree;

    my $query = $tree && $tree->{REQUEST} && $tree->{REQUEST}->{QUERY}
        or return;

    return unless $query =~ /^NETDISCOVERY$/;

    my $dev = $tree->{REQUEST}->{CONTENT} && $tree->{REQUEST}->{CONTENT}->{DEVICE}
        or return;

    my $device = $self->fields_common_analysis($dev);

    my $device_scan_result;
    unless ($device->{credential} && $device->{ip_range}) {
        my $devices = $self->_getDevices();
        $device_scan_result = $devices->{$device->{ip}}
            if $devices && $devices->{$device->{ip}};
    }

    # Fix credential & ip_range if set in dedicated storage
    if ($device_scan_result) {
        $device->{credential} = $device_scan_result->{credential}
            if $device_scan_result->{credential};
        $device->{ip_range} = $device_scan_result->{ip_range}
            if $device_scan_result->{ip_range};
        # Set deviceid for deduplication
        # 'ha-host' is set when inventory is done on an ESX server, this doesn't work for a vCenter
        $device->{deviceid} = ref($device_scan_result->{deviceid}) eq 'HASH' ? $device_scan_result->{deviceid}->{'ha-host'} : $device_scan_result->{deviceid}
            if $device_scan_result->{deviceid};
    }

    # Fix credential if credential was set into []
    $device->{credential} = $1
        if $device->{credential} && $device->{credential} =~ /^\[(.*)\]$/;

    if ($dev->{IPS} && ref($dev->{IPS}->{IP})) {
        $device->{ips} = join(',', @{$dev->{IPS}->{IP}});
    }

    # Extract tag from file name
    my ($tag) = $file =~ m|/\d+\.\d+\.\d+\.\d+_(.+)\.xml$|;
    $device->{tag}    = $tag || '';
    $device->{source} = $self->name;

    # Defines dynamic fields that can't be edited
    my @netinventory_fields = GLPI::Agent::HTTP::Server::ToolBox::Results::NetInventory->fields();

    $device->{_noedit} = { map { $_->{name} => 1 } $self->fields(), @netinventory_fields };

    # Any empty field should be editable unless specifically set not editable
    foreach my $field ($self->fields(), @netinventory_fields) {
        next if $field->{noedit};
        my $value = $device->{$field->{name}};
        $device->{_noedit}->{$field->{name}} = 0 unless (defined($value) && length($value));
    }

    # Don't include fields from local Inventory which are not in NetInventory
    my @inventory = GLPI::Agent::HTTP::Server::ToolBox::Results::Inventory->fields();
    foreach my $field (@inventory) {
        $device->{_noedit}->{$field->{name}} = 1
            unless exists($device->{_noedit}->{$field->{name}});
    }

    # Always set type editable when not a supported one
    $device->{_noedit}->{type} = 0
        unless $device->{type} && $device->{type} =~ /^NETWORKING|PRINTER|STORAGE$/;

    return $device;
}

sub update_template_hash {
    my ($self, $hash, $devices) = @_;
    $hash->{netscan_count} = grep { $_->hasNetScan() } values(%{$devices});
}

1;
