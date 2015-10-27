package Code4Health::AppKitX::CommunityAdmin::Controller::CommunityAdmin;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Communities',
    appkit_myclass              => 'Code4Health::AppKitX::CommunityAdmin',
    appkit_method_group         => 'Communities',
    appkit_shared_module        => 'Communities',
);

sub auto : Action {
    my ($self, $c) = @_;
    my $index_url = $c->uri_for($self->action_for('list'));
    $c->stash->{index_url} = $index_url;
    $self->add_breadcrumb($c, { name => 'Communities', url => $index_url });
}

sub list
    : Local
    : Args(0)
    : NavigationName('List Communities')
    : AppKitFeature('Communities')
{
    my ($self, $c) = @_;

    my $communities = [$c->model('Users::Community')->active->by_name];

    $c->stash->{communities} = $communities;
    $c->stash->{add_url} = $c->uri_for($self->action_for('add'));
}

sub add
    : Local
    : AppKitFeature('Communities')
    : AppKitForm
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Add');
    if($c->req->param('cancel'))
    {
        $c->res->redirect($c->stash->{index_url});
        $c->detach;
    }
    my $form = $c->stash->{form};
    if($form->submitted_and_valid)
    {
        my $data = {
            name => $form->param_value('name'),
        };
        $c->model('Users::Community')->create($data);
        $c->flash->{status_msg} = 'Added community';
        $c->res->redirect($c->stash->{index_url});
    }
}

sub community_chain
    : Chained('/')
    : CaptureArgs(1)
    : PathPart('community')
    : AppKitFeature('Communities')
{
    my ($self, $c, $code) = @_;

    my $community = $c->model('Users::Community')->find({ code => $code, status => 'active' });
    $c->detach('/not_found') unless $community;
    $c->stash->{community} = $community;
    my $url = $c->uri_for($self->action_for('edit'), [$community->code]);
    $c->stash->{url} = $url;
    $self->add_breadcrumb($c, { name => $community->name, url => $url });
}

sub edit
    : Chained('/community_chain')
    : AppKitFeature('Communities')
    : AppKitForm
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Edit');
}

1;
