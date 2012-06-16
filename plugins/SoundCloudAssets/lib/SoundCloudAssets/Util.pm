package SoundCloudAssets::Util;

use strict;
use warnings;

require MT;

use Exporter qw(import);
our @ALL = qw(
    is_valid_plugin_config
    is_valid_track_url
    plugin
);
our @EXPORT_OK = @ALL;
our %EXPORT_TAGS = (all => \@ALL);

sub post_init {
    # always add our entry text filter
    no warnings 'redefine';

    require MT::Entry;
    my $orig_text_filters = \&MT::Entry::text_filters;

    *MT::Entry::text_filters = sub {
        my $filters = $orig_text_filters->(@_);
        unshift @$filters, 'embed_soundcloud_tracks';
        return $filters;
    };
}

sub is_valid_plugin_config {
    return plugin()->get_config_value('api_client_id') ? 1 : 0;
}

#
# SoundCloud track URLs:
#
# http://soundcloud.com/guau/destroyers-weird-day-guau-remix-elektroshok-records
# http://snd.sc/iHsrKr
#
sub is_valid_track_url {
    my $url = shift;
    return $url && $url =~ m'^\s* (?:http://)? (?:www\.)? (?: soundcloud\.com/[^/]+/[^/]+ | snd\.sc/[^/]+ )'xi;
}

sub embed_filter {
    my ($text, $ctx) = @_;

    # replacing RTE-compatible track placeholder tags with actual embed code
    # <mt:soundcloud asset-id="xxx" [other params]>...</mt:soundcloud>
    if ($text) {
        $text =~ s|<mt:soundcloud\s+(.*?)>.*?</mt:soundcloud>|embed_track($1)|iseg;
    }

    return $text;
}

sub embed_track {
    my ($param_str) = @_;
    my %params;

    # parsing key=value attributes of the track placeholder tag
    while ($param_str =~ /([\w\-:]+) \s* = \s* (['"]?) (.*?) \2/igsx) {
        $params{$1} = $3;
    }

    $params{blog_id} = delete $params{'blog-id'};
    $params{asset_id} = delete $params{'asset-id'};

    require MT::Asset;
    my $asset = MT::Asset->load($params{asset_id});

    return $asset ? $asset->as_html({ embed_code => 1, %params }) : '';
}

sub plugin {
    return MT->component("SoundCloudAssets");
}

1;
