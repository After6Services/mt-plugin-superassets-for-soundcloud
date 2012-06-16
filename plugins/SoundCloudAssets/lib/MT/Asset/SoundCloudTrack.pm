package MT::Asset::SoundCloudTrack;

use strict;
use warnings;

use base 'MT::Asset';

require MT;
require MT::Util;
use SoundCloudAssets::Util qw(:all);

__PACKAGE__->install_properties({
    class_type  => 'soundcloud_track',
    column_defs => {
        soundcloud_track_id             => 'string meta indexed',
        soundcloud_track_permalink      => 'string meta',
        soundcloud_track_artwork_url    => 'string meta',
        soundcloud_track_user_id        => 'string meta indexed',
        soundcloud_track_user_permalink => 'string meta indexed',
        soundcloud_track_user_name      => 'string meta',
    },
});

sub class_label { "SoundCloud Track" }   

sub class_label_plural { "SoundCloud Tracks" }

sub has_thumbnail { 1 }

# entry asset manager needs this
sub file_name { shift->label }

sub thumbnail_url {
    my ($asset, %param) = @_;

    my ($w, $h) = @param{qw/Width Height/};
    $w ||= $param{width};
    $h ||= $param{height};

    # the default is 100x100 "large" artwork image
    # http://developers.soundcloud.com/docs/api/reference#tracks
    my $url = $asset->soundcloud_track_artwork_url;
    my ($width, $height) = (100, 100);

    # using the default image when no track artwork is available
    unless ($url) {
        $url = MT->instance->static_path . plugin->envelope . '/default_track_artwork.png';
        $width = $height = 64;
    }

    # scale down only
    $w = $width if $w && $w > $width;
    $h = $height if $h && $h > $height;

    my ($new_w, $new_h);
    my $ratio = $width / $height;

    if ($w && (!$h || int($w / $ratio) <= $h)) {
        $new_w = $w;
        $new_h = int($new_w / $ratio);
    }
    elsif ($h) {
        $new_h = $h;
        $new_w = int($new_h * $ratio);
    }

    return ($url, $new_w, $new_h);
}

sub as_html {
    my ($asset, $param) = @_;

    if ($param->{embed_code}) {
        # called from our text filter - generating the final embed code to be published

        die "Couldn't generate SoundCloud Track embed code: missing target blog_id for asset " . $asset->id
            unless $param->{blog_id};

        # try using a blog-level or system-wide module "SoundCloud Player"
        require MT::Template;
        my ($tmpl) = MT::Template->load(
            {
                type    => 'custom',
                name    => 'SoundCloud Player',
                blog_id => [ $param->{blog_id}, 0 ],
            },
            {
                sort      => 'blog_id',
                direction => 'descend',
            },
        );

        # or the default one
        $tmpl ||= plugin->load_tmpl('track_player.tmpl');

        require MT::Template::Context;
        my $ctx = MT::Template::Context->new;
        $ctx->stash('blog', $asset->blog);
        $ctx->stash('asset', $asset);
        $tmpl->context($ctx);
        $tmpl->param($param);

        my $html = $tmpl->build;
        die "Couldn't generate SoundCloud track embed code: " . $tmpl->errstr
            unless defined $html;

        return $html;
    }
    else {
        # RTE-compatible placeholder tag
        return sprintf(
            '<mt:soundcloud asset-id="%s" blog-id="%s" contentEditable="false">%s<br/><strong>%s</strong></mt:soundcloud>',
            $asset->id,
            $param->{blog_id},
            $asset->soundcloud_track_user_name || $asset->soundcloud_track_user_permalink,
            $asset->label
        );
    }
}

sub edit_template_param {
    my $asset = shift;
    my ($cb, $app, $param, $tmpl) = @_;
    return;
}

1;
