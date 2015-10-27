package Code4Health::AppKitX::CommunityAdmin::Controller::CommunityAdmin;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

1;
