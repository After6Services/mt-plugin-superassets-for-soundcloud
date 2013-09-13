package SuperAssetsForSoundCloud::CMS;

use strict;
use warnings;

require MT;
require MT::Asset::SoundCloudTrack;
use SuperAssetsForSoundCloud::Util qw(:all);
use Encode;
require CGI;

sub create_track {
    my $app = shift;
    my (%params, %errors, $tmpl, $track);

    return $app->error("Permission denied.")
        unless $app->user->is_superuser || $app->permissions && $app->permissions->can_upload;

    $errors{invalid_plugin_config} = 1 unless is_valid_plugin_config();

    $params{$_} = $app->param($_) || '' for qw(track_url continue_args no_insert);

    # checking params preemptively passed via url or submitted with form
    if ($params{track_url} && !keys %errors) {
        if (is_valid_track_url($params{track_url})) {
            # getting track data from soundcloud
            my $res = MT->new_ua->get(
                sprintf(
                    'http://api.soundcloud.com/resolve.json?client_id=%s&url=%s',
                    plugin->get_config_value('api_client_id'),
                    CGI::escape($params{track_url})
                )
            );

            if ($res->is_success) {
                require JSON;
                eval {
                    $track = JSON->new->allow_nonref->utf8(1)->decode($res->content) || {};
                };

                if ($@) {;
                    $errors{api_error} = $@;
                }
                else {
                    if ( my ($t) = MT::Asset::SoundCloudTrack->search_by_meta(
                            'soundcloud_track_id', $track->{id}
                         )
                       ) {
                        $errors{track_already_exists} = 1;
                        $params{original_asset_id} = $t->id;
                    }
                }
            }
            else {
                if ($res->code eq '401') {
                    $errors{api_error_permission_denied} = 1;
                }
                elsif ($res->code eq '404') {
                    $errors{error_track_not_found} = 1;
                }
                elsif ($res->code eq '503') {
                    $errors{error_service_unavailable} = 1;
                }
                elsif ($res->code =~ /^5/) {
                    $errors{service_error} = 1;
                }
                else {
                    $errors{api_error} = sprintf('(%s): %s', $res->code, $res->status_line);
                }
            }
        }
        else {
            $errors{invalid_track_url} = 1;
        }
    }

    if ($app->param("submit") && !keys %errors) {
        return unless $app->validate_magic;

        unless ($track) {
            $errors{invalid_track_url} = 1;
        }
        else {
            if ($track->{state} && $track->{state} ne 'finished') {
                $errors{error_track_not_available} = 1;
            }

            # just making sure we're not getting a playlist/set, etc.
            if ($track->{kind} && $track->{kind} ne 'track') {
                $errors{error_unsupported_object_kind} = 1;
            }
        }

        unless (keys %errors) {
            # everything seems to be just swell, so let's create a new asset
            my $asset = MT::Asset::SoundCloudTrack->new;
            $asset->blog_id($app->blog->id);
            $asset->label($track->{title});
            $asset->description($track->{description});
            $asset->url($track->{permalink_url});
            $asset->modified_by($app->user->id);

            # soundcloud-specific stuff
            $asset->soundcloud_track_id($track->{id});
            $asset->soundcloud_track_permalink($track->{permalink});
            $asset->soundcloud_track_artwork_url($track->{artwork_url});
            $asset->soundcloud_track_user_id($track->{user_id});
            $asset->soundcloud_track_user_permalink($track->{user}->{permalink});
            $asset->soundcloud_track_user_name($track->{user}->{username});

            # importing tags
            if ($track->{tag_list}) {
                # space-separated tag list, tags with spaces are in double quotes
                $asset->set_tags(
                    grep {
                        !/\w:\w/;  # excluding invisible machine tags, e.g., "blah:blah"
                    }
                    map {
                        s/"//g; s/^\s*|\s*$//g; $_;  # cleanup
                    }
                    $track->{tag_list} =~ /(".+?"|\S+)/g
                );
            }

            my $original = $asset->clone;
            $asset->save or return $app->error("Couldn't save asset: " . $asset->errstr);
            $app->run_callbacks('cms_post_save.asset', $app, $asset, $original);

            # be nice and return users back to asset insert/listing dialog views
            if ($params{continue_args}) {
                my $url = $app->uri . '?' . $params{continue_args};
                $url .= '&no_insert=' . $params{no_insert};
                $url .= '&dialog_view=1';
                return $app->redirect($url);
            }

            # otherwise close dialog via js and redirect to the normal
            # asset listing page (seems to be the default mt behavior)
            $params{new_asset_id} = $asset->id;
            $tmpl = plugin->load_tmpl('create_track_complete.tmpl');
        }
    }

    %params = (%params, %errors, errors => 1) if keys %errors;
    $tmpl ||= plugin->load_tmpl("create_track.tmpl");
    return $app->build_page($tmpl, \%params);
}

sub asset_list_source {
    my ($cb, $app, $tmpl) = @_;

    if ($app->param('filter_val')) {
        if ($app->param('filter_val') eq 'soundcloud_track') {
            # fixing title
            my $replace_re = '<mt:setvarblock name="page_title">.*?setvarblock>';
            my $new = q{<mt:setvarblock name="page_title">Insert SoundCloud Track</mt:setvarblock>};
            $$tmpl =~ s/$replace_re/$new/;

            # replacing "Upload New File" with our thingy
            $replace_re = '<mt:setvarblock name="upload_new_file_link">.*?setvarblock>';
            # omg %)
            $new = <<NEW;
<mt:setvarblock name="upload_new_file_link">
<img src="<mt:var name="static_uri">images/status_icons/create.gif" alt="Add SoundCloud Track" width="9" height="9" />
<mt:unless name="asset_select"><mt:setvar name="entry_insert" value="1"></mt:unless>
<a href="<mt:var name="script_url">?__mode=soundcloud_track_create&amp;blog_id=<mt:var name="blog_id">&amp;no_insert=<mt:var name="no_insert">&amp;dialog_view=1&amp;<mt:if name="asset_select">asset_select=1&amp;<mt:else>entry_insert=1&amp;</mt:if>edit_field=<mt:var name="edit_field" escape="url">&amp;continue_args=<mt:var name="return_args" escape="url">">Add SoundCloud Track</a>
</mt:setvarblock>
NEW
            $$tmpl =~ s/$replace_re/$new/s;
            $$tmpl =~ s/phrase="Insert"/phrase="Continue"/;
        }
    }
    else {
        # just appending our "Add SoundCloud Track" link on listings with mixed asset types
        my $replace_re = '(<mt:setvarblock name="upload_new_file_link">.*?)(<\/mt:setvarblock>)';
        my $new = <<NEW;
<img src="<mt:var name="static_uri">images/status_icons/create.gif" alt="Add SoundCloud Track" width="9" height="9" style="margin-left: 1em" />
<a href="<mt:var name="script_url">?__mode=soundcloud_track_create&amp;blog_id=<mt:var name="blog_id">&amp;no_insert=<mt:var name="no_insert">&amp;dialog_view=1&amp;<mt:if name="asset_select">asset_select=1&amp;<mt:else>entry_insert=1&amp;</mt:if>edit_field=<mt:var name="edit_field" escape="url">&amp;continue_args=<mt:var name="return_args" escape="url">">Add SoundCloud Track</a>
NEW
        $$tmpl =~ s/$replace_re/$1$new$2/s;
    }
}

sub asset_insert_source {
    my ($cb, $app, $tmpl) = @_;

    # enable thumbnail previews for soundcloud tracks in the entry asset manager
    my $old = '<mt:If tag="AssetType" like="\^\((.+?)\)\$">';
    my $new;
    $$tmpl =~ s/$old/<mt:If tag="AssetType" like="^($1|soundcloud track)\$">/g;

    $old = '<mt:If tag="AssetType" eq="image">';
    $new = '<mt:If tag="AssetType" like="^(image|soundcloud track)$">';
    $$tmpl =~ s/\Q$old\E/$new/g;
}

sub edit_entry_param {
    my ($cb, $app, $param, $tmpl) = @_;

    # enable thumbnail previews for soundcloud tracks in the entry asset manager
    if (ref $param->{asset_loop}) {
        for my $p (@{$param->{asset_loop}}) {
            my $asset = MT::Asset->load($p->{asset_id});
            if ($asset->class eq 'soundcloud_track') {
                ($p->{asset_thumb}) = $asset->thumbnail_url(Width => 100);
            }
        }
    }
}

sub editor_source {
    my ($cb, $app, $tmpl) = @_;

    # adding some css
    $$tmpl .= q{
        <mt:setvarblock name="html_head" append="1">
        <link rel="stylesheet" type="text/css" href="<mt:var name="static_uri">plugins/SuperAssetsForSoundCloud/editor.css" />
        </mt:setvarblock>
    };

    # adding insert track toolbar button
    my $insert_image_button_re = '<a.*?<b>Insert Image<\/b>.*?<\/a>';
    my $new_button = '<a href="javascript: void 0;" title="Insert SoundCloud Track" mt:command="open-dialog" mt:dialog-params="__mode=list_assets&amp;_type=asset&amp;edit_field=<mt:var name="toolbar_edit_field">&amp;blog_id=<mt:var name="blog_id">&amp;dialog_view=1&amp;filter=class&amp;filter_val=soundcloud_track" class="command-insert-soundcloud-track toolbar button"><b>Insert SoundCloud Track</b><s></s></a>';
    $$tmpl =~ s/($insert_image_button_re)/$1$new_button/;

    # adding frame editor css injection to render track previews nicely
    $$tmpl .= <<CSSINJECTION
<mt:setvarblock name="html_head" append="1">
<script language="javascript">
TC.attachLoadEvent(function() {
    window.setTimeout(function() {
        var idoc = app.editor.iframe.document;
        if (!idoc)
            return;
        var css = idoc.createElement('link');
        css.type = 'text/css';
        css.rel = 'stylesheet';
        css.href = '<mt:var name="static_uri">plugins/SuperAssetsForSoundCloud/editor-content.css';
        idoc.getElementsByTagName('head')[0].appendChild(css);
    }, 200);
});
</script>
</mt:setvarblock>
CSSINJECTION
}

1;
